#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
case "${1:-}" in
  ""|--check) ;;
  *) echo "Usage: sh Scripts/generate-resources.sh [--check]" >&2; exit 1 ;;
esac
if ! command -v swiftgen >/dev/null 2>&1; then
  echo "SwiftGen 6.6.3 is required to regenerate resources." >&2
  exit 1
fi
case "$(swiftgen --version)" in
  "SwiftGen v6.6.3 "*) ;;
  *) echo "Use SwiftGen 6.6.3 for reproducible generation." >&2; exit 1 ;;
esac
FINAI_LOCALIZATION_INPUT=$(mktemp -d)
export FINAI_LOCALIZATION_INPUT
trap 'rm -rf "$FINAI_LOCALIZATION_INPUT"' EXIT HUP INT TERM
xcrun xcstringstool compile FinAI/Resources/Localization/Localizable.xcstrings \
  --output-directory "$FINAI_LOCALIZATION_INPUT" --language en --serialization-format text
FINAI_GENERATED_OUTPUT=FinAI/Resources/Generated
if [ "${1:-}" = --check ]; then
  FINAI_GENERATED_OUTPUT="$FINAI_LOCALIZATION_INPUT/generated"
fi
export FINAI_GENERATED_OUTPUT
mkdir -p "$FINAI_GENERATED_OUTPUT"
swiftgen config run --config swiftgen.yml
if [ "${1:-}" = --check ]; then
  diff -u FinAI/Resources/Generated/Assets.swift "$FINAI_GENERATED_OUTPUT/Assets.swift"
  diff -u FinAI/Resources/Generated/Localization.swift "$FINAI_GENERATED_OUTPUT/Localization.swift"
fi
