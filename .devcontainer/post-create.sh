#!/usr/bin/env bash
#
# Idempotent Dev Container bootstrap.
# Kept intentionally small — tool *installation* is declarative (see devcontainer.json
# Features). This only prepares caches and surfaces versions so any drift from CI is
# visible in the creation log.
set -euo pipefail

# Docker creates named-volume mount points owned by root, so every cache we
# mount into $HOME lands unwritable for `vscode` — `az login`, the provider
# cache and `tflint --init` all fail with "permission denied" until this runs.
echo "==> Claiming mounted cache volumes"
for dir in "${HOME}/.azure" "${HOME}/.terraform.d/plugin-cache" "${HOME}/.tflint.d" "${HOME}/.kube" "${HOME}/.minikube"; do
  [ -d "${dir}" ] || continue
  [ -O "${dir}" ] || sudo chown -R "$(id -u):$(id -g)" "${dir}"
done
# kubectl refuses group/world-readable kubeconfigs for some auth plugins.
chmod 700 "${HOME}/.kube" 2>/dev/null || true

echo "==> Preparing Terraform provider plugin cache"
mkdir -p "${TF_PLUGIN_CACHE_DIR:-$HOME/.terraform.d/plugin-cache}"

# Flux CLI. There is no maintained devcontainer Feature for flux, so we install the
# single static binary here. Idempotent: skipped if already on PATH. Pin with
# FLUX_VERSION on the host (e.g. FLUX_VERSION=2.4.0) to match a specific release.
if ! command -v flux >/dev/null 2>&1; then
  echo "==> Installing flux CLI"
  curl -fsSL https://fluxcd.io/install.sh | sudo -E bash \
    || echo "   (flux install skipped/failed — needs network; run the curl again once online)"
fi

# kubelogin — required to talk to the cluster at all: dev/staging run with
# aks_local_account_disabled = true, so `az aks get-credentials` writes an
# Entra exec-plugin kubeconfig and kubectl fails without this binary. The Azure
# CLI ships a matching build; send its bundled kubectl to a throwaway path so we
# keep the Feature's kubectl on PATH.
if ! command -v kubelogin >/dev/null 2>&1; then
  echo "==> Installing kubelogin (Entra auth for AKS)"
  KUBELOGIN_TMP="$(mktemp -d)"
  if az aks install-cli --install-location "${KUBELOGIN_TMP}/kubectl-unused" \
       --kubelogin-install-location "${KUBELOGIN_TMP}/kubelogin" >/dev/null 2>&1; then
    sudo install -m 0755 "${KUBELOGIN_TMP}/kubelogin" /usr/local/bin/kubelogin
  else
    echo "   (kubelogin install skipped — needs network; rerun 'az aks install-cli')"
  fi
  rm -rf "${KUBELOGIN_TMP}"
fi

# Warm the TFLint plugin cache (downloads the azurerm ruleset pinned in .tflint.hcl).
# Non-fatal: needs network + a GITHUB_TOKEN to avoid rate limits.
if [[ -f .tflint.hcl ]]; then
  echo "==> tflint --init"
  tflint --init || echo "   (tflint --init skipped/failed — run manually once authenticated)"
fi

if [[ -f .pre-commit-config.yaml ]]; then
  if [[ -f .git/hooks/pre-commit ]]; then
    echo "==> pre-commit hook already installed (shared .git — must work on the host too)"
  else
    echo "==> pre-commit hook not installed. Enable it where you commit:"
    echo "     host:      brew install pre-commit terraform-docs && pre-commit install"
    echo "     container: pre-commit install"
  fi
fi

echo ""
echo "==> Tool versions (compare against .github/workflows/*.yml)"
# Two rules in this block, both learned the hard way under `set -euo pipefail`:
#   * no `| head -n1` and no `awk '{...; exit}'` — closing the pipe early sends
#     SIGPIPE upstream, the pipeline returns 141, and `set -e` aborts create
#     even though every tool installed fine. Let awk read to EOF instead.
#   * `|| true` throughout: reporting versions must never fail the build.
{
  terraform version | awk 'NR==1'
  echo "tflint     $(tflint --version | awk 'NR==1')"
  # No backslashes: inside $( ), the single quotes already protect the double
  # quotes, so `\"azure-cli\"` reached az as a literal backslash and the query
  # was rejected — which is why this line always printed "unknown".
  echo "az         $(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo 'unknown')"
  kubectl version --client -o yaml 2>/dev/null | awk '/gitVersion/{if (!seen++) print "kubectl    "$2}'
  # kubelogin prints an empty "kubelogin version" line; the real tag is on the
  # "git hash: v0.2.19/<sha>" line.
  echo "kubelogin  $(kubelogin --version 2>/dev/null | awk -F'[ /]' '/git hash/{print $3}' || echo 'not installed')"
  echo "flux       $(flux version --client 2>/dev/null | awk '/flux:/{print $2}')"
  echo "trivy      $(trivy --version 2>/dev/null | awk '/Version/{if (!seen++) print $2}')"
} || true

cat <<'EOF'

==> Ready. Next steps:
    az login                 # or set ARM_CLIENT_ID/SECRET/TENANT/SUBSCRIPTION on the host
    terraform init -backend-config=environments/dev/backend.hcl   # azurerm remote state
    terraform plan  -var-file=environments/dev/example.tfvars
EOF
