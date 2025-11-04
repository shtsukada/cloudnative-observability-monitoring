# e2e.mk - kind/e2e専用。既存Makefileは変更せず、これだけで完結させる
SHELL := /usr/bin/env bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

CHART_DIR ?= charts/monitoring-stack
RELEASE ?= cno-mon
NAMESPACE ?= monitoring
VALUES ?= values-kind.yaml

# kind/e2e専用パラメータ
KIND_CLUSTER ?= obs-smoke
K8S_VERSION ?= v1.30.0

.PHONY: tools kind-up kind-down deploy wait smoke e2e clean help

help:
	@echo "Targets (from e2e.mk):"
	@echo "  make -f e2e.mk kind-up # kindクラスタ作成"
	@echo "  make -f e2e.mk deploy # 監視スタックをHelmデプロイ"
	@echo "  make -f e2e.mk wait # Pod Ready待ち(instance=$(RELEASE))"
	@echo "  make -f e2e.mk smoke # スモーク(docs/smoke-sample.logへ)"
	@echo "  make -f e2e.mk kind-down # kindクラスタ削除"
	@echo "  make -f e2e.mk e2e # 一括(up->deploy->smoke->down)"
	@echo ""
	@echo "Vars"
	@echo "  CHART_DIR=$(CHART_DIR)"
	@echo "  RELEASE=$(RELEASE)"
	@echo "  NAMESPACE=$(NAMESPACE)"
	@echo "  VALUES=$(VALUES)"
	@echo "  KIND_CLUSTER=$(KIND_CLUSTER)"
	@echo "  K8S_VERSION=$(K8S_VERSION)"

tools:
	@command -v kind >/dev/null || { echo "kind not found"; exit 1; }
	@command -v kubectl >/dev/null || { echo "kubectl not found"; exit 1; }
	@command -v helm >/dev/null || { echo "helm not found"; exit 1; }
	@command -v jq >/dev/null || { echo "jq not found"; exit 1; }
	@command -v curl >/dev/null || { echo "curl not found"; exit 1; }

kind-up: tools
	hack/kind-up.sh "$(KIND_CLUSTER)" "$(K8S_VERSION)"

deploy:
	helm upgrade --install "$(RELEASE)" "$(CHART_DIR)" \
		--namespace "$(NAMESPACE)" --create-namespace \
		-f "$(CHART_DIR)/$(VALUES)"
	$(MAKE) -f e2e.mk wait

wait:
	@echo "[wait] pods ready (ns=$(NAMESPACE) instance=$(RELEASE))"
	tries=20; \
	while [ $$tries -gt 0 ]; do \
	not_ready=$$(kubectl -n "$(NAMESPACE)" get pods -l app.kubernetes.io/instance="$(RELEASE)" --no-headers 2>/dev/null \
		| awk '{print $$3}' \
		| grep -Ev '^(Running|Completed)$$' \
		| wc -l | tr -d ' '); \
	total=$$(kubectl -n "$(NAMESPACE)" get pods -l app.kubernetes.io/instance="$(RELEASE)" --no-headers 2>/dev/null | wc -l | tr -d ' '); \
	if [ "$$total" -gt 0 ] && [ "$$not_ready" -eq 0 ]; then \
		echo "[ok] all pods ready ($$total pods)"; \
		exit 0; \
	fi; \
	tries=$$((tries-1)); \
	echo "[wait] remaining=$$tries (not_ready=$$not_ready, total=$$total)"; \
	sleep 30; \
	done; \
	echo "[fail] pods did not become ready in time"; \
	kubectl -n "$(NAMESPACE)" get pods -l app.kubernetes.io/instance="$(RELEASE)" -o wide || true; \
	exit 1

smoke:
	RELEASE="$(RELEASE)" NAMESPACE="$(NAMESPACE)" bash hack/smoke.sh | tee docs/smoke-sample.log
	@grep -q "SMOKE RESULT: OK" docs/smoke-sample.log

kind-down:
	hack/kind-down.sh "$(KIND_CLUSTER)"

e2e: kind-up deploy smoke kind-down
	@echo "E2E finished successfully"

clean:
	@rm -f docs/smoke-sample.log
