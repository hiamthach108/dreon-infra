.PHONY: help local-up local-down platform-install build-local apps-deploy gen-keys setup-hosts status logs

CLUSTER_NAME := dreon-local
NS_SYSTEM    := dreon-system
NS_DEV       := dreon-dev

# Default target
help: ## Show this help
	@echo ""
	@echo "  dreon-infra — local platform commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ─── Cluster ──────────────────────────────────────────────────────────────────

local-up: ## 1. Create k3d cluster + apply namespaces
	@bash scripts/local-up.sh

local-down: ## Destroy the local k3d cluster
	@bash scripts/local-down.sh

# ─── Platform ─────────────────────────────────────────────────────────────────

platform-install: ## 2. Install Kong, PostgreSQL, Redis, RabbitMQ via Helm
	@bash scripts/install-platform.sh

# ─── Apps ─────────────────────────────────────────────────────────────────────

build-local: ## 3. Build Docker images + import into k3d
	@bash scripts/build-push-local.sh

apps-deploy: ## 4. Apply secrets + deploy all app workloads
	@bash scripts/deploy-apps.sh

rebuild: ## Rebuild and restart a specific service (e.g. make rebuild svc=dreon-auth)
	@if [ -z "$(svc)" ]; then echo "Error: Please specify a service name, e.g. make rebuild svc=dreon-auth"; exit 1; fi
	@bash scripts/rebuild-service.sh $(svc)

# ─── Secrets / Keys ───────────────────────────────────────────────────────────

gen-keys: ## Generate RS256 keypair for dreon-auth (run once)
	@bash scripts/gen-keys.sh

setup-hosts: ## Add api.dreon.local to /etc/hosts (requires sudo)
	@if grep -q "api.dreon.local" /etc/hosts; then \
		echo "✅  api.dreon.local already in /etc/hosts"; \
	else \
		echo "127.0.0.1 api.dreon.local" | sudo tee -a /etc/hosts; \
		echo "✅  Added api.dreon.local → 127.0.0.1"; \
	fi

# ─── Observability ────────────────────────────────────────────────────────────

status: ## Show pod status in both namespaces
	@echo "\n📦 Platform ($(NS_SYSTEM)):"
	@kubectl get pods -n $(NS_SYSTEM)
	@echo "\n🚀 Apps ($(NS_DEV)):"
	@kubectl get pods -n $(NS_DEV)
	@echo "\n🌐 Ingress:"
	@kubectl get ingress -n $(NS_DEV)

logs-auth: ## Tail dreon-auth logs
	kubectl logs -n $(NS_DEV) -l app=dreon-auth -f

logs-notification: ## Tail dreon-notification logs
	kubectl logs -n $(NS_DEV) -l app=dreon-notification -f

kong-admin: ## Port-forward Kong Admin API to localhost:8001
	kubectl port-forward -n $(NS_SYSTEM) svc/kong-kong-admin 8001:8001

rmq-ui: ## Port-forward RabbitMQ Management UI to localhost:15672
	kubectl port-forward -n $(NS_SYSTEM) svc/rabbitmq 15672:15672

pg-connect: ## Open a psql shell to the shared Postgres
	kubectl exec -it -n $(NS_SYSTEM) \
		$$(kubectl get pod -n $(NS_SYSTEM) -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}') \
		-- psql -U postgres
