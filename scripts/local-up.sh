#!/usr/bin/env bash
# scripts/local-up.sh
# Step 1: Create the k3d cluster and apply namespaces.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "🚀 Creating k3d cluster: dreon-local..."
k3d cluster create --config "$REPO_ROOT/clusters/local/k3d.yaml"

echo ""
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s

echo ""
echo "📁 Applying namespaces..."
kubectl apply -f "$REPO_ROOT/namespaces/"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Cluster is up. Namespaces created:"
kubectl get namespaces | grep dreon
echo ""
echo "Next step → make platform-install"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Setup /etc/hosts hint
if ! grep -q "api.dreon.local" /etc/hosts; then
  echo ""
  echo "💡 Don't forget to add the following to /etc/hosts:"
  echo "   127.0.0.1 api.dreon.local"
  echo ""
  echo "   Run: make setup-hosts"
fi
