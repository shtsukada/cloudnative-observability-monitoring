# Makefile for cloudnative-observability-monitoring
CHART_DIR := charts/monitoring-stack
RELEASE   := cno-mon
NAMESPACE := monitoring

.PHONY: deps lint template install upgrade uninstall install-kind pf-grafana status

## 依存チャート取得（Chart.lock 生成）
deps:
	helm dependency build $(CHART_DIR)

## チャートLint
lint:
	helm lint $(CHART_DIR)

## Dry-run（テンプレート検証）
template:
	helm template $(RELEASE) $(CHART_DIR) -n $(NAMESPACE) > /dev/null

## インストール（学習用デフォルト values）
install:
	helm install $(RELEASE) $(CHART_DIR) -n $(NAMESPACE) --create-namespace

## アップグレード（既存Releaseに反映）
upgrade:
	helm upgrade $(RELEASE) $(CHART_DIR) -n $(NAMESPACE)

## アンインストール
uninstall:
	helm uninstall $(RELEASE) -n $(NAMESPACE) || true

## kind 等ローカル向け（NodePortなどをvalues-kind.yamlで上書き）
install-kind:
	helm install $(RELEASE) $(CHART_DIR) -n $(NAMESPACE) --create-namespace -f $(CHART_DIR)/values-kind.yaml

## Grafanaのポートフォワード（別ターミナルで）
pf-grafana:
	kubectl -n $(NAMESPACE) port-forward svc/kps-grafana 3000:80

## 主要リソースの状態確認
status:
	kubectl -n $(NAMESPACE) get pods,svc
