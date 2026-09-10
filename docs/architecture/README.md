# Architecture

How the BjjEire platform is put together. Each page covers one view; start with
[context](context.md) if you are new, or [identity](identity.md) if something
is failing to authenticate.

| Page | Covers |
|---|---|
| [context.md](context.md) | Repository boundaries, system diagram, request path, what this stack provisions |
| [network.md](network.md) | VNet, subnets, NAT Gateway egress, Cloudflare origin lockdown, private DNS |
| [identity.md](identity.md) | Managed identities, federated credentials, Entra app registrations, what gets published to GitHub |
| [secrets.md](secrets.md) | Key Vault → External Secrets → pods, access model, network posture |
| [environments.md](environments.md) | dev / staging / prod matrix, fail-closed prod, state layout, promotion |
| [ci-cd.md](ci-cd.md) | Workflows, OIDC, plan/apply flow, drift detection |

Decisions and their rationale live in [../adr/](../adr/). Operator procedures
live in [../runbooks/](../runbooks/).

## Keeping these accurate

These pages describe the configuration in this repository, not the live estate.
When you change `main.*.tf` in a way that alters topology, identity, or network
posture, update the matching page in the same pull request.

Module inputs and outputs are **generated** by terraform-docs into each
module's `README.md` and checked in CI — never hand-edit the block between the
`BEGIN_TF_DOCS` markers.

The editable diagram is
[`../diagrams/architecture.drawio.svg`](../diagrams/architecture.drawio.svg).
It renders inline on GitHub and opens for editing in
[diagrams.net](https://app.diagrams.net/) or the draw.io VS Code extension.
