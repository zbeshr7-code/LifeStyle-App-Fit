#!/usr/bin/env bash
# Codemagic iOS build — do NOT pass ios/Runner.xcworkspace to flutter build ipa.
set -euo pipefail

EXPORT_PLIST="${EXPORT_OPTIONS_PLIST:-/Users/builder/export_options.plist}"
VERSION_LINE="$(grep '^version: ' pubspec.yaml)"
BUILD_NAME="$(echo "$VERSION_LINE" | awk '{print $2}' | cut -d '+' -f 1)"
BUILD_NUMBER="$(echo "$VERSION_LINE" | awk '{print $2}' | cut -d '+' -f 2)"

echo "== Flutter build ipa (scheme: Runner) =="
echo "Export options: $EXPORT_PLIST"

flutter build ipa --release \
  --scheme Runner \
  --export-options-plist="$EXPORT_PLIST" \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER"
