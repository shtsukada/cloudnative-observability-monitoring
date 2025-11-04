#!/usr/bin/env bash
set -euo pipefail
CLUSTER_NAME="${1:-obs-smoke}"

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "[kind] deleting cluster ${CLUSTER_NAME}"
  kind delete cluster --name "${CLUSTER_NAME}"
else
  echo "[kind] cluster ${CLUSTER_NAME} not found; nothing to do"
fi
