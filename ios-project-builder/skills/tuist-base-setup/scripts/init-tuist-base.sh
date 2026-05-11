#!/usr/bin/env bash
# Initialize a Tuist project base inside <project-root>:
#   - Merge-copy <tuist-template>/* (Package.swift +
#     ProjectDescriptionHelpers/, ...) into <project-root>/Tuist/.
#   - Merge-copy <xcconfigs-template>/* into <project-root>/xcconfigs/.
#   - Copy <tuist-config-file> to <project-root>/Tuist.swift (overwrite).
#
# This script is layout-agnostic — it does not create Projects/ or any
# module directories. Single-/multi-module differences are handled by
# the caller skill (e.g. .gitignore policy, module placement).
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") --project-root <dir>
                       --tuist-template <dir>
                       --xcconfigs-template <dir>
                       --tuist-config-file <file>

Merge-copies the Tuist base into <project-root>:
  - <tuist-template>/* into <project-root>/Tuist/ (existing dirs
    merged, same-named files overwritten).
  - <xcconfigs-template>/* into <project-root>/xcconfigs/.
  - <tuist-config-file> to <project-root>/Tuist.swift (overwrite).

Required:
  --project-root <dir>          Absolute path to the project root.
  --tuist-template <dir>        Absolute path to the Tuist template
                                directory (must contain Package.swift and
                                ProjectDescriptionHelpers/).
  --xcconfigs-template <dir>    Absolute path to the xcconfigs template
                                directory.
  --tuist-config-file <file>    Absolute path to the Tuist.swift template
                                file (lands as <project-root>/Tuist.swift).

Options:
  -h, --help                    Show this help.
EOF
}

PROJECT_ROOT=""
TUIST_TEMPLATE=""
XCCONFIGS_TEMPLATE=""
TUIST_CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)       PROJECT_ROOT="$2";       shift 2 ;;
    --tuist-template)     TUIST_TEMPLATE="$2";     shift 2 ;;
    --xcconfigs-template) XCCONFIGS_TEMPLATE="$2"; shift 2 ;;
    --tuist-config-file)  TUIST_CONFIG_FILE="$2";  shift 2 ;;
    -h|--help)            usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -n "$PROJECT_ROOT" ]]       || { echo "--project-root required"       >&2; usage >&2; exit 1; }
[[ -n "$TUIST_TEMPLATE" ]]     || { echo "--tuist-template required"     >&2; usage >&2; exit 1; }
[[ -n "$XCCONFIGS_TEMPLATE" ]] || { echo "--xcconfigs-template required" >&2; usage >&2; exit 1; }
[[ -n "$TUIST_CONFIG_FILE" ]]  || { echo "--tuist-config-file required"  >&2; usage >&2; exit 1; }

[[ -d "$PROJECT_ROOT" ]]       || { echo "Project root not a directory: $PROJECT_ROOT" >&2; exit 1; }
[[ -d "$TUIST_TEMPLATE" ]]     || { echo "Tuist template not found: $TUIST_TEMPLATE"   >&2; exit 1; }
[[ -d "$XCCONFIGS_TEMPLATE" ]] || { echo "xcconfigs template not found: $XCCONFIGS_TEMPLATE" >&2; exit 1; }
[[ -f "$TUIST_CONFIG_FILE" ]]  || { echo "Tuist config file not found: $TUIST_CONFIG_FILE"   >&2; exit 1; }

# 1) Merge-copy Tuist template into ${PROJECT_ROOT}/Tuist/.
# cp -R "<src>/." "<dst>/" copies src's contents into dst, creating dst
# if needed and overwriting same-named files inside.
mkdir -p "${PROJECT_ROOT}/Tuist"
cp -R "${TUIST_TEMPLATE}/." "${PROJECT_ROOT}/Tuist/"
echo "Copied Tuist template -> ${PROJECT_ROOT}/Tuist/"

# 2) Merge-copy xcconfigs into ${PROJECT_ROOT}/xcconfigs/.
mkdir -p "${PROJECT_ROOT}/xcconfigs"
cp -R "${XCCONFIGS_TEMPLATE}/." "${PROJECT_ROOT}/xcconfigs/"
echo "Copied xcconfigs -> ${PROJECT_ROOT}/xcconfigs/"

# 3) Tuist.swift at the project root.
cp "${TUIST_CONFIG_FILE}" "${PROJECT_ROOT}/Tuist.swift"
echo "Copied Tuist.swift -> ${PROJECT_ROOT}/Tuist.swift"
