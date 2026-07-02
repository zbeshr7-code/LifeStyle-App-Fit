#!/usr/bin/env bash
# Codemagic Workflow Editor → Pre-build script (recommended):
#   bash ./codemagic_install_flutter_wrapper.sh
# Or full bootstrap (Post-clone):
#   bash ./codemagic_post_clone.sh
set -euo pipefail

echo "== Codemagic post-clone: prepare iOS =="

if [ ! -f .env ]; then
  cp .env.example .env
fi

flutter pub get

mkdir -p ios/Runner.xcworkspace/xcshareddata/xcschemes
mkdir -p ios/Runner.xcodeproj/xcshareddata/xcschemes

if [ -f ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme ]; then
  cp -f ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme \
        ios/Runner.xcworkspace/xcshareddata/xcschemes/Runner.xcscheme
fi

echo "Workspace schemes:"
ls -la ios/Runner.xcworkspace/xcshareddata/xcschemes/ || true
echo "Project schemes:"
ls -la ios/Runner.xcodeproj/xcshareddata/xcschemes/ || true

xcodebuild -list -workspace ios/Runner.xcworkspace
