# ADR-0004: Cloudflare Access at the edge replaces oauth2-proxy in the request path

- **Status:** Accepted
- **Date:** 2026-09-08 (recorded; decision predates this record)
- **Applies to:** `main.cloudflare-access.tf`, `main.oauth2.tf`, `modules/cloudflare-access-idp/`

## Context

Non-production environments need to be gated so that only known people reach
them, and the API needs per-request authorization in every environment. The
original design put oauth2-proxy in front of the frontend inside the cluster,
authenticating against an Entra app registration.

The platform already terminates every request at Cloudflare — the cluster has
no public ingress at all, and traffic arrives through a Cloudflare Tunnel whose
origin is the Istio ingress gateway on `:443`. That makes the edge the natural
place to enforce identity, one hop before anything reaches the cluster.

## Decision

Zero Trust Access enforces identity at the Cloudflare edge, with Entra ID
registered as the OIDC identity provider
(`modules/cloudflare-access-idp/`). The Access application covers
`cluster_domain`, `*.cluster_domain`, and `api-<env>.<root_domain>`.

**oauth2-proxy is not in the request path.** Its app registration
(`main.oauth2.tf`) and its Key Vault secrets — `oauth2-proxy-client-secret`,
`oauth2-proxy-cookie-secret` — are still provisioned, because the GitOps repo
and the Flux bootstrap repo still reference them and removing them would be a
cross-repo change.

Application-level auth is unchanged and independent: the SPA authenticates with
MSAL against the `bjjeire-spa-<env>` registration, and Istio and the API
validate JWTs issued for the `bjjeire-api-<env>` audience.

A Cloudflare service token (`cloudflare_tests_service_token_enabled`) lets CI
bypass Access on dev and staging. It is forced off in prod.

## Consequences

- There are two authentication layers with different jobs, and they are easy to
  confuse. Access answers "may this person reach this environment at all"; MSAL
  and the API JWT check answers "what may this user do". Removing either does
  not substitute for the other.
- The frontend has **no** in-cluster auth proxy. If Access is misconfigured or
  disabled, the SPA is reachable by anyone who can resolve the hostname —
  though the API still rejects unauthenticated calls.
- oauth2-proxy resources look like dead code and are not. Deleting
  `main.oauth2.tf` breaks the Flux bootstrap repo, which reads the app
  registration via a data source, and leaves ExternalSecrets pointing at Key
  Vault entries that no longer exist.
- The Access policy is the gate for human traffic, so its allow-list of emails
  and groups is a production access-control surface, edited in Terraform rather
  than in the Cloudflare dashboard.

## Alternatives considered

- **Keep oauth2-proxy in front of the frontend.** Another in-cluster hop to
  operate and upgrade, duplicating an identity check the edge already performs
  before the request enters the tunnel.
- **Istio `RequestAuthentication` for browser traffic.** Works for APIs, but
  gives no login redirect flow for a browser hitting the SPA cold.
- **Remove the oauth2-proxy registration entirely.** Correct eventually;
  blocked on a coordinated change in `bjjeire-terraform-gitops-flux-bootstrap`
  and `bjjeire-gitops`.
