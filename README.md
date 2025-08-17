# cloudnative-observability-monitoring

Prometheus / Alertmanager / Grafana / Loki / Tempo などの **監視・可観測性スタック** を Helm で提供します。

## 成果物

- kube-prometheus-stack
- Loki, Tempo, OTel Collector
- Grafana Datasource 自動登録
- ダッシュボード 3枚（Operator/K8s/App）
- PrometheusRule + Slack 通知

## 契約

- Slack 通知: `alertmanager-slack`
- OTLP エンドポイント: `OTEL_EXPORTER_OTLP_ENDPOINT`
- Namespace: monitoring

## ディレクトリ（例）

charts/
└─ monitoring-stack/ # 例: まとめチャート or 個別チャート群
├─ Chart.yaml
├─ values.yaml
├─ values-kind.yaml # kind 用の軽量設定（retention短縮/replica=1等）
└─ templates/

## Quickstart

```bash
helm install monitoring oci://ghcr.io/YOUR_ORG/cloudnative-observability-monitoring --version X.Y.Z
```

## MVP

- Prometheus/Loki/Tempo/OTel Collector
- Grafana 自動登録
- ダッシュボード ×3
- 最小 Alert → Slack 通知

## Plus

- Recording Rules/SLO
- Exemplars
- Tail-based Sampling
- Blackbox Exporter

## 受け入れ基準チェックリスト

- [ ] Grafana に P/L/T datasource が登録される
- [ ] Prometheus target up==1
- [ ] zap ログが Loki で検索可能
- [ ] トレースが Tempo に表示される
- [ ] Slack にアラート通知が届く

## スコープ外

- ダッシュボード詳細調整
- Alertmanager の複雑なルーティング

## ライセンス

MIT License
