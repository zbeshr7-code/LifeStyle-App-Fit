#!/usr/bin/env bash
# Strips ios/Runner.xcworkspace from Codemagic Workflow Editor's broken
# "flutter build ipa ... ios/Runner.xcworkspace" command.
set -euo pipefail

REAL_FLUTTER="${FLUTTER_ROOT:-/Users/builder/programs/flutter}/bin/flutter"
if [ ! -x "$REAL_FLUTTER" ]; then
  REAL_FLUTTER="$(command -v flutter)"
fi

WRAPPER_DIR="${CM_BUILD_DIR:-$(pwd)}/.codemagic/bin"
mkdir -p "$WRAPPER_DIR"

cat > "$WRAPPER_DIR/flutter" << SCRIPT
#!/usr/bin/env bash
REAL="$REAL_FLUTTER"
if [[ "\$1" == "build" && "\$2" == "ipa" ]]; then
  args=(build ipa)
  shift 2
  while [[ \$# -gt 0 ]]; do
    case "\$1" in
      ios/Runner.xcworkspace|ios/Runner.xcodeproj|Runner.xcworkspace|Runner.xcodeproj)
        shift
        ;;
      *)
        args+=("\$1")
        shift
        ;;
    esac
  done
  has_scheme=false
  for arg in "\${args[@]}"; do
    if [[ "\$arg" == "--scheme" || "\$arg" == --scheme=* ]]; then
      has_scheme=true
      break
    fi
  done
  if [[ "\$has_scheme" == "false" ]]; then
    args+=(--scheme Runner)
  fi
  exec "\$REAL" "\${args[@]}"
fi
exec "\$REAL" "\$@"
SCRIPT

chmod +x "$WRAPPER_DIR/flutter"

if [ -n "${CM_ENV:-}" ]; then
  echo "export PATH=\"$WRAPPER_DIR:\$PATH\"" >> "$CM_ENV"
fi
export PATH="$WRAPPER_DIR:$PATH"

echo "== Codemagic flutter wrapper installed =="
echo "Wrapper: $WRAPPER_DIR/flutter"
echo "Real:    $REAL_FLUTTER"
if [ -x "$REAL_FLUTTER" ]; then
  "$WRAPPER_DIR/flutter" --version
else
  echo "Flutter not on disk yet; wrapper activates when build runs."
fi
