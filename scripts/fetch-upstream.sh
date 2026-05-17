#!/usr/bin/env bash
# Download upstream gitea-mcp binaries for a given version and verify SHA256.
# Usage: fetch-upstream.sh <version>  e.g. fetch-upstream.sh 1.3.0
#
# Outputs are written to ./dist-cache/extract-<platform>/ with the unpacked
# binary at a known name per platform:
#   extract-win-amd64/gitea-mcp.exe
#   extract-win-arm64/gitea-mcp.exe
#   extract-darwin-amd64/gitea-mcp
#   extract-darwin-arm64/gitea-mcp
#   extract-linux-amd64/gitea-mcp
#   extract-linux-arm64/gitea-mcp
#
# Fails the script on the first SHA mismatch. Re-runs are idempotent.

set -euo pipefail

VERSION="${1:?usage: fetch-upstream.sh <version>}"
BASE="https://gitea.com/gitea/gitea-mcp/releases/download/v${VERSION}"
CACHE="$(pwd)/dist-cache"
mkdir -p "$CACHE"

SUMS_FILE="gitea-mcp_${VERSION}_checksums.txt"
echo "==> fetching checksums file"
if [ ! -f "$CACHE/$SUMS_FILE" ]; then
  curl -fsSL "$BASE/$SUMS_FILE" -o "$CACHE/$SUMS_FILE"
fi

# Map upstream archive name -> our normalized platform name -> binary inside archive
# Note: upstream uses Darwin/Linux/Windows + x86_64/arm64; we normalize.
ARCHIVES=(
  "gitea-mcp_Windows_x86_64.zip:win-amd64:gitea-mcp.exe"
  "gitea-mcp_Windows_arm64.zip:win-arm64:gitea-mcp.exe"
  "gitea-mcp_Darwin_x86_64.tar.gz:darwin-amd64:gitea-mcp"
  "gitea-mcp_Darwin_arm64.tar.gz:darwin-arm64:gitea-mcp"
  "gitea-mcp_Linux_x86_64.tar.gz:linux-amd64:gitea-mcp"
  "gitea-mcp_Linux_arm64.tar.gz:linux-arm64:gitea-mcp"
)

for entry in "${ARCHIVES[@]}"; do
  IFS=':' read -r ARCHIVE PLATFORM BINARY <<< "$entry"
  echo "==> $ARCHIVE -> $PLATFORM"

  if [ ! -f "$CACHE/$ARCHIVE" ]; then
    curl -fsSL "$BASE/$ARCHIVE" -o "$CACHE/$ARCHIVE"
  fi

  # SHA256 verify against upstream sums file
  EXPECTED="$(awk -v a="$ARCHIVE" '$2 == a { print $1 }' "$CACHE/$SUMS_FILE")"
  if [ -z "$EXPECTED" ]; then
    echo "ERROR: $ARCHIVE not in $SUMS_FILE" >&2
    exit 1
  fi
  ACTUAL="$(sha256sum "$CACHE/$ARCHIVE" | awk '{print $1}')"
  if [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "ERROR: SHA256 mismatch for $ARCHIVE" >&2
    echo "  expected: $EXPECTED" >&2
    echo "  actual:   $ACTUAL" >&2
    exit 1
  fi

  # Extract. Use python3 -m zipfile for .zip so we don't depend on `unzip` being
  # installed on minimal runner images (debian13 minimal doesn't ship it).
  EXTRACT_DIR="$CACHE/extract-$PLATFORM"
  rm -rf "$EXTRACT_DIR"
  mkdir -p "$EXTRACT_DIR"
  case "$ARCHIVE" in
    *.zip)    python3 -m zipfile -e "$CACHE/$ARCHIVE" "$EXTRACT_DIR" ;;
    *.tar.gz) tar -xzf "$CACHE/$ARCHIVE" -C "$EXTRACT_DIR" ;;
    *) echo "ERROR: unknown archive type: $ARCHIVE" >&2; exit 1 ;;
  esac

  if [ ! -f "$EXTRACT_DIR/$BINARY" ]; then
    echo "ERROR: expected binary $BINARY missing in $EXTRACT_DIR" >&2
    ls -la "$EXTRACT_DIR" >&2
    exit 1
  fi
  chmod +x "$EXTRACT_DIR/$BINARY" || true
  echo "    ok ($(stat -c%s "$EXTRACT_DIR/$BINARY" 2>/dev/null || stat -f%z "$EXTRACT_DIR/$BINARY") bytes)"
done

echo "==> all upstream binaries fetched and verified"
