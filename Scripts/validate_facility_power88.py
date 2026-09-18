#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
files=["Sources/ScenarioEngine/Simulation/FacilityPowerPhysics88.swift","Sources/GameUI/Rev88VisualFidelity.swift","Tests/ElectricalCoreTests/FacilityPowerPhysics88Tests.swift"]
ok=True
for f in files:
 p=root/f; good=p.exists() and p.stat().st_size>100; print(("PASS" if good else "FAIL"),f); ok &= good
physics=(root/files[0]).read_text(); ui=(root/"Sources/GameUI/Rev72IntegratedLabView.swift").read_text()
for t in ["EESequence88","singleLineGround","doubleLineGround","negativeSequenceA","EEConductorThermal88","EEFacilityMeasurementFrame88","controlVoltageV"]:
 good=t in physics; print(("PASS" if good else "FAIL"),t); ok &= good
for t in ["field.rev88FacilityPower","EERev88FacilityDashboard","EERev88MCCLineup","EERev88ThermalStrip","EERev88StarterBucket","EERev88InstrumentCluster","EERev88CausalRibbon"]:
 good=t in ui; print(("PASS" if good else "FAIL"),"reachable "+t); ok &= good
raise SystemExit(0 if ok else 1)
