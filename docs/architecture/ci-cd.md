# CI/CD

All pipelines authenticate to Azure with OIDC. There are no long-lived cloud
credentials in GitHub secrets — only `TF_VAR_*` application tokens that are not
outputs of this stack.

## Workflows

| Workflow | Trigger | Does |
|---|---|---|
| [`terraform-pipeline.yml`](../../.github/workflows/terraform-pipeline.yml) | `workflow_dispatch` | Quality → IaC scan → plan → optional apply, per environment |
| [`terraform-quality.yml`](../../.github/workflows/terraform-quality.yml) | `workflow_dispatch` | `fmt`, `validate`, tflint via the shared template |
| [`terraform-audit.yml`](../../.github/workflows/terraform-audit.yml) | `workflow_dispatch` | Trivy IaC scan, SARIF to code scanning |
| [`terraform-drift.yml`](../../.github/workflows/terraform-drift.yml) | `workflow_dispatch` | Plan against live state, open/close a drift issue |
| [`terraform-docs.yml`](../../.github/workflows/terraform-docs.yml) | `pull_request`, `workflow_dispatch` | Fail if generated module docs are stale |
| [`renovate.yaml`](../../.github/workflows/renovate.yaml) | schedule | Self-hosted Renovate |

`quality` and `iac-scan` come from
[`bjjeire-ci-templates`](https://github.com/ianoflynnautomation/bjjeire-ci-templates)
as reusable workflows (`workflow_call`), so the linting and scanning contract is
shared across repositories rather than copy-pasted.

> **Currently manual.** The `pull_request` and `push` triggers in
> `terraform-pipeline.yml`, and the `schedule` in `terraform-drift.yml`, are
> commented out. Until they are re-enabled, plan/apply and drift detection run
> only on demand, and the pipeline badge in the README will show no status.

## Authentication

`gha_terraform` federates two subjects: `environment:<env>` and
`ref:refs/heads/main`. Both the plan and apply jobs therefore **must** set
`environment:` — without it there is no matching federated credential and the
token exchange fails.

There is no `pull_request` subject. A pull request can plan against `dev`
(that environment has no reviewers and no branch policy) but cannot obtain a
token for staging or prod, and cannot apply anywhere.

Each job sets `ARM_USE_OIDC: true` and takes `ARM_CLIENT_ID`, `ARM_TENANT_ID`,
`ARM_SUBSCRIPTION_ID` from GitHub Environment **variables** that this stack
writes itself. `permissions: {}` is set at workflow level; jobs request
`id-token: write` and `contents: read` individually.

## Bootstrap

The first apply of any environment runs from a laptop. It creates the
`gha_terraform` identity, creates the GitHub Environment, and writes `ARM_*` and
`TF_STATE_*` onto it. After that, CI can authenticate.

The plan job has a preflight step that fails with an actionable annotation if
`ARM_CLIENT_ID`, `TF_STATE_RG`, `TF_STATE_ACCOUNT`, or the environment's
`terraform.tfvars` are missing.

## Plan and apply

```
setup → quality ─┐
      → iac-scan ─┴→ plan (environment:<env>) → apply (if inputs.apply)
```

`plan` runs `terraform plan -detailed-exitcode`, writes a truncated
`terraform show` into the job step summary, and deletes the plan file in an
`if: always()` step. **No plan artifact is uploaded and no plan comment is
posted** — the binary plan contains every secret this stack manages, and the
repository is public. See
[ADR-0006](../adr/0006-no-plan-artifacts-in-a-public-repo.md).

`apply` runs only when the plan reported changes and the dispatcher asked for
it. It re-plans and applies on the same runner.

The consequence worth naming: **an Environment reviewer approves an
environment, not a diff.** The plan they read in the step summary is not the
artifact that executes. The window is narrowed by the per-environment
`concurrency` group (`cancel-in-progress: false`, so runs queue instead of
racing the state lock), by exact module version pinning, and by drift
detection.

## Drift

`terraform-drift.yml` plans with `-lock=false` against live state and maintains
one issue per environment, labelled `terraform-drift-<env>` — opening or
updating it when drift appears, commenting and closing it when state matches
again.

## Quality gates

- `terraform fmt -check`, `terraform validate`, tflint with
  `.tflint.hcl` (azurerm ruleset, typed/documented variable rules,
  `terraform_workspace_remote` on).
- Trivy IaC scan at `CRITICAL,HIGH`, honouring `.trivyignore` and `trivy.yaml`,
  uploading SARIF under the `trivy-iac` category.
- terraform-docs staleness check on every pull request.
- Locally, `.pre-commit-config.yaml` runs the same fmt/validate/docs/trivy set
  plus `detect-private-key`.

## Dependencies

Renovate runs self-hosted on a schedule. Module PRs never auto-merge; AVM
pre-1.0 minor bumps and all majors need dependency-dashboard approval; provider
and Actions updates are grouped for patch/minor. A reviewed dev plan gates every
promotion. See [ADR-0001](../adr/0001-adopt-azure-verified-modules.md).
