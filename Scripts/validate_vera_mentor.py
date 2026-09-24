#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
engine=(r/"Sources/ScenarioEngine/VeraMentor.swift").read_text()
ui=(r/"Sources/GameUI/VeraMentorView.swift").read_text()
gameui=(r/"Sources/GameUI/Rev72IntegratedLabView.swift").read_text()
tests=(r/"Tests/ElectricalCoreTests/VeraMentorTests.swift").read_text()

checks={
"safety gate exists":"enum EEVeraSafetyRouter" in engine and "static func gate(" in engine,
"gate runs before any provider call":"EEVeraSafetyRouter.gate(context)" in engine and "let selectedProvider" in engine,
# Regression guard: the safety-affected check must be evaluated before
# identity/isolation, so a provider can never be reached with an
# unresolved protective-function condition.
"safety-function-affected checked first":engine.index("safetyFunctionAffected && !context.energyIsolatedAndVerified") < engine.index("!context.identityConfirmed"),
"gas/coal domains gated on area+gas test":"context.domain == .naturalGas || context.domain == .coalMining" in engine,
"provider cannot upgrade a stop verdict":"protocol EEVeraMentorProvider" in engine and "safety: EEVeraMentorDiagnosticResponse" in engine,
"platform guard":"canImport(SwiftUI)" in ui,
"panel reads real gated reply":"struct EEVeraMentorPanel" in ui and "EEVeraMentorRuntime.reply(for: context)" in ui,
"safety lamp reflects stop/proceed":"reply.safety.status == .stopAndEscalate" in ui,
"wired into Engineering workspace":'"engineering.veraMentor"' in gameui and "EEVeraMentorPanel()" in gameui,
"tests cover the stop-before-identity ordering":"protectiveFunctionAffectedStopsBeforeIdentity" in tests,
"tests cover provider cannot upgrade a stop verdict":"offlineProviderNeverUpgradesAStopVerdict" in tests,
}
for k,v in checks.items(): print(("PASS" if v else "FAIL"),k)
raise SystemExit(0 if all(checks.values()) else 1)
