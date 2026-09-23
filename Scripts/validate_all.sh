#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAST=0
if [[ "${1:-}" == "--fast" ]]; then FAST=1; fi

run_py() {
  local script="$1"
  if [[ -f "$script" ]]; then
    echo "== $script =="
    python3 "$script"
  fi
}

run_py Scripts/validate_causal_depth86.py
run_py Scripts/validate_continuous_causal_machine85.py
run_py Scripts/validate_unified_truth.py
run_py Scripts/validate_reality_scene.py
run_py Scripts/validate_metal_telemetry.py
run_py Scripts/validate_xcode_project.py

echo "== Swift build: ScenarioEngine =="
swift build --target ScenarioEngine

echo "== Swift build: GameUI =="
swift build --target GameUI

if [[ "$FAST" -eq 0 ]]; then
  echo "== Swift tests =="
  swift test
else
  echo "== Swift tests skipped (--fast) =="
fi

echo "VALIDATION COMPLETE"
