#!/usr/bin/env bash
# Assemble the .mcpb bundle from the manifest + fetched binaries.
# Usage: build-bundle.sh <version>
#
# Expects scripts/fetch-upstream.sh has already populated dist-cache/extract-*.
# Writes the bundle to dist/gitea-<version>.mcpb and a sidecar SHA256SUMS.

set -euo pipefail

VERSION="${1:?usage: build-bundle.sh <version>}"
ROOT="$(pwd)"
CACHE="$ROOT/dist-cache"
BUILD="$ROOT/build"
DIST="$ROOT/dist"

# Clean staging
rm -rf "$BUILD"
mkdir -p "$BUILD/server" "$DIST"

# Substitute version into manifest. Tag-driven: the workflow passes the tag
# (minus 'v' prefix) as <version>. We replace the literal "version": "..."
# value in the source manifest.
python3 - <<EOF
import json, sys
m = json.load(open("$ROOT/manifest.json"))
m["version"] = "$VERSION"
json.dump(m, open("$BUILD/manifest.json", "w"), indent=2)
EOF

# Lay out binaries. NOTE: current MCPB v0.3 spec does not differentiate arch
# inside platform_overrides. We ship amd64 in the slot for each OS; arm64
# binaries are available in dist-cache for the per-arch sidecar artifacts.
cp "$CACHE/extract-win-amd64/gitea-mcp.exe"   "$BUILD/server/gitea-mcp.exe"
cp "$CACHE/extract-darwin-amd64/gitea-mcp"    "$BUILD/server/gitea-mcp-darwin"
cp "$CACHE/extract-linux-amd64/gitea-mcp"     "$BUILD/server/gitea-mcp-linux"

# Preserve upstream's LICENSE (any platform's copy will do — they're identical)
cp "$CACHE/extract-linux-amd64/LICENSE" "$BUILD/UPSTREAM_LICENSE"

# Pack as zip with .mcpb extension. cd into BUILD so paths are bundle-relative.
BUNDLE="$DIST/gitea-${VERSION}.mcpb"
rm -f "$BUNDLE"
python3 scripts/_zipdir.py "$BUILD" "$BUNDLE"

# Per-arch sidecar bundles for users who want native arm64 (no Rosetta).
# These contain only the relevant binary; the manifest still references the
# canonical OS slot name (e.g. gitea-mcp-darwin), so install path is identical.
for triple in win-arm64 darwin-arm64 linux-arm64; do
  src="$CACHE/extract-$triple"
  if [ ! -d "$src" ]; then continue; fi
  ARCH_BUILD="$ROOT/build-$triple"
  rm -rf "$ARCH_BUILD"
  mkdir -p "$ARCH_BUILD/server"
  cp "$BUILD/manifest.json" "$ARCH_BUILD/manifest.json"
  cp "$BUILD/UPSTREAM_LICENSE" "$ARCH_BUILD/UPSTREAM_LICENSE"
  case "$triple" in
    win-*)    cp "$src/gitea-mcp.exe" "$ARCH_BUILD/server/gitea-mcp.exe" ;;
    darwin-*) cp "$src/gitea-mcp"     "$ARCH_BUILD/server/gitea-mcp-darwin" ;;
    linux-*)  cp "$src/gitea-mcp"     "$ARCH_BUILD/server/gitea-mcp-linux" ;;
  esac
  ARCH_BUNDLE="$DIST/gitea-${VERSION}-${triple}.mcpb"
  rm -f "$ARCH_BUNDLE"
  python3 scripts/_zipdir.py "$ARCH_BUILD" "$ARCH_BUNDLE"
done

# Optional: pack the freebsd-built binary if present in extract-freebsd-amd64
if [ -d "$CACHE/extract-freebsd-amd64" ] && [ -f "$CACHE/extract-freebsd-amd64/gitea-mcp" ]; then
  FB_BUILD="$ROOT/build-freebsd-amd64"
  rm -rf "$FB_BUILD"
  mkdir -p "$FB_BUILD/server"
  cp "$BUILD/manifest.json" "$FB_BUILD/manifest.json"
  cp "$BUILD/UPSTREAM_LICENSE" "$FB_BUILD/UPSTREAM_LICENSE"
  # MCPB v0.3 doesn't list freebsd in compatibility.platforms; this artifact is
  # for users wiring it into Claude Code / Codex directly, not Claude Desktop.
  cp "$CACHE/extract-freebsd-amd64/gitea-mcp" "$FB_BUILD/server/gitea-mcp-freebsd"
  FB_BUNDLE="$DIST/gitea-${VERSION}-freebsd-amd64.mcpb"
  rm -f "$FB_BUNDLE"
  python3 scripts/_zipdir.py "$FB_BUILD" "$FB_BUNDLE"
fi

# Emit a SHA256SUMS file for all artifacts (matches upstream's pattern)
( cd "$DIST" && sha256sum *.mcpb > SHA256SUMS )

echo "==> built:"
( cd "$DIST" && ls -la *.mcpb SHA256SUMS )
