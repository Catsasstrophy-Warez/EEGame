#!/usr/bin/env python3
from pathlib import Path
R=Path(__file__).resolve().parents[1]
checks={
"spatial equipment bay":("Sources/GameUI/Rev89SpatialEquipmentVisuals.swift","EERev89SpatialEquipmentBay"),
"bucket interior":("Sources/GameUI/Rev89SpatialEquipmentVisuals.swift","EERev89BucketInterior"),
"PLC rack":("Sources/GameUI/Rev89SpatialEquipmentVisuals.swift","EERev89PLCRack"),
"terminal strip":("Sources/GameUI/Rev89SpatialEquipmentVisuals.swift","EERev89TerminalStrip"),
"motor cutaway":("Sources/GameUI/Rev89SpatialEquipmentVisuals.swift","EERev89MotorCutaway"),
"vision modes":("Sources/GameUI/Rev89SpatialEquipmentVisuals.swift","EERev88VisionMode"),
"shared physical frame":("Sources/GameUI/Rev89SpatialEquipmentVisuals.swift","EEFacilityMeasurementFrame88"),
"root reachability":("Sources/GameUI/Rev72IntegratedLabView.swift","EERev89SpatialEquipmentBay"),
"accessibility equipment":("Sources/GameUI/Rev89SpatialEquipmentVisuals.swift","rev89.spatialEquipmentBay"),
"accessibility plc":("Sources/GameUI/Rev89SpatialEquipmentVisuals.swift","rev89.plcRack"),
}
ok=0
for name,(f,tok) in checks.items():
    good=tok in (R/f).read_text()
    print(("PASS" if good else "FAIL"),name)
    ok+=good
print(f"{ok}/{len(checks)} PASS")
raise SystemExit(0 if ok==len(checks) else 1)
