#!/usr/bin/env bash
# scripts/deploy-apps.sh
# Step 4: Apply secrets and deploy all app workloads to dreon-dev.
# Requires secrets/dev/*.secret.yaml to be populated from examples first.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NS="dreon-dev"

# Verify secret files exist
check_secret() {
  local file="$REPO_ROOT/secrets/dev/$1"
  if [ ! -f "$file" ]; then
    echo "❌ Missing secret file: $file"
    echo "   Copy the example and fill in real values:"
    echo "   cp secrets/dev/$1.example.yaml secrets/dev/$1"
    exit 1
  fi
}

check_secret "dreon-auth.secret.yaml"
check_secret "dreon-notification.secret.yaml"

echo "🔐 Applying secrets to $NS..."
kubectl apply -f "$REPO_ROOT/secrets/dev/dreon-auth.secret.yaml"         -n $NS
kubectl apply -f "$REPO_ROOT/secrets/dev/dreon-notification.secret.yaml" -n $NS

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Deploying dreon-auth..."
kubectl apply -f "$REPO_ROOT/apps/dreon-auth/" -n $NS

echo ""
echo "🚀 Deploying dreon-notification..."
kubectl apply -f "$REPO_ROOT/apps/dreon-notification/" -n $NS

echo ""
echo "⏳ Waiting for rollouts to complete..."
kubectl rollout status deployment/dreon-auth         -n $NS --timeout=90s
kubectl rollout status deployment/dreon-notification -n $NS --timeout=90s

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All services deployed. Pods in $NS:"
kubectl get pods -n $NS
echo ""
echo "Ingress routes:"
kubectl get ingress -n $NS
echo ""
echo "Test:"
echo "  curl http://api.dreon.local/api/v1/auth/ping"
echo "  curl http://api.dreon.local/api/v1/notifications/ping"
