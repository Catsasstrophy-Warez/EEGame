#!/usr/bin/env python3
from pathlib import Path
R=Path(__file__).resolve().parents[1]
a=(R/"Sources/GameUI/Rev90PhysicalInteractionVisuals.swift").read_text(); b=(R/"Sources/GameUI/Rev72IntegratedLabView.swift").read_text()
checks=['EERev90PhysicalInteractionLab', 'EERev90AnimatedBucket', 'EERev90ConductorHarness', 'EERev90ProbeBoard', 'EERev90ScopeTrace', 'EERev90ProtectionCutaway', 'EERev90WearSurface', 'EEFacilityMeasurementFrame88', 'rev90.probeBoard']
ok=0
for x in checks:
 g=x in a; print(("PASS" if g else "FAIL"),x);ok+=g
g="EERev90PhysicalInteractionLab" in b;print(("PASS" if g else "FAIL"),"root reachability");ok+=g
print(f"{ok}/{len(checks)+1} PASS");raise SystemExit(0 if ok==len(checks)+1 else 1)
