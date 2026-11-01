.PHONY: up down restart logs status ps clean test-alert reload-prometheus help

# Default target
help: ## Show this help message
	@echo ""
	@echo "  Monitoring Stack — Available Commands"
	@echo "  ────────────────────────────────────────"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

up: ## Start the full monitoring stack
	@echo "🚀 Starting monitoring stack..."
	docker compose up -d
	@echo ""
	@echo "✅ Stack is up!"
	@echo "   Prometheus:   http://127.0.0.1:9090"
	@echo "   Grafana:      http://127.0.0.1:3000"
	@echo "   Alertmanager: http://127.0.0.1:9093"
	@echo "   cAdvisor:     http://127.0.0.1:8080"

down: ## Stop the full monitoring stack
	@echo "🛑 Stopping monitoring stack..."
	docker compose down

restart: ## Restart all services
	@echo "🔄 Restarting monitoring stack..."
	docker compose restart

logs: ## Tail logs from all services
	docker compose logs -f --tail=50

status: ## Show health status of all services
	@echo ""
	@echo "  Service Status"
	@echo "  ──────────────"
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker compose ps
	@echo ""
	@echo "  Health Checks"
	@echo "  ─────────────"
	@curl -sf http://127.0.0.1:9090/-/healthy >/dev/null 2>&1 && echo "  ✅ Prometheus  — healthy" || echo "  ❌ Prometheus  — unreachable"
	@curl -sf http://127.0.0.1:9093/-/healthy >/dev/null 2>&1 && echo "  ✅ Alertmanager — healthy" || echo "  ❌ Alertmanager — unreachable"
	@curl -sf http://127.0.0.1:3000/api/health >/dev/null 2>&1 && echo "  ✅ Grafana      — healthy" || echo "  ❌ Grafana      — unreachable"
	@curl -sf http://127.0.0.1:9100/metrics >/dev/null 2>&1 && echo "  ✅ Node Exporter — healthy" || echo "  ❌ Node Exporter — unreachable"
	@curl -sf http://127.0.0.1:8080/metrics >/dev/null 2>&1 && echo "  ✅ cAdvisor      — healthy" || echo "  ❌ cAdvisor      — unreachable"
	@echo ""

ps: ## Show running containers
	docker compose ps

clean: ## Stop stack and remove all data volumes
	@echo "⚠️  This will delete all Prometheus and Grafana data!"
	@read -p "   Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	docker compose down -v
	@echo "🗑  All data volumes removed."

test-alert: ## Run alert pipeline smoke test (requires stress-ng)
	@echo "🧪 Running alert pipeline test..."
	bash scripts/test-alert.sh

reload-prometheus: ## Hot-reload Prometheus config without restart
	@echo "🔄 Reloading Prometheus configuration..."
	curl -sf -XPOST http://127.0.0.1:9090/-/reload && echo "✅ Prometheus config reloaded" || echo "❌ Failed to reload"

validate: ## Validate Prometheus config and rules
	@echo "🔍 Validating configuration files..."
	docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
	docker compose exec prometheus promtool check rules /etc/prometheus/alert_rules.yml
	@echo "✅ All configs valid"
