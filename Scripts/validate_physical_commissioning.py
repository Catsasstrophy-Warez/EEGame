#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
s=(r/"Sources/ScenarioEngine/Simulation/PhysicalCommissioning83.swift").read_text()
v=(r/"Sources/GameUI/VisualSystem/EEPhysicalCommissioningTwin83.swift").read_text()
checks={"protection state":"EECommissioningState83" in s,"disconnect":'"DS-04"' in v, "fuses":'"F\\(i+1)-04"' in v and "for i in 0..<3" in v,
"overload":'"OL-04"' in v,"DMM":'"DMM-1"' in v,"probes":'"PROBE-RED"' in v and '"PROBE-COM"' in v,
"cutaway":'"SOL-PLUNGER"' in v and '"VALVE-STEM"' in v,"wire route":'"W-1207"' in v,"actuation solver":"EEActuation83" in s}
for k,x in checks.items(): print(("PASS" if x else "FAIL"),k)
raise SystemExit(0 if all(checks.values()) else 1)
