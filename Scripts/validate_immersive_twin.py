#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
s=(root/"Sources/GameUI/VisualSystem/EEImmersiveIndustrialTwin82.swift").read_text()
m=(root/"Sources/ScenarioEngine/Simulation/ImmersiveTwinState82.swift").read_text()
checks={
"MCC shell":'"MCC-2B"' in s,
"door":'"MCC-DOOR"' in s,
"dead front":'"MCC-DEADFRONT"' in s,
"withdrawable bucket":'"BKT-04"' in s and "bucketWithdrawn" in s,
"terminal strip":'"TB1:12"' in s,
"wire route":'"W-1207"' in s,
"field JB":'"JB-14"' in s,
"solenoid":'"SOL-101"' in s,
"valve":'"XV-101"' in s,
"transmitter":'"PIT-101"' in s,
"thermal mode":".thermal" in s,
"golden mode":".goldenThread" in s,
"truth model":"telemetry(identity:" in m,
}
for k,v in checks.items(): print(("PASS" if v else "FAIL"),k)
raise SystemExit(0 if all(checks.values()) else 1)
