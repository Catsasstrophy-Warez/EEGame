#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
s=(r/"Sources/ScenarioEngine/Simulation/UnifiedElectricalTruth84.swift").read_text()
u=(r/"Sources/GameUI/Rev72IntegratedLabView.swift").read_text()
checks={"CircuitMNA import":"import CircuitMNA" in s,"reference solver":"ReferenceDCSolver" in s,
"disconnect topology":"rDisconnect" in s,"fuse topology":"rFuse" in s,"PLC topology":"rPLC" in s,
"terminal fault topology":"rTerminal" in s,"short branch":"shortToGround" in s and "resistors.append" in s,
"solved DMM":"static func measure" in s,"production reachability":'"field.unifiedTruth"' in u}
for k,v in checks.items():print(("PASS" if v else "FAIL"),k)
raise SystemExit(0 if all(checks.values()) else 1)
