#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
rk=(root/"Sources/GameUI/VisualSystem/EERealitySpatialTwin81.swift").read_text()
manifest=(root/"Sources/ScenarioEngine/Simulation/SpatialTwinManifest81.swift").read_text()
checks={
"RealityKit guard":"canImport(RealityKit)" in rk,
"identity component":"EERealityIdentity81" in rk,
"telemetry component":"EERealityTelemetry81" in rk,
"spatial tap":"SpatialTapGesture" in rk,
"terminal identity":'"TB1:12"' in rk and '"W-1207"' in rk,
"manifest":"EESpatialTwinManifest81" in manifest,
"manifest validation":"validate()" in manifest,
}
failed=[k for k,v in checks.items() if not v]
for k,v in checks.items(): print(("PASS" if v else "FAIL"),k)
raise SystemExit(1 if failed else 0)
