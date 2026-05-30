#!/usr/bin/env bash
# scripts/local-down.sh
# Tears down the local k3d cluster.

set -euo pipefail

echo "🛑 Deleting k3d cluster: dreon-local..."
k3d cluster delete dreon-local

echo ""
echo "✅ Cluster deleted. Docker volumes for platform services are also removed."
echo "   To restart cleanly: make local-up && make platform-install && make apps-deploy"
