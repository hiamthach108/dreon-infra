#!/usr/bin/env bash
# scripts/build-push-local.sh
# Step 3: Build Docker images for all services and import them into k3d.
# No registry required — images are loaded directly into the cluster nodes.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVICES_ROOT="$(dirname "$REPO_ROOT")"

CLUSTER_NAME="dreon-local"

build_and_import() {
  local name=$1
  local src_dir=$2
  local tag="${name}:local"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔨 Building $tag from $src_dir..."
  docker build -t "$tag" "$src_dir"

  echo "📤 Importing $tag into k3d cluster '$CLUSTER_NAME'..."
  k3d image import "$tag" -c "$CLUSTER_NAME"
  echo "✅ $tag imported"
}

# Build each service from its sibling directory
build_and_import "dreon-auth"         "$SERVICES_ROOT/dreon-auth"
build_and_import "dreon-notification" "$SERVICES_ROOT/dreon-notification"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All images built and imported."
echo ""
echo "Next step → make apps-deploy"
