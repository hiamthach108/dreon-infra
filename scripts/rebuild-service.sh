#!/usr/bin/env bash
# scripts/rebuild-service.sh
# Rebuilds a single service, imports it to k3d, and restarts its deployment.
# Usage: ./scripts/rebuild-service.sh <service-name>

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <service-name>"
  echo "Example: $0 dreon-api"
  exit 1
fi

SERVICE_NAME="$1"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVICES_ROOT="$(dirname "$REPO_ROOT")"
CLUSTER_NAME="dreon-local"
NS="dreon-dev"
SRC_DIR="$SERVICES_ROOT/$SERVICE_NAME"

if [ ! -d "$SRC_DIR" ]; then
  echo "❌ Error: Directory $SRC_DIR does not exist."
  exit 1
fi

TAG="${SERVICE_NAME}:local"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 Building $TAG from $SRC_DIR..."
docker build -t "$TAG" "$SRC_DIR"

echo ""
echo "📤 Importing $TAG into k3d cluster '$CLUSTER_NAME'..."
k3d image import "$TAG" -c "$CLUSTER_NAME"

echo ""
echo "🔄 Restarting deployment $SERVICE_NAME in namespace $NS..."
kubectl rollout restart deployment/"$SERVICE_NAME" -n "$NS"

echo ""
echo "⏳ Waiting for rollout to complete..."
kubectl rollout status deployment/"$SERVICE_NAME" -n "$NS" --timeout=90s

echo ""
echo "✅ Successfully rebuilt and restarted $SERVICE_NAME"
