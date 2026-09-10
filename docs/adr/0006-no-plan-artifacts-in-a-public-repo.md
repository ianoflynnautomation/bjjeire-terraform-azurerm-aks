# ADR-0006: CI never uploads a Terraform plan artifact

- **Status:** Accepted
- **Date:** 2026-09-08 (recorded; decision predates this record)
- **Applies to:** `.github/workflows/terraform-pipeline.yml`, `.github/workflows/terraform-drift.yml`

## Context

The usual production pattern is plan-on-PR, upload the binary plan as an
artifact, have a human review it, then apply *that exact file* after merge. It
closes the gap between what was reviewed and what runs.

A Terraform binary plan contains every value the configuration touches,
including sensitive ones, in cleartext. `terraform show` on the plan file
prints them. **This repository is public**, and so are its Actions artifacts and
run logs.

This stack writes the Cloudflare tunnel token, GitHub App private key, GHCR
PAT, generated Grafana and MongoDB passwords, and the AKS SSH private key. All
of those appear in the plan.

## Decision

No plan artifact is uploaded, and no plan output is posted as a PR comment.

- The plan job runs `terraform plan -detailed-exitcode -out=tfplan`, writes a
  truncated `terraform show` into `$GITHUB_STEP_SUMMARY`, and deletes the plan
  file in an `if: always()` step.
- The apply job re-runs `plan` and applies the result in the same step on the
  same runner. The plan file never leaves the job.
- The drift workflow does the same, and posts its report into an issue body
  rather than an artifact.

The step summary is visible to anyone who can see the repository, so it is
treated as public output. Terraform redacts `sensitive` values there; the
binary plan would not have been redacted, which is the whole reason it is not
published.

## Consequences

- **The approval gate approves an environment, not a diff.** A reviewer
  approving a staging or prod deployment is authorising a run, not a specific
  set of changes, because the plan they can see in the summary is not the
  artifact that executes. Between approval and apply, the configuration is
  fixed but the live state may have moved.
- The window is narrowed by the `concurrency` group per environment (no two
  runs for one environment race), by exact module version pinning (ADR-0001),
  and by the scheduled drift check.
- Anyone reintroducing `actions/upload-artifact` for `tfplan`, or a
  plan-comment action, publishes every secret this stack manages. The
  workflow header says so; this ADR is the longer form.
- Reviewing a plan means opening the run's step summary, not a PR comment.

## Alternatives considered

- **Make the repository private.** Removes the constraint entirely and would
  allow the standard reviewed-artifact flow. Rejected because the repository is
  deliberately public as a reference implementation.
- **Upload the plan encrypted.** Requires a key available to the apply job,
  which means the artifact is only as private as that key, in a public repo's
  run history. Adds complexity for a small gain.
- **`terraform plan -out` with all sensitive values sourced at apply time.**
  Not achievable here — the sensitive values *are* the resources being created.
- **HCP Terraform / Terraform Cloud.** Holds plans server-side with proper
  access control and would solve this cleanly. A real option if this outgrows
  GitHub-hosted CI; it adds an external dependency and a cost line today.
