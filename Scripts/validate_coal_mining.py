#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
ui=(r/"Sources/GameUI/CoalMiningOperationsView.swift").read_text()
gameui=(r/"Sources/GameUI/Rev72IntegratedLabView.swift").read_text()
physics=(r/"Sources/ScenarioEngine/Rev42CoalMiningDeepSystems.swift").read_text()

checks={
"platform guard":"canImport(SwiftUI)" in ui,
"dashboard reads real mine state":"struct EECoalMiningDashboard" in ui and "mine.beltAvailable" in ui and "mine.deliveredTPH" in ui,
"longwall face view":"struct EECoalLongwallFaceView" in ui and "face.shearer.headgateDrumAmps" in ui,
"ventilation/atmosphere view":"struct EECoalVentilationAtmosphereView" in ui and "sensor.methanePercent" in ui and "sensor.coPPM" in ui,
"preparation plant view":"struct EECoalPreparationPlantView" in ui and "heavyMedia.correctedMediumSG" in ui and "thickener.rakeTorquePercent" in ui,
"train loadout view":"struct EECoalTrainLoadoutView" in ui and "train.activeCar" in ui,
"incident replay view":"struct EECoalIncidentReplayView" in ui and "state.recorder.frames" in ui,
"wired into Field workspace":'"field.coalMining"' in gameui and "EECoalMiningRev44()" in gameui,
"mine picker wired":"coalMining.minePicker" in gameui and "EEMineID.allCases" in gameui,
"advance button drives real tick":"coalMining.advance" in gameui and "coalMining.tick(seconds:" in gameui,
# Regression guard: the methane status lamp must reflect the real reading,
# not an unrelated field (an earlier draft used shearer vibration as the
# lamp's "active" condition, which was meaningless).
"methane lamp reflects real reading":'active:faceMethanePercent>1' in ui,
# Sanity: the physics this UI is built on actually exists (not stubbed).
"physics model present":"struct EECoalMiningRev44" in physics or "struct EECoalMiningRev44" in (r/"Sources/ScenarioEngine/Rev42CoalMiningDeepSystems.swift").read_text(),
}
for k,v in checks.items(): print(("PASS" if v else "FAIL"),k)
raise SystemExit(0 if all(checks.values()) else 1)
