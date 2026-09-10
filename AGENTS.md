# Agent guide — bjjeire-terraform-azurerm-aks

Terraform for the BjjEire platform: one root module, three environments
(`dev` / `staging` / `prod`), applied against Azure + Cloudflare + Entra ID +
GitHub. Everything inside the cluster belongs to a different repo — see
[docs/architecture/context.md](docs/architecture/context.md).

**This repository is public.** Never commit a value you would not publish.

## Read this before you change anything

| If you are touching… | Read first |
|---|---|
| Key Vault network settings | [ADR-0002](docs/adr/0002-keep-key-vault-public-data-plane.md) — public access is load-bearing |
| AKS API server exposure | [ADR-0003](docs/adr/0003-public-aks-api-server.md) — private cluster breaks CI |
| Auth, oauth2-proxy, Cloudflare Access | [ADR-0004](docs/adr/0004-cloudflare-access-replaces-oauth2-proxy.md) |
| Any `variable` block | [ADR-0005](docs/adr/0005-flat-variables-over-object-inputs.md) |
| Module sources or versions | [ADR-0001](docs/adr/0001-adopt-azure-verified-modules.md) |
| CI plan/apply flow | [ADR-0006](docs/adr/0006-no-plan-artifacts-in-a-public-repo.md) |
| Identities, federated credentials | [docs/architecture/identity.md](docs/architecture/identity.md) |

The full index is [docs/adr/README.md](docs/adr/README.md). Several settings in
this repo look like security findings and are deliberate; the ADR is where the
reasoning lives. If you think an ADR is wrong, say so — don't silently reverse it.

## Conventions

**Variables are flat.** Every knob is its own top-level `variable` with a
default, so any of them can be overridden from a tfvars file. Never collapse
`var.foo_bar` and `var.foo_baz` into a single object variable, and never
hardcode a per-environment value in HCL. Type everything precisely — no `any`.
Add `description` and, where a wrong value would fail at apply time, a
`validation` block.

**Files are kebab-case, HCL is snake_case.** The root module is split by
concern: `main.<concern>.tf` and `variables.<concern>.tf` (`main.aks.tf`,
`variables.network.tf`, …). Root files carry no project prefix.

**Modules:** singular names (`modules/app-registration/`) are generic
primitives; plural, project-prefixed names
(`modules/bjjeire-app-registrations/`) are compositions specific to this
platform. Each module has `main.tf`, `variables.tf`, `outputs.tf`,
`terraform.tf`, and a generated `README.md`.

**External modules** use registry `source` + an exact `version` (not a range).
Renovate raises the bumps. Do not introduce `git::` sources.

**Environments** differ only by `environments/<env>/terraform.tfvars` and
`backend.hcl`. There is no per-environment HCL and no workspace usage.
Promotion is always **dev → staging → prod**.

## Commands

```bash
terraform init -backend-config=environments/dev/backend.hcl
terraform plan -var-file=environments/dev/terraform.tfvars -out=tfplan
terraform fmt -recursive
terraform validate
tflint --config="$(pwd)/.tflint.hcl"
pre-commit run --all-files          # includes terraform-docs
terraform-docs markdown table --output-file README.md --output-mode inject modules/<name>
```

`plan` needs `TF_VAR_*` secrets in the environment; see
[docs/runbooks/setup.md](docs/runbooks/setup.md). Never run `apply` against
staging or prod from a laptop — those go through `workflow_dispatch` with
GitHub Environment reviewers.

## Hard rules

- **Never `git commit` or `git push`.** Leave changes in the working tree; the
  maintainer commits.
- **Never apply to prod.** Dev only, and only when asked.
- **Never source `.env`.** It is a command cheat-sheet containing live prod
  apply/destroy lines. Grep it for a value if you need one.
- **Never commit secrets.** `cloudflare_api_token`, `github_app_private_key`,
  `ghcr_pat`, `github_preview_pat`, and `private_email` arrive as `TF_VAR_*`.
  Generated passwords go to Key Vault. Plans, state files, and `*.pem` are
  gitignored — keep them that way.
- **Never commit tenant, subscription, or client IDs** in scratch notes or docs.
- **Regenerate module docs** after changing a module's variables or outputs, or
  CI fails.

## Where things live

```
main.*.tf              root composition, one concern per file
variables.*.tf         flat variables
modules/               local modules (Cloudflare, Entra, budget)
environments/<env>/    backend.hcl + terraform.tfvars
docs/adr/              decisions and their rationale
docs/architecture/     how the platform is put together
docs/runbooks/         one-time and recurring operator procedures
docs/diagrams/         architecture.drawio.svg (editable in draw.io)
.github/workflows/     pipeline, quality, audit, drift, docs, renovate
```

## Related repositories

`bjjeire-terraform-gitops-flux-bootstrap` (Flux bootstrap, consumes this
stack's client IDs) · `bjjeire-gitops` (everything in-cluster) · `bjjeire`
(API, SPA, seeder) · `bjjeire-tests` (Playwright / atest).

A change here that renames or recreates an identity usually needs a matching
change in the bootstrap repo. See
[docs/architecture/identity.md](docs/architecture/identity.md#after-a-teardown).
