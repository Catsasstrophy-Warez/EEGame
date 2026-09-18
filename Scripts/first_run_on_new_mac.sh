#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "== Electric Engineer Rev84 cross-computer preflight =="
python3 Scripts/validate_xcode_project.py
bash -n Scripts/xcode_readiness.sh
if command -v xcodegen >/dev/null 2>&1; then
  echo "Regenerating Xcode project from project.yml..."
  xcodegen generate
else
  echo "xcodegen not found; using bundled Xcode project. Install XcodeGen before regeneration."
fi
if command -v xcodebuild >/dev/null 2>&1; then
  echo "Xcode detected:"
  xcodebuild -version
  echo "Available schemes:"
  xcodebuild -list -project ElectricEngineerGame.xcodeproj 2>/dev/null || true
else
  echo "xcodebuild not available in PATH."
fi
echo "Preflight complete. Open the .xcodeproj in Xcode and configure your local Development Team."
