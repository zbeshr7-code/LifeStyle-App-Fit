#!/usr/bin/env bash
# Ensures the committed .codemagic/bin/flutter wrapper is on PATH for this build.
set -euo pipefail

WRAPPER_DIR="${CM_BUILD_DIR:-$(pwd)}/.codemagic/bin"
chmod +x "$WRAPPER_DIR/flutter"

if [ -n "${CM_ENV:-}" ]; then
  echo "export PATH=\"$WRAPPER_DIR:\$PATH\"" >> "$CM_ENV"
fi
export PATH="$WRAPPER_DIR:$PATH"

echo "== Codemagic flutter wrapper on PATH =="
echo "Wrapper: $WRAPPER_DIR/flutter"
which flutter
flutter --version
