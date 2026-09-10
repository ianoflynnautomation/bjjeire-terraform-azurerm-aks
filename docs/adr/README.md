# Architecture Decision Records

Decisions with lasting consequences for this stack, and the reasoning behind
them. Several of them look like security findings from the outside — the ADR
explains why they are deliberate and what would break if reversed.

Format: [MADR](https://adr.github.io/madr/). One file per decision, numbered
sequentially, never renumbered. Superseding a decision means writing a new ADR
and flipping the old one's status — not editing it.

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-adopt-azure-verified-modules.md) | Azure resources go through Azure Verified Modules, pinned by registry version | Accepted |
| [0002](0002-keep-key-vault-public-data-plane.md) | Key Vault keeps its public data plane enabled | Accepted |
| [0003](0003-public-aks-api-server.md) | The AKS API server stays public, with authorized IP ranges in prod | Accepted |
| [0004](0004-cloudflare-access-replaces-oauth2-proxy.md) | Cloudflare Access at the edge replaces oauth2-proxy in the request path | Accepted |
| [0005](0005-flat-variables-over-object-inputs.md) | Root module inputs are flat variables, never grouped objects | Accepted |
| [0006](0006-no-plan-artifacts-in-a-public-repo.md) | CI never uploads a Terraform plan artifact | Accepted |
| [0007](0007-user-assigned-control-plane-identity.md) | The AKS control plane uses a user-assigned identity | Accepted |
| [0008](0008-pr-environment-identity-is-dev-only.md) | The PR-environment identity exists on dev only | Accepted |

## Adding one

Copy [`0000-template.md`](0000-template.md), take the next number, and link it
from the table above and from [AGENTS.md](../../AGENTS.md) if an agent could
plausibly try to reverse it.
