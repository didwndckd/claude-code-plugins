#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <root>" >&2
  exit 1
}

[[ $# -eq 1 ]] || usage

ROOT="$1"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
TEMPLATE="$SKILL_DIR/templates/Base/ViewModel.swift"

[[ -f "$TEMPLATE" ]] || { echo "Missing template: $TEMPLATE" >&2; exit 3; }

mkdir -p "$ROOT/Base"

DEST="$ROOT/Base/ViewModel.swift"
if [[ -e "$DEST" ]]; then
  echo "Skipped (exists): $DEST"
else
  cp "$TEMPLATE" "$DEST"
  echo "Created: $DEST"
fi
