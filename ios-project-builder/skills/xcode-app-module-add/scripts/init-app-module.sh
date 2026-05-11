#!/usr/bin/env bash
# Initialize an app module by copying entry-point sources and resources
# into <output-dir>:
#   <output-dir>/Sources/Entry/  - entry-point source files
#   <output-dir>/Info.plist      - Info.plist at module root
#   <output-dir>/Resources/      - Assets.xcassets/
#
# For SwiftUI, the App.swift template's __APP_NAME__ placeholder is
# substituted with <AppName> and saved as "<AppName>App.swift".
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") --output-dir <dir> --name <AppName>
                       --entry-point swiftui|uikit
                       --templates-dir <entry-templates-dir>
                       --assets-dir <assets-xcassets-path>

Initializes an app module:
  - Sources/Entry/ : entry-point source files (per --entry-point)
  - Info.plist     : at module root
  - Resources/     : Assets.xcassets/

For SwiftUI, the App.swift template's __APP_NAME__ placeholder is
substituted with <AppName> and saved as "<AppName>App.swift".
For UIKit, AppDelegate.swift and SceneDelegate.swift are copied as-is.

Required:
  --output-dir <dir>           Absolute path to the app module directory.
  --name <AppName>             App name. Must be a valid Swift identifier
                               (letters/digits/underscore, no leading digit).
  --entry-point swiftui|uikit  Entry-point flavor.
  --templates-dir <dir>        Absolute path to the entry-point templates
                               parent directory. Must contain:
                                 - swiftui/ or uikit/ (per entry-point)
                               (Assets.xcassets is passed separately via
                                --assets-dir; it is shared across skills.)
  --assets-dir <dir>           Absolute path to the Assets.xcassets/
                               directory itself (e.g. .../templates/Assets.xcassets).

Options:
  -h, --help                   Show this help.
EOF
}

OUTPUT_DIR=""
NAME=""
ENTRY_POINT=""
TEMPLATES_DIR=""
ASSETS_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)    OUTPUT_DIR="$2";    shift 2 ;;
    --name)          NAME="$2";          shift 2 ;;
    --entry-point)   ENTRY_POINT="$2";   shift 2 ;;
    --templates-dir) TEMPLATES_DIR="$2"; shift 2 ;;
    --assets-dir)    ASSETS_DIR="$2";    shift 2 ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -n "$OUTPUT_DIR" ]]    || { echo "--output-dir required"    >&2; usage >&2; exit 1; }
[[ -n "$NAME" ]]          || { echo "--name required"          >&2; usage >&2; exit 1; }
[[ -n "$ENTRY_POINT" ]]   || { echo "--entry-point required"   >&2; usage >&2; exit 1; }
[[ -n "$TEMPLATES_DIR" ]] || { echo "--templates-dir required" >&2; usage >&2; exit 1; }
[[ -n "$ASSETS_DIR" ]]    || { echo "--assets-dir required"    >&2; usage >&2; exit 1; }

if ! [[ "$NAME" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  echo "--name '$NAME' is not a valid Swift identifier" >&2
  exit 1
fi

case "$ENTRY_POINT" in
  swiftui|uikit) ;;
  *)
    echo "--entry-point must be 'swiftui' or 'uikit' (got: $ENTRY_POINT)" >&2
    exit 1
    ;;
esac

[[ -d "$TEMPLATES_DIR" ]] || { echo "Templates dir not found: $TEMPLATES_DIR" >&2; exit 1; }

ENTRY_TEMPLATE_DIR="${TEMPLATES_DIR}/${ENTRY_POINT}"
ASSETS_TEMPLATE_DIR="${ASSETS_DIR}"

[[ -d "$ENTRY_TEMPLATE_DIR" ]]  || { echo "Entry template dir not found: $ENTRY_TEMPLATE_DIR" >&2; exit 1; }
[[ -d "$ASSETS_TEMPLATE_DIR" ]] || { echo "Assets template not found: $ASSETS_TEMPLATE_DIR"   >&2; exit 1; }

SOURCES_DIR="${OUTPUT_DIR}/Sources/Entry"
RESOURCES_DIR="${OUTPUT_DIR}/Resources"

mkdir -p "$SOURCES_DIR" "$RESOURCES_DIR"

# Entry-point sources -> Sources/Entry/.
case "$ENTRY_POINT" in
  swiftui)
    APP_SWIFT_TEMPLATE="${ENTRY_TEMPLATE_DIR}/App.swift"
    [[ -f "$APP_SWIFT_TEMPLATE" ]] || { echo "App.swift template not found: $APP_SWIFT_TEMPLATE" >&2; exit 1; }
    APP_SWIFT_OUTPUT="${SOURCES_DIR}/${NAME}App.swift"
    sed "s/__APP_NAME__/${NAME}/g" "$APP_SWIFT_TEMPLATE" > "$APP_SWIFT_OUTPUT"
    echo "Created: $APP_SWIFT_OUTPUT"
    ;;
  uikit)
    for src in AppDelegate.swift SceneDelegate.swift; do
      template="${ENTRY_TEMPLATE_DIR}/${src}"
      [[ -f "$template" ]] || { echo "$src template not found: $template" >&2; exit 1; }
      cp "$template" "${SOURCES_DIR}/${src}"
      echo "Copied: ${SOURCES_DIR}/${src}"
    done
    ;;
esac

# Info.plist -> <output-dir>/Info.plist (module root, filename fixed).
INFO_PLIST_TEMPLATE="${ENTRY_TEMPLATE_DIR}/Info.plist"
[[ -f "$INFO_PLIST_TEMPLATE" ]] || { echo "Info.plist template not found: $INFO_PLIST_TEMPLATE" >&2; exit 1; }
cp "$INFO_PLIST_TEMPLATE" "${OUTPUT_DIR}/Info.plist"
echo "Copied: ${OUTPUT_DIR}/Info.plist"

# Assets.xcassets/ -> Resources/Assets.xcassets/ (merge-copy).
mkdir -p "${RESOURCES_DIR}/Assets.xcassets"
cp -R "${ASSETS_TEMPLATE_DIR}/." "${RESOURCES_DIR}/Assets.xcassets/"
echo "Copied: ${RESOURCES_DIR}/Assets.xcassets/"
