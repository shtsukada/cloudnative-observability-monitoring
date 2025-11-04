#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${1:-obs-smoke}"
K8S_VERSION="${2:-v1.30.0}"

cat <<'EOF' >/tmp/kind-smoke.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
EOF

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "[kind] cluster ${CLUSTER_NAME} already exists"
else
  echo "[kind] creating cluster ${CLUSTER_NAME} (${K8S_VERSION})"
  kind create cluster --name "${CLUSTER_NAME}" --image "kindest/node:${K8S_VERSION}" --config /tmp/kind-smoke.yaml
fi

kubectl wait --for=condition=Ready node --all --timeout=120s
echo "[kind] cluster ready"
