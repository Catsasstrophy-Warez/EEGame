#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
scene=(r/"Sources/RealityScene/RealityScene.swift").read_text()
gameui=(r/"Sources/GameUI/Rev72IntegratedLabView.swift").read_text()
checks={
"platform guard":"canImport(RealityKit)" in scene and "canImport(SwiftUI)" in scene,
"circuit topology nodes":all(n in scene for n in ['"CircuitSource"','"CircuitBreaker"','"CircuitJunction"','"CircuitLoadA"','"CircuitLoadB"']),
"circuit topology wires":all(n in scene for n in ['"WireSourceToBreaker"','"WireBreakerToJunction"','"WireJunctionToLoadA"','"WireJunctionToLoadB"']),
"distinguishable node shapes":"generateCylinder" in scene and "generateSphere" in scene and "generateBox" in scene,
"buildCircuitRow":"func buildCircuitRow()" in scene,
"applyElectricalState":"func applyElectricalState(to root: Entity" in scene,
"fault visual enum":"enum CircuitFaultVisual" in scene and all(c in scene for c in ["openCircuit","groundFault","shortCircuit","warning"]),
"tappable nodes":"generateCollisionShapes" in scene and "InputTargetComponent()" in scene,
"tap-to-inspect gesture":"SpatialTapGesture()" in scene and ".targetedToAnyEntity()" in scene,
"haptic feedback on tap":"UIImpactFeedbackGenerator" in scene,
# Persisted (not built-in-convenience) camera: RealitySceneCameraState is
# owned by the caller via @Binding, so it survives the RealityKit view's
# own teardown when a SwiftUI .sheet dismisses and re-presents.
"persisted camera state":"struct RealitySceneCameraState" in scene and "@Binding public var camera: RealitySceneCameraState" in scene,
"camera drag/zoom gestures":"DragGesture" in scene and "MagnificationGesture" in scene,
# Regression guard: RealityView's update closure takes exactly one
# (inout RealityViewContent) parameter. A second unused parameter
# ("} update: { content, _ in") broke the first real Xcode build.
"update closure arity":"} update: { content in" in scene and "} update: { content, _ in" not in scene,
"live-driven from app":"RealitySceneView(energized:" in gameui and "simulation.snapshot" in gameui and "camera:$realityCamera" in gameui,
"fault mapped from app state":"circuitFaultVisual" in gameui and "facilityFault88" in gameui,
}
for k,v in checks.items(): print(("PASS" if v else "FAIL"),k)
raise SystemExit(0 if all(checks.values()) else 1)
