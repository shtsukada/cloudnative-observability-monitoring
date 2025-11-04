#!/usr/bin/env bash
set -euo pipefail

RELEASE="${RELEASE:-cno-mon}"
NAMESPACE="${NAMESPACE:-monitoring}"

echo "[info] namespace=${NAMESPACE} release=${RELEASE}"

need() { command -v "$1" >/dev/null || { echo "missing $1"; exit 1; }; }
for b in kubectl jq curl base64; do need "$b"; done

# ---- service name resolver (try candidates in order) ----
resolve_svc() {
  local ns="$1"; shift
  local name
  for name in "$@"; do
    if kubectl -n "$ns" get svc "$name" >/dev/null 2>&1; then
      echo "$name"
      return 0
    fi
  done
  return 1
}

# Your current cluster shows the following services:
# grafana: cno-mon-grafana
# prometheus: kps-prometheus
# alertmanager: kps-alertmanager
# loki: loki
# tempo: tempo
SVC_GRAFANA="$(resolve_svc "$NAMESPACE" \
  "${RELEASE}-grafana" \
  "cno-mon-grafana" \
  "grafana" \
)"; : "${SVC_GRAFANA:?grafana service not found}"

SVC_PROM="$(resolve_svc "$NAMESPACE" \
  "${RELEASE}-kube-prometheus-stack-prometheus" \
  "kps-prometheus" \
  "prometheus" \
)"; : "${SVC_PROM:?prometheus service not found}"

SVC_AM="$(resolve_svc "$NAMESPACE" \
  "${RELEASE}-kube-prometheus-stack-alertmanager" \
  "kps-alertmanager" \
  "alertmanager" \
)"; : "${SVC_AM:?alertmanager service not found}"

SVC_LOKI="$(resolve_svc "$NAMESPACE" \
  "${RELEASE}-loki" \
  "loki" \
)"; : "${SVC_LOKI:?loki service not found}"

SVC_TEMPO="$(resolve_svc "$NAMESPACE" \
  "${RELEASE}-tempo" \
  "tempo" \
)"; : "${SVC_TEMPO:?tempo service not found}"

echo "[svc] grafana=${SVC_GRAFANA} prometheus=${SVC_PROM} alertmanager=${SVC_AM} loki=${SVC_LOKI} tempo=${SVC_TEMPO}"

# ---- Port-Forward (background) ----
PF_LOG=/tmp/smoke-port-forward.log
: > "${PF_LOG}"

cleanup() {
  echo "[cleanup] killing port-forwards"
  pkill -f "kubectl -n ${NAMESPACE} port-forward" || true
}
trap cleanup EXIT

# local ports
L_PROM=9090
L_AM=9093
L_GRAFANA=3000
L_LOKI=3100
L_TEMPO=3200

# remote ports (per svc spec)
R_PROM=9090
R_AM=9093
R_GRAFANA=80
R_LOKI=3100
R_TEMPO=3200

kubectl -n "${NAMESPACE}" port-forward svc/"${SVC_PROM}"    ${L_PROM}:${R_PROM}       >>"${PF_LOG}" 2>&1 &
kubectl -n "${NAMESPACE}" port-forward svc/"${SVC_AM}"      ${L_AM}:${R_AM}           >>"${PF_LOG}" 2>&1 &
kubectl -n "${NAMESPACE}" port-forward svc/"${SVC_GRAFANA}" ${L_GRAFANA}:${R_GRAFANA} >>"${PF_LOG}" 2>&1 &
kubectl -n "${NAMESPACE}" port-forward svc/"${SVC_LOKI}"    ${L_LOKI}:${R_LOKI}       >>"${PF_LOG}" 2>&1 &
kubectl -n "${NAMESPACE}" port-forward svc/"${SVC_TEMPO}"   ${L_TEMPO}:${R_TEMPO}     >>"${PF_LOG}" 2>&1 &

wait_port() {
  local url="$1" name="$2" tries=60
  until curl -sSf "$url" >/dev/null 2>&1; do
    ((tries--)) || { echo "[fail] $name not responding: $url"; echo "----- pf log -----"; tail -n 120 "${PF_LOG}" || true; exit 1; }
    sleep 2
  done
  echo "[ok] $name up: $url"
}
wait_port "http://127.0.0.1:${L_PROM}/-/ready" "prometheus"
wait_port "http://127.0.0.1:${L_AM}/-/ready" "alertmanager"
wait_port "http://127.0.0.1:${L_GRAFANA}/api/health" "grafana"
wait_port "http://127.0.0.1:${L_LOKI}/ready" "loki"
wait_port "http://127.0.0.1:${L_TEMPO}/ready" "tempo"

# ---- 1) Prometheus targets UP ----
echo "[step] Prometheus targets"
targets_json="$(curl -sS "http://127.0.0.1:${L_PROM}/api/v1/targets?state=active")"

