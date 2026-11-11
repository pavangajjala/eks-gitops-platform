#!/usr/bin/env bash
# Render every overlay and validate all manifests against their schemas.
# Used by CI and runnable locally: needs kustomize and kubeconform on PATH.
set -euo pipefail

cd "$(dirname "$0")/.."

KUBERNETES_VERSION="${KUBERNETES_VERSION:-1.34.0}"
CRD_SCHEMAS='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

conform() {
  kubeconform -strict -summary \
    -kubernetes-version "$KUBERNETES_VERSION" \
    -schema-location default \
    -schema-location "$CRD_SCHEMAS" \
    "$@"
}

echo "== Argo CD applications and Kyverno policies"
conform gitops/bootstrap gitops/platform gitops/policies

for overlay in gitops/apps/*/overlays/*; do
  echo "== $overlay"
  kustomize build "$overlay" | conform -
done
