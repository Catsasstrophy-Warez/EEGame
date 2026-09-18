#!/usr/bin/env python3
from pathlib import Path
R=Path(__file__).resolve().parents[1];a=(R/'Sources/GameUI/Rev91ImmersiveProductionVisuals.swift').read_text();b=(R/'Sources/GameUI/Rev72IntegratedLabView.swift').read_text()
t=['EERev91ImmersiveProductionLab', 'EERev91TerminalWireMap', 'EERev91LeadPlacement', 'EERev91BufferedScope', 'EERev91ProcessMachine', 'EERev91Environment', 'EEFacilityMeasurementFrame88', 'rev91.leadPlacement', 'rev91.bufferedScope']
ok=0
for x in t:
 g=x in a;print(('PASS' if g else 'FAIL'),x);ok+=g
g='EERev91ImmersiveProductionLab' in b;print(('PASS' if g else 'FAIL'),'root reachability');ok+=g
print(f'{ok}/{len(t)+1} PASS');raise SystemExit(0 if ok==len(t)+1 else 1)