# 動的に job 名を検出（例: kps-prometheus / kps-alertmanager など）
prom_job="$(echo "$targets_json" | jq -r '.data.activeTargets[].labels.job' | grep -i '^.*prometheus.*$' | head -n1 || true)"
am_job="$(  echo "$targets_json" | jq -r '.data.activeTargets[].labels.job' | grep -i '^.*alertmanager.*$' | head -n1 || true)"

# 見つからない場合のフォールバックも用意
prom_job="${prom_job:-prometheus}"
am_job="${am_job:-alertmanager}"

echo "[detect] prom_job=${prom_job} am_job=${am_job}"

required_jobs=( "kube-state-metrics" "node-exporter" "${prom_job}" "${am_job}" )

for job in "${required_jobs[@]}"; do
  up_count="$(echo "$targets_json" | jq --arg j "$job" '[.data.activeTargets[] | select(.labels.job==$j and .health=="up")] | length')"
  echo "  - ${job} up=${up_count}"
  [[ "$up_count" -ge 1 ]] || { echo "[fail] job=${job} not up"; exit 1; }
done
echo "[ok] Prometheus targets are up"

# ---- 2) Loki push & query ----
echo "[step] Loki push/query"
ts_ns="$(date +%s%N)"
msg="smoke-$RANDOM"
payload=$(cat <<JSON
{
  "streams": [
    {
      "stream": { "job": "smoke", "app": "monitoring-stack" },
      "values": [[ "${ts_ns}", "${msg}" ]]
    }
  ]
}
JSON
)
curl -sS -X POST "http://127.0.0.1:${L_LOKI}/loki/api/v1/push" \
  -H "Content-Type: application/json" -d "${payload}" >/dev/null

sleep 2
qr=$(curl -sS "http://127.0.0.1:${L_LOKI}/loki/api/v1/query_range" \
  --get --data-urlencode 'query={job="smoke"}' --data-urlencode "limit=10")
hit=$(echo "$qr" | jq '[.data.result[]?.values[]? | select(.[1]=="'"$msg"'")] | length')
echo "  - loki hits=${hit}"
[[ "$hit" -ge 1 ]] || { echo "[fail] loki did not return the pushed log"; exit 1; }
echo "[ok] Loki round-trip ok"

# ---- 3) Tempo ready ----
echo "[step] Tempo readiness"
curl -sSf "http://127.0.0.1:${L_TEMPO}/ready" >/dev/null
echo "[ok] Tempo /ready 200"

# ---- 4) Grafana health + datasources + dashboard endpoint 200 ----
echo "[step] Grafana datasources & dashboard endpoints"
GRAFANA_SECRET="${RELEASE}-grafana"
admin_pass=$(kubectl -n "${NAMESPACE}" get secret "${GRAFANA_SECRET}" -o jsonpath='{.data.admin-password}' 2>/dev/null | base64 -d || true)

# 一部のチャートでは Secret 名が異なることがあるためフォールバック
if [[ -z "${admin_pass}" ]]; then
  # よくあるフォールバック名
  for s in "cno-mon-grafana" "grafana"; do
    admin_pass=$(kubectl -n "${NAMESPACE}" get secret "$s" -o jsonpath='{.data.admin-password}' 2>/dev/null | base64 -d || true)
    [[ -n "$admin_pass" ]] && break
  done
fi

if [[ -z "${admin_pass}" ]]; then
  echo "[warn] could not resolve grafana admin password secret; trying unauthenticated endpoints only"
  # /api/health は認証不要でも200返る構成が多い
  curl -sSf "http://127.0.0.1:${L_GRAFANA}/api/health" >/dev/null
else
  auth_hdr="Authorization: Basic $(printf "admin:%s" "$admin_pass" | base64)"
  curl -sSf -H "$auth_hdr" "http://127.0.0.1:${L_GRAFANA}/api/health" | jq -r '.database' | grep -qi "ok"
  ds_json=$(curl -sS -H "$auth_hdr" "http://127.0.0.1:${L_GRAFANA}/api/datasources")
  for need in "prometheus" "loki" "tempo"; do
    if echo "$ds_json" | jq -r '.[].type' | grep -qi "^${need}\$"; then
      echo "  - datasource ${need} found"
    else
      echo "[fail] datasource ${need} not found"; exit 1;
    fi
  done
  first_uid=$(curl -sS -H "$auth_hdr" "http://127.0.0.1:${L_GRAFANA}/api/search?type=dash-db&query=" | jq -r '.[0].uid // empty')
  if [[ -z "$first_uid" ]]; then
    echo "[fail] no dashboards returned by /api/search"; exit 1;
  fi
  curl -sSf -H "$auth_hdr" "http://127.0.0.1:${L_GRAFANA}/api/dashboards/uid/${first_uid}" >/dev/null
fi
echo "[ok] Grafana APIs ok"

echo "SMOKE RESULT: OK"
