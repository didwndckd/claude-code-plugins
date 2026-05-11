#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <path> <async-key> <io-key> [--base]" >&2
  echo "  path: 프로젝트 루트 기준 상대 경로 (예: '.' 또는 'Sources')" >&2
  echo "  async-key: swift-concurrency | combine | rx" >&2
  echo "  io-key: combine-uikit | rx-uikit | swiftui" >&2
  echo "  --base: UIKit + Base/ViewModel.swift 베이스 파일 생성한 경우" >&2
  exit 1
}

[[ $# -ge 3 ]] || usage

PATH_ROOT="$1"
ASYNC_KEY="$2"
IO_KEY="$3"
shift 3

WITH_BASE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) WITH_BASE=1; shift ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

case "$ASYNC_KEY" in
  swift-concurrency|combine|rx) ;;
  *) echo "Invalid async-key: $ASYNC_KEY" >&2; exit 2 ;;
esac

case "$IO_KEY" in
  combine-uikit|rx-uikit|swiftui) ;;
  *) echo "Invalid io-key: $IO_KEY" >&2; exit 2 ;;
esac

PATH_ROOT="${PATH_ROOT#./}"
PATH_ROOT="${PATH_ROOT%/}"

if [[ -z "$PATH_ROOT" || "$PATH_ROOT" == "." ]]; then
  PATHS_GLOB="**"
else
  LAST_COMPONENT="${PATH_ROOT##*/}"
  PATHS_GLOB="**/${LAST_COMPONENT}/**"
fi

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
BASE_FILE="$SKILL_DIR/templates/rule-base.md"
ASYNC_FILE="$SKILL_DIR/templates/async/${ASYNC_KEY}.md"
IO_FILE="$SKILL_DIR/templates/io/${IO_KEY}.md"

[[ -f "$BASE_FILE" ]] || { echo "Missing template: $BASE_FILE" >&2; exit 3; }
[[ -f "$ASYNC_FILE" ]] || { echo "Missing template: $ASYNC_FILE" >&2; exit 3; }
[[ -f "$IO_FILE" ]] || { echo "Missing template: $IO_FILE" >&2; exit 3; }

cat <<EOF
---
paths:
  - "${PATHS_GLOB}"
---

## 폴더 구조

\`\`\`
EOF

if [[ $WITH_BASE -eq 1 ]]; then
  cat <<'EOF'
Base/
└── ViewModel.swift
EOF
fi

cat <<'EOF'
<화면명>/
├── ViewModel/
└── View/
```

- `<화면명>/ViewModel/`, `<화면명>/View/`는 화면 작성 시점에 생성한다 (가이드 트리).

EOF

cat "$BASE_FILE"
cat "$ASYNC_FILE"
echo
cat "$IO_FILE"
