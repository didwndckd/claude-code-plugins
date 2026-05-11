#!/usr/bin/env bash
# 디버그 모드: 호출 여부와 조기 종료 단계를 stderr로 echo한다.
# 정상 발화 시 stdout으로 PostToolUse 후속 지시 JSON 출력.
set -uo pipefail

log() { echo "[hook:sync-base-md] $1" >&2; }

log "호출됨"

input=$(cat)
log "input 수신 완료 (${#input} bytes)"

file_path=$(printf '%s' "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)
cwd=$(printf '%s' "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || true)
log "file_path='${file_path}' cwd='${cwd}'"

if [[ -z "${file_path}" ]]; then
  echo "[hook:sync-base-md] 조기 종료: file_path 비어있음"
  exit 0
fi

if [[ "$(basename "${file_path}")" != "CLAUDE.md" ]]; then
  echo "[hook:sync-base-md] 조기 종료: basename이 CLAUDE.md 아님 ($(basename "${file_path}"))"
  exit 0
fi

if [[ ! -f "${file_path}" ]]; then
  echo "[hook:sync-base-md] 조기 종료: 파일 없음 (${file_path})"
  exit 0
fi

if [[ -z "${cwd}" ]]; then
  echo "[hook:sync-base-md] 조기 종료: cwd 비어있음"
  exit 0
fi

base_md="${cwd}/docs/specs/base.md"
if [[ ! -f "${base_md}" ]]; then
  echo "[hook:sync-base-md] 조기 종료: base.md 없음 (${base_md})"
  exit 0
fi

log "모든 조건 통과 → additionalContext 출력"

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "방금 `CLAUDE.md`가 갱신되었습니다. `docs/specs/base.md`도 결정된 내용에 맞춰 동기화가 필요한지 확인해주세요. 규칙: (a) 원본 명시 요구는 그대로 둔다, (b) '자유' 또는 '명시되지 않음'이었거나 user 결정 필요였던 항목만 결정값으로 갱신, (c) 결정 완료된 항목은 user 결정 필요 항목 체크리스트에서 체크 처리, (d) base.md 외 파일은 건드리지 마세요. 변경 직전에 어떤 줄을 어떻게 바꾸는지 user에게 한 줄 보고 후 진행."
  }
}
JSON
