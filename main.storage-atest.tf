# Test-history store for atest.
#
# Flake detection is statistical: a single run cannot tell you whether a test is
# unstable, so the history has to outlive the run that produced it.
#
# ── WHAT IS IN THE CONTAINER ──────────────────────────────────────────────────
# An append-only log of run records, one immutable object per run and shard:
#
#   atest-history/v1/runs/2026/08/30/<runId>/<shard>.json.gz
#
# This replaced a single history.sqlite that CI downloaded, ingested into, and
# re-uploaded under an If-Match precondition. That shape worked for one writer
# and failed for two: overlapping main-branch runs raced on the ETag, and the
# loser either failed the step or silently discarded the other run's attempts.
# It also rewrote the entire database to append thirty seconds of it.
#
# Objects remove the race rather than arbitrating it. The blob name is derived
# from the run id and the shard, so a re-ingested shard overwrites exactly
# itself, two shards of one run write different names, and two concurrent runs
# write different names — no locks, no preconditions, no lost writes. The date
# in the path is what lets a 90-day analysis filter the LISTING and download
# only what it will score.
#
# ── WHY A CONTAINER AND NOT A DATABASE ────────────────────────────────────────
# One list and a few hundred small GETs per CI run, a handful of PUTs. No
# concurrent query load, no joins across datasets, no retention beyond a rolling
# window. A managed database would add cost, a private endpoint and a backup
# policy for a workload that is a listing and some object reads.
locals {
  atest_history_enabled = var.storage_atest_account_name != ""

  # Lifecycle rules match on `<container>/<blob prefix>`. Matching the container
  # alone rather than `v1/runs/` covers every layout prefix a consumer might
  # set (`azblob://acct/atest-history/bjjeire-java` writes under one), and the
  # container holds nothing but run history, so there is nothing else to spare.
  atest_history_prefixes = [
    for container in values(var.storage_atest_containers) : "${container.name}/"
  ]
}

# WRITES COME ONLY FROM MAIN, AND THAT IS ENFORCED HERE RATHER THAN IN YAML.
# The `gha_atest_history` identity in main.identity.tf federates on
# refs/heads/main alone and is the only principal granted Contributor. The
# existing `gha_pr_env` identity carries both a pull_request and a main
# credential, so granting it Contributor would have let any pull request write
# — the branch restriction would have lived in a workflow file that anyone can
# edit. Reader is granted to gha_pr_env instead, so pull requests can score
# against the baseline without being able to amend it.
#
# That split is also the right semantics: a flake baseline should describe
# trunk. A pull request introducing an unstable test must not enter the
# baseline before anyone has decided to merge it. atest names the same intent
# on its side with `?readonly=1`, which turns the policy into a mode instead of
# a 403 arriving once per shard file.

module "storage_atest_history" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.10.0"

  # Opt-in per environment. The root module is shared, so this is created only
  # where storage_atest_account_name is set — dev today, others when they want
  # it. Without the gate, adding a required variable for one environment breaks
  # `terraform plan` in the others.
  count = local.atest_history_enabled ? 1 : 0

  name                = var.storage_atest_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
  enable_telemetry    = var.vnet_enable_telemetry

  account_tier             = var.storage_atest_account_tier
  account_replication_type = var.storage_atest_replication_type

  # Derived data: every record can be rebuilt by replaying CI runs, so LRS is
  # the right durability tier and a backup policy would be ceremony.
  #
  # No anonymous access and no shared keys — every caller authenticates with
  # Entra over OIDC, the same way the AKS workload identities do.
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  https_traffic_only_enabled      = true
  min_tls_version                 = var.storage_atest_min_tls_version
  public_network_access_enabled   = true

  blob_properties = {
    # OFF, overriding the module's default of true. Blob names here are stable
    # and re-writes are idempotent by design — re-ingesting a shard writes the
    # same bytes to the same name — so versioning would accumulate a version
    # per CI re-run of content that is identical, and bill for it. The value
    # versioning normally provides (recovering an overwrite) is provided
    # instead by the records being reproducible from the pipeline.
    versioning_enabled = false

    # Soft delete IS kept, because the failure it covers is different: a
    # mistyped `atest history prune --keep-days 1` deletes months of history in
    # one call, and unlike an overwrite that is not something CI will rebuild.
    delete_retention_policy = {
      enabled = true
      days    = var.storage_atest_soft_delete_days
    }
  }

  containers = var.storage_atest_containers

  # Retention, enforced by the account rather than by a CI step.
  #
  # `atest history prune` does the same job and runs on main, but it only runs
  # when the pipeline does. A repo that stops merging for a quarter, or a job
  # that is disabled while something else is debugged, would otherwise keep
  # paying for history nobody reads. Belt and braces, and the braces do not
  # depend on the workflow being green.
  #
  # Set deliberately LONGER than atest's read window (default 90 days) so the
  # account never deletes a record the analysis was about to score. Retention
  # is the backstop; the read window is the thing that decides what counts.
  storage_management_policy_rule = {
    expire_run_records = {
      name    = "expire-run-records"
      enabled = true
      filters = {
        blob_types   = ["blockBlob"]
        prefix_match = local.atest_history_prefixes
      }
      actions = {
        base_blob = {
          delete_after_days_since_modification_greater_than = var.storage_atest_retention_days
        }
      }
    }
  }

  role_assignments = merge(
    {
      gha_main_blob_contributor = {
        role_definition_id_or_name = var.storage_atest_role_definition_writer
        principal_id               = module.workload_identities.principal_ids["gha_atest_history"]
      }
    },
    local.gha_pr_env_enabled ? {
      gha_pr_blob_reader = {
        role_definition_id_or_name = var.storage_atest_role_definition_reader
        principal_id               = try(module.workload_identities.principal_ids["gha_pr_env"], "")
      }
    } : {},
  )
}
