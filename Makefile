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

## Umbrella chart
NAMESPACE ?= monitoring
RELEASE ?= monitoring-stack
CHART_DIR ?= charts/monitoring-stack

.PHONY: helm.deps helm.lock render deploy deploy-kind uninstall status pf.grafana smoke.traces smoke.logs logs.otelcol ds.health

helm.deps:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo add opentelemetry https://open-telemetry.github.io/opentelemetry-helm-charts
	helm repo update
	helm dependency update $(CHART_DIR)

helm.deps:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo add opentelemetry https://open-telemetry.github.io/opentelemetry-helm-charts
	helm repo update
	helm dependency update $(CHART_DIR)

render: helm.deps
	helm template $(RELEASE) $(CHART_DIR) -n $(NAMESPACE) >/dev/null

deploy: helm.deps
	helm upgrade --install $(RELEASE) $(CHART_DIR) -n $(NAMESPACE) --create-namespace

deploy-kind: helm.deps
	helm upgrade --install $(RELEASE) $(CHART_DIR) -n $(NAMESPACE) --create-namespace \
		-f $(CHART_DIR)/values-kind.yaml

uninstall:
	-helm uninstall $(RELEASE) -n $(NAMESPACE)

status:
	kubectl -n $(NAMESPACE) get pods,svc

pf.grafana:
	kubectl -n $(NAMESPACE) port-forward svc/cno-mon-grafana 3000:80

logs.otelcol:
	kubectl -n $(NAMESPACE) logs deploy/otelcol -f --since=10m

ds.health:
	@echo "== Grafana Data Sources should be green (Prometheus/Loki/Tempo) =="
	kubectl -n $(NAMESPACE) get cm -l app.kubernetes.io/name=grafana -o name || true
	kubectl -n $(NAMESPACE) get svc | egrep 'cno-mon-grafana|loki|tempo|otelcol' || true

smoke.traces:
	kubectl -n $(NAMESPACE) run telemetrygen-traces --rm -i --image=ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:latest -- \
		traces --otlp-endpoint=otelcol.$(NAMESPACE).svc.cluster.local:4317 --otlp-insecure --duration=10s

smoke.logs:
	kubectl -n $(NAMESPACE) run telemetrygen-logs --rm -i --image=ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:latest -- \
		logs --otlp-endpoint=http://otelcol.$(NAMESPACE).svc.cluster.local:4318 --otlp-insecure --duration=10s
