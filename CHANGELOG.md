# Changelog

## [0.2.0](https://github.com/shtsukada/cloudnative-observability-monitoring/compare/monitoring-stack-v0.1.0...monitoring-stack-v0.2.0) (2025-11-09)


### Features

* **alerts-min:** 最小構成のアラートセットをmonitoring-stack(Umbrella)に追加 ([c94ebf5](https://github.com/shtsukada/cloudnative-observability-monitoring/commit/c94ebf5500a965ff1b898743b28c3778501c0087))
* **chart-skeleton-umbrella:** monitoringスタックを Umbrella Helm Chart で一括デプロイ可能にする土台を追加 ([ad13816](https://github.com/shtsukada/cloudnative-observability-monitoring/commit/ad138169a63a4f0be55846030d16088f7c70f765))
* **chart-skeleton-umbrella:** monitoringスタックを Umbrella Helm Chart で一括デプロイ可能にする土台を追加 ([ba1e560](https://github.com/shtsukada/cloudnative-observability-monitoring/commit/ba1e560770698117009dccdab36bd24af33819f0))
* **dashboards-min:** Grafanaへダッシュボード作成(K8s/Operator/gRPC) ([49209a5](https://github.com/shtsukada/cloudnative-observability-monitoring/commit/49209a546c6a9eb619354d45a4089a9b05add028))
* **datasources-auto:** GrafanaにLoki/Tempoを登録(Umbrella valuesで管理) ([276fcc4](https://github.com/shtsukada/cloudnative-observability-monitoring/commit/276fcc489c0457d635d56c86d3e841d97e2cd0fe))
* **e2e-kind-smoke:** kind上でProm/Loki/Tempo/Grafana の疎通と最小ターゲットUPを自動検証 ([00331ad](https://github.com/shtsukada/cloudnative-observability-monitoring/commit/00331ad7705b273d2597ba77ec3619aa904c9f43))
* **loki-tempo-otelcol:** OTLPログ取込に向けたLokiのTSDB移行 ([daa8d3f](https://github.com/shtsukada/cloudnative-observability-monitoring/commit/daa8d3f8b4f9a23de0040d0ce62ba7a62fd7bf0b))
* **release-automation:** Release Please + Helm OCI配布 + cosign(keyless)署名 + SBOM(syft)導入 ([0c475ac](https://github.com/shtsukada/cloudnative-observability-monitoring/commit/0c475ac2e4bf384d04293fa3414bda6a705cf87c))
* **security-netpolicy:** 監視スタックの通信を最小許可のNetworkPolicyでホワイトリスト化 ([59fe731](https://github.com/shtsukada/cloudnative-observability-monitoring/commit/59fe7319565bace5a577e431b691f70eb248b828))
* **servicemonitors-podmonitors:** ServiceMonitor/PodMonitorをvalue駆動での生成、管理を実装 ([1c8fc53](https://github.com/shtsukada/cloudnative-observability-monitoring/commit/1c8fc53d508e44934125271ecfdd052e289154f6))
