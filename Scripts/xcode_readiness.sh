#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
echo "== Swift package build =="; swift build --target ScenarioEngine; swift build --target GameUI
if command -v xcodegen >/dev/null 2>&1; then echo "== Generating Xcode project =="; xcodegen generate; else echo "xcodegen not installed; project.yml is ready."; fi
if command -v xcodebuild >/dev/null 2>&1 && [ -d ElectricEngineerGame.xcodeproj ]; then echo "== Xcode project schemes =="; xcodebuild -project ElectricEngineerGame.xcodeproj -list; else echo "xcodebuild unavailable in this environment."; fi
