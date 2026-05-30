#!/usr/bin/env bash
# scripts/install-platform.sh
# Step 2: Install Kong, PostgreSQL, Redis, RabbitMQ via Helm into dreon-system.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "📦 Adding Helm repos..."
helm repo add kong    https://charts.konghq.com      2>/dev/null || true
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo update

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🦍 Installing Kong Gateway..."
helm upgrade --install kong kong/kong \
  --namespace dreon-system \
  --create-namespace \
  --values "$REPO_ROOT/platform/kong/values.local.yaml" \
  --wait --timeout 3m

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐘 Installing PostgreSQL..."
# Create ConfigMap for init scripts first
kubectl create configmap postgres-init-scripts \
  --from-file="$REPO_ROOT/platform/postgres/init/" \
  --namespace dreon-system \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install postgres bitnami/postgresql \
  --namespace dreon-system \
  --values "$REPO_ROOT/platform/postgres/values.local.yaml" \
  --wait --timeout 3m

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🟥 Installing Redis..."
helm upgrade --install redis bitnami/redis \
  --namespace dreon-system \
  --values "$REPO_ROOT/platform/redis/values.local.yaml" \
  --wait --timeout 3m

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐰 Installing RabbitMQ..."
kubectl apply -f "$REPO_ROOT/platform/rabbitmq/rabbitmq.yaml"
# Wait for RabbitMQ to be ready
kubectl rollout status deployment/rabbitmq -n dreon-system --timeout 3m

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Platform installed. Pods in dreon-system:"
kubectl get pods -n dreon-system
echo ""
echo "Next step → make build-local && make apps-deploy"
