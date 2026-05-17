#!/usr/bin/env bash
# Build gitea-mcp from source for freebsd-amd64. Upstream doesn't publish a
# FreeBSD binary, so we compile it ourselves on the bsd-ws01 runner.
#
# Usage: build-from-source-freebsd.sh <version>
# Output: dist-cache/extract-freebsd-amd64/gitea-mcp

set -euo pipefail

VERSION="${1:?usage: build-from-source-freebsd.sh <version>}"
ROOT="$(pwd)"
CACHE="$ROOT/dist-cache"
SRC="$CACHE/src-gitea-mcp-${VERSION}"
OUT_DIR="$CACHE/extract-freebsd-amd64"

mkdir -p "$CACHE"
rm -rf "$SRC" "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "==> cloning upstream gitea-mcp v${VERSION}"
git clone --depth 1 --branch "v${VERSION}" \
  https://gitea.com/gitea/gitea-mcp.git "$SRC"

echo "==> go build freebsd/amd64"
( cd "$SRC" && GOOS=freebsd GOARCH=amd64 go build -trimpath -ldflags "-s -w" -o "$OUT_DIR/gitea-mcp" . )

# Copy upstream license alongside so we preserve attribution
cp "$SRC/LICENSE" "$OUT_DIR/LICENSE" 2>/dev/null || true

ls -la "$OUT_DIR"
echo "==> freebsd-amd64 build complete"
