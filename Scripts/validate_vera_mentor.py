#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
engine=(r/"Sources/ScenarioEngine/VeraMentor.swift").read_text()
capabilities=(r/"Sources/ScenarioEngine/VeraMentorCapabilities.swift").read_text()
ui=(r/"Sources/GameUI/VeraMentorView.swift").read_text()
coalui=(r/"Sources/GameUI/CoalMiningOperationsView.swift").read_text()
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
"panel reads real gated reply":"struct EEVeraMentorPanel" in ui and "EEVeraMentorRuntime.replyWithAudit(for: context" in ui,
"safety lamp reflects stop/proceed":"reply.safety.status == .stopAndEscalate" in ui,
"wired into Engineering workspace":'"engineering.veraMentor"' in gameui and "EEVeraMentorPanel()" in gameui,
"tests cover the stop-before-identity ordering":"protectiveFunctionAffectedStopsBeforeIdentity" in tests,
"tests cover provider cannot upgrade a stop verdict":"offlineProviderNeverUpgradesAStopVerdict" in tests,
# Capabilities: persisted policy/audit, live-state context builders.
"audit store persists via UserDefaults":"enum EEVeraMentorStore" in capabilities and "UserDefaults" in capabilities,
"audit log is bounded":"maxAuditEntries" in capabilities and "suffix(maxAuditEntries)" in capabilities,
"replyWithAudit never bypasses the gate":"static func replyWithAudit" in capabilities and "await self.reply(for: context)" in capabilities,
"coal mining context reads real sensor state":"static func coalMining(" in capabilities and "state.atmosphere[mine]?.sensors" in capabilities,
"facility power context reads real trip cause":"static func facilityPower(" in capabilities and "state.protection.tripCause != .none" in capabilities,
"vera panel exposes provider policy and audit log":"vera.providerPolicy" in ui and "vera.auditLog" in ui,
"coal mining view can auto-consult vera from live state":"struct EECoalMiningVeraConsultButton" in coalui and "EEVeraMentorContextFactory.coalMining(" in coalui,
"coal mining vera consult wired into Field workspace":"EECoalMiningVeraConsultButton(mine:selectedMine,state:coalMining)" in gameui,
"tests cover audit persistence and live-state escalation":"replyWithAuditPersistsAnEventWhenRetentionIsOn" in tests and "coalMiningContextEscalatesOnRealMethaneAlarm" in tests and "facilityPowerContextEscalatesOnRealTripCause" in tests,
}
for k,v in checks.items(): print(("PASS" if v else "FAIL"),k)
raise SystemExit(0 if all(checks.values()) else 1)
