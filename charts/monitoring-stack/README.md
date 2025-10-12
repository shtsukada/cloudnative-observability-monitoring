# monitoring-stack (Umbrella Chart)

**目的**
kube-prometheus-stackを中核に、Loki/Tempo/OTel Collectorなどを段階追加する**Umbrella チャート**。
このブランチだけでPrometheus/Grafana/Alertmanagerを展開できます。

## 成果物
- Umbrella Helm Chart(依存： `kube-prometheus-stack`固定版)
- `values.yaml`の最小契約(namespace固定、retentionなど)
- `values.schema.json`によるバリデーション

## 契約(Contract)
- Namespace: `.Values.global.namespace` (固定 :`monitoring`)
- 今後の拡張(後続ブランチで実装)
  - Grafana Datasources 自動登録（`contracts.datasources.enabled`）
  - Loki/Tempo/OTel Collector 導線（`contracts.logs.toLoki` / `contracts.traces.toTempo`）
  - ServiceMonitor/PodMonitor（パス/ポート切替）契約の追加

## Quickstart（開発用）
```bash
# 依存チャート取得
helm dependency build charts/monitoring-stack

# Dry-run
helm template cno-mon charts/monitoring-stack -n monitoring | head -n 60

# インストール
helm install cno-mon charts/monitoring-stack -n monitoring --create-namespace

# 状態確認
kubectl -n monitoring get pods
kubectl -n monitoring get svc
```

## バージョン固定
- Chart.yaml の dependencies.version は固定（:latest 禁止）
- 将来 renovate-notifications ブランチで上流更新の自動PR

## ロードマップ
- datasources-auto: Grafana datasources 自動登録
- loki-tempo-otelcol: ログ→Loki / OTLP→Tempo 導線
- servicemonitors-podmonitors: 監視対象の増設
- dashboards-min / alerts-min: 最小ダッシュボード/アラート
- security-netpolicy: NetworkPolicy 最小許可
