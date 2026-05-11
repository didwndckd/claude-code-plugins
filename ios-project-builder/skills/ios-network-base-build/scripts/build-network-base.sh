#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") <path> <network> <async> [--force]

Args:
  path     destination directory (created if missing)
  network  Moya | URLSession
  async    SwiftConcurrency | Combine | RxSwift
  --force  overwrite existing files at destination
EOF
  exit 1
}

[ "$#" -ge 3 ] || usage

DEST="$1"
NETWORK="$2"
ASYNC="$3"
FORCE="${4:-}"

case "$NETWORK" in
  Moya|URLSession) ;;
  *) echo "Error: invalid network '$NETWORK' (expected: Moya | URLSession)" >&2; exit 2 ;;
esac

case "$ASYNC" in
  SwiftConcurrency|Combine|RxSwift) ;;
  *) echo "Error: invalid async '$ASYNC' (expected: SwiftConcurrency | Combine | RxSwift)" >&2; exit 2 ;;
esac

if [ -n "$FORCE" ] && [ "$FORCE" != "--force" ]; then
  echo "Error: unknown flag '$FORCE'" >&2
  usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

SRC_ENDPOINT="$TEMPLATES_DIR/$NETWORK/Endpoint.swift"
SRC_RESPONSE="$TEMPLATES_DIR/$NETWORK/APIResponse.swift"
SRC_CLIENT="$TEMPLATES_DIR/$NETWORK/$ASYNC/APIClient.swift"

for src in "$SRC_ENDPOINT" "$SRC_RESPONSE" "$SRC_CLIENT"; do
  [ -f "$src" ] || { echo "Error: template not found: $src" >&2; exit 3; }
done

mkdir -p "$DEST"

DST_ENDPOINT="$DEST/Endpoint.swift"
DST_RESPONSE="$DEST/APIResponse.swift"
DST_CLIENT="$DEST/APIClient.swift"

if [ "$FORCE" != "--force" ]; then
  for dst in "$DST_ENDPOINT" "$DST_RESPONSE" "$DST_CLIENT"; do
    if [ -e "$dst" ]; then
      echo "Error: file already exists: $dst (rerun with --force to overwrite)" >&2
      exit 4
    fi
  done
fi

cp "$SRC_ENDPOINT" "$DST_ENDPOINT"
cp "$SRC_RESPONSE" "$DST_RESPONSE"
cp "$SRC_CLIENT"   "$DST_CLIENT"

echo "Created:"
echo "  $DST_ENDPOINT"
echo "  $DST_RESPONSE"
echo "  $DST_CLIENT"
