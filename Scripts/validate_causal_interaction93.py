#!/usr/bin/env python3
from pathlib import Path
R=Path(__file__).resolve().parents[1];x='\n'.join((R/p).read_text() for p in ['Sources/ScenarioEngine/Simulation/InstrumentInteraction93.swift','Sources/GameUI/Rev93CausalInteraction.swift','Sources/GameUI/Rev72IntegratedLabView.swift']);t=['EEInstrumentLoadedNetwork93', 'ReferenceDCSolver', 'EEMeterMode93', 'EEFacilityHarness93', 'EERev93LoadedMeter', 'EERev93CanonicalHarness', 'EERev93MechanicalContactor', 'EERev93CausalInteractionLab', 'rev93.loadedMeter']
ok=0
for a in t:
 g=a in x;print(('PASS' if g else 'FAIL'),a);ok+=g
print(f'{ok}/{len(t)} PASS');raise SystemExit(0 if ok==len(t) else 1)
