#!/usr/bin/env bash
# scripts/gen-keys.sh
# Generates an RS256 keypair for dreon-auth + dreon-api.
# Run once before populating secrets.
#
# Output: keys/dreon-auth.key (private) and keys/dreon-auth.pub (public)
# The PEM content is also printed for easy copy-paste into secret files.

set -euo pipefail

KEYS_DIR="$(cd "$(dirname "$0")/.." && pwd)/keys"
PRIVATE_KEY="$KEYS_DIR/dreon-auth.key"
PUBLIC_KEY="$KEYS_DIR/dreon-auth.pub"

mkdir -p "$KEYS_DIR"

echo "🔑 Generating RS256 keypair (4096-bit)..."
openssl genrsa -out "$PRIVATE_KEY" 4096 2>/dev/null
openssl rsa -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY" 2>/dev/null

echo ""
echo "✅ Keys written to:"
echo "   Private: $PRIVATE_KEY"
echo "   Public:  $PUBLIC_KEY"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "JWT_PRIVATE_KEY (paste into secrets/dev/dreon-auth.secret.yaml)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$PRIVATE_KEY"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "JWT_PUBLIC_KEY (paste into dreon-auth.secret.yaml AND dreon-api.secret.yaml)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$PUBLIC_KEY"
echo ""
echo "⚠️  keys/ is gitignored. Never commit the private key."
