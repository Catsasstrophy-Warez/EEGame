#!/usr/bin/env python3
from pathlib import Path
R=Path(__file__).resolve().parents[1];a=(R/'Sources/GameUI/Rev92ProductionArtSystem.swift').read_text();b=(R/'Sources/GameUI/Rev72IntegratedLabView.swift').read_text();c=(R/'Sources/GameUI/Rev91ImmersiveProductionVisuals.swift').read_text();t=['EERev92ProductionArtDeck', 'EERev92EquipmentFaceplates', 'EERev92WireLabels', 'EERev92FacilityRoom', 'EERev92AudioVisualState', 'EEFacilityMeasurementFrame88', 'facility88.scope.samples', 'L1.V', 'rev92.trueTransientScope']
ok=0
for x in t:
 g=x in (a+b+c);print(('PASS' if g else 'FAIL'),x);ok+=g
g='EERev92ProductionArtDeck' in b;print(('PASS' if g else 'FAIL'),'root reachability');ok+=g
print(f'{ok}/{len(t)+1} PASS');raise SystemExit(0 if ok==len(t)+1 else 1)
