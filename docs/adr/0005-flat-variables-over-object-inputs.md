# ADR-0005: Root module inputs are flat variables, never grouped objects

- **Status:** Accepted
- **Date:** 2026-09-08 (recorded; decision predates this record)
- **Applies to:** every `variables.*.tf` in the root module

## Context

Three environments share one root module. Everything that differs between them
lives in `environments/<env>/terraform.tfvars` — there is no per-environment
HCL, no `count` on environment name to select resource shapes, and no
workspaces.

That only holds if every setting is individually overridable. The moment a
group of related settings is collapsed into one object variable, overriding one
field in tfvars means restating the whole object, and defaults inside the
object stop applying.

## Decision

Each setting is its own top-level `variable` with a type, a description, and a
default that is safe for dev. There are currently around 280 of them across ten
`variables.*.tf` files, split by concern to match the `main.*.tf` split.

Rules:

- **No `any` types.** Every variable is precisely typed. `tflint`'s
  `terraform_typed_variables` rule enforces this.
- **`description` on everything.** Enforced by
  `terraform_documented_variables`.
- **`validation` blocks where a wrong value fails late.** Around 90 of them
  today. Prefer failing at plan time with a sentence explaining the fix over
  failing at apply time with an Azure API error.
- **Environment-conditional defaults use `coalesce`,** so the variable stays
  overridable — for example
  `coalesce(var.gha_pr_env_enabled, var.environment == "dev")` in
  `main.identity.tf`. Never branch on `var.environment` alone; that hardcodes a
  policy nobody can override from tfvars.

Grouped objects are acceptable *inside* a module boundary where the whole
object is the unit of configuration — `var.kv_network_acls`,
`var.storage_images_containers`, `var.api_app_roles` — because AVM modules take
them that way and callers replace them wholesale.

## Consequences

- `variables.*.tf` is large, and adding a setting means writing a full variable
  block rather than adding a field to an object. That verbosity is the point.
- Any environment can override any knob without touching HCL, which is what
  keeps "one root module, three environments, zero per-environment code" true.
- A new setting must ship with a default that preserves existing behaviour, or
  every committed tfvars breaks at once.
- Refactoring several `var.foo_*` into `var.foo` is a breaking change to all
  three tfvars files and to the setup runbook. Do not do it as cleanup.

## Alternatives considered

- **One object per concern** (`var.aks = { ... }`). Fewer, tidier declarations;
  loses per-field defaulting and forces tfvars to restate whole blocks.
- **Terragrunt with per-environment HCL.** Solves the same problem with a layer
  of tooling and a second language. Rejected as disproportionate for three
  environments of one stack.
- **Workspaces.** Rejected: state separation is already handled by per-env
  backend keys, and workspaces make environment differences invisible in the
  configuration. `tflint`'s `terraform_workspace_remote` rule is enabled to
  keep them out.
