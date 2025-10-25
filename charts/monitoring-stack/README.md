# monitoring-stack (Umbrella Chart)

## 目的
Prometheus/GrafanaにLoki/Tempo/OTel Collectorを統合した**Umbrella チャート**。
- OTLP→Tempo(traces)
- OTLP→Loki(logs)
- Grafana Data sources(Prometheus/Loki/Tempo)のヘルス緑化

## サブチャート
- prometheus-community/kube-prometheus-stack(alias:`kps`)
- grafana/loki(alias:`loki`)
- grafana/tempo(alias:`tempo`)
- open-telemetry/opentelemetry-collector(alias:`otelcol`)

## Dashboards(Minimal)
Grafanaに最小セットのダッシュボード3枚を作成します。
- Kubernetes-Minimal(UID: cno-k8s-min):CPU/Memory WS/Pod Restart/Nodes Ready/Pods Running-Pending
- Operator/Prometheus-Minimal(UID: cno-operator-min):Target Health（up）/ Rule Eval Duration p95 / Controller Reconcile Errors
- gRPC App-Minimal(UID: cno-grpc-min):RPS / Latency p95,p99（grpc_server_handling_seconds_bucket）/ Error Rate / Status Codes



## 契約(Contract)
- Namespace: `.Values.global.namespace` (固定 :`monitoring`)
- 今後の拡張(後続ブランチで実装)
  - Grafana Datasources 自動登録（`contracts.datasources.enabled`）
  - Loki/Tempo/OTel Collector 導線（`contracts.logs.toLoki` / `contracts.traces.toTempo`）
  - ServiceMonitor/PodMonitor（パス/ポート切替）契約の追加

## デプロイ
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add opentelemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

helm dependency update charts/monitoring-stack
helm upgrade --install monitoring-stack charts/monitoring-stack -n monitoring --create-namespace










