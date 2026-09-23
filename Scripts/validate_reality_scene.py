#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
scene=(r/"Sources/RealityScene/RealityScene.swift").read_text()
gameui=(r/"Sources/GameUI/Rev72IntegratedLabView.swift").read_text()
checks={
"platform guard":"canImport(RealityKit)" in scene and "canImport(SwiftUI)" in scene,
"circuit row nodes":all(n in scene for n in ['"CircuitSource"','"CircuitBreaker"','"CircuitLoad"','"WireSourceToBreaker"','"WireBreakerToLoad"']),
"buildCircuitRow":"func buildCircuitRow()" in scene,
"applyElectricalState":"func applyElectricalState(to root: Entity" in scene,
"tappable nodes":"generateCollisionShapes" in scene and "InputTargetComponent()" in scene,
"tap-to-inspect gesture":"SpatialTapGesture()" in scene and ".targetedToAnyEntity()" in scene,
"orbit camera controls":".realityViewCameraControls(.orbit)" in scene,
# Regression guard: RealityView's update closure takes exactly one
# (inout RealityViewContent) parameter. A second unused parameter
# ("} update: { content, _ in") broke the first real Xcode build.
"update closure arity":"} update: { content in" in scene and "} update: { content, _ in" not in scene,
"live-driven from app":"RealitySceneView(energized:" in gameui and "simulation.snapshot" in gameui,
}
for k,v in checks.items(): print(("PASS" if v else "FAIL"),k)
raise SystemExit(0 if all(checks.values()) else 1)
