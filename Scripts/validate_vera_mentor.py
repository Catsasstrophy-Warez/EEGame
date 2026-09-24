#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
engine=(r/"Sources/ScenarioEngine/VeraMentor.swift").read_text()
capabilities=(r/"Sources/ScenarioEngine/VeraMentorCapabilities.swift").read_text()
refindex=(r/"Sources/ScenarioEngine/VeraMentorReferenceIndex.swift").read_text()
codeknowledge=(r/"Sources/ScenarioEngine/VeraCodeKnowledge.swift").read_text()
safetyknowledge=(r/"Sources/ScenarioEngine/VeraElectricalSafetyKnowledge.swift").read_text()
navigator=(r/"Sources/ScenarioEngine/VeraStandardsNavigator.swift").read_text()
spec=(r/"Sources/ScenarioEngine/VeraMentorSpecification.swift").read_text()
equipment=(r/"Sources/ScenarioEngine/VeraEquipmentExpertise.swift").read_text()
techniques=(r/"Sources/ScenarioEngine/VeraFieldTechniquesKnowledge.swift").read_text()
foundationprovider=(r/"Sources/ScenarioEngine/VeraAppleFoundationModelProvider.swift").read_text()
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
# Reference index (NEC/NFPA 70E/field quick-reference): structured
# citations only, never verbatim code/book text, and every entry must
# tell the player to verify against their AHJ-adopted edition.
"reference index covers NEC, NFPA 70E, and field quick-reference":all(s in refindex for s in ['case nec = "NEC (NFPA 70)"','case nfpa70E = "NFPA 70E"','case fieldReferenceGuide = "Field quick-reference"']),
"reference index disclaims verbatim quoting and demands edition verification":"AHJ-adopted edition" in refindex and "not a copy of any of those publications" in refindex,
"reference retrieval is domain-scoped":"static func retrieve(domain: EEVeraMentorDomain" in refindex and "entry.domains.contains(domain)" in refindex,
"runtime attaches citations after the provider, never before the gate":"let citations = EEVeraReferenceIndex.retrieve" in engine and engine.index("EEVeraSafetyRouter.gate(context)") < engine.index("let citations = EEVeraReferenceIndex.retrieve"),
"reply view surfaces citations with edition-verification disclosure":"vera.citations" in ui and "VERIFY AGAINST YOUR AHJ-ADOPTED EDITION" in ui,
"tests cover citation retrieval and gate-then-cite ordering":"everyEntryDeclaresAtLeastOneDomainAndKeyword" in tests and "stopVerdictStillReceivesCitations" in tests,
# Deeper library: MSHA (coal mining federal regulation), more NEC/NFPA
# 70E breadth, and a query-independent browse view.
"MSHA source exists for coal mining regulation":'case msha = "MSHA (30 CFR)"' in refindex and "domains: [.coalMining]" in refindex,
"every domain has at least one library entry":refindex.count("domains: [") >= 25,
"library() groups by source for query-independent browsing":"static func library(for domain: EEVeraMentorDomain)" in refindex and "Dictionary(grouping:" in refindex,
"UI exposes the browse-library view":"EEVeraReferenceLibraryView" in ui and "vera.referenceLibrary" in ui,
"tests cover the expanded library and MSHA citation":"everyDomainHasAtLeastOneLibraryEntry" in tests and "methaneMonitoringQueryFindsMSHACitation" in tests,
# Even deeper: OSHA + industry-standard sources, restored
# firstQuestions/commonFalsePositives pathway depth, and UI surfacing
# of both.
"OSHA and industry-standard sources exist":'case osha = "OSHA (29 CFR)"' in refindex and 'case industryStandard = "Industry standard"' in refindex,
"pathway restores firstQuestions and commonFalsePositives":"public let firstQuestions: [String]" in engine and "public let commonFalsePositives: [String]" in engine,
"every domain pathway has first questions and false positives populated":engine.count("firstQuestions:") >= 6 and engine.count("commonFalsePositives:") >= 6,
"UI surfaces first questions and false positives, not just next actions":"vera.firstQuestions" in ui and "vera.falsePositives" in ui,
"tests cover pathway depth across every domain":"everyDomainHasFirstQuestionsAndFalsePositives" in tests,
"tests cover OSHA/industry-standard retrieval":"lotoQueryFindsBothOSHAAndNFPA70ECitations" in tests and "safetyInstrumentedSystemQueryFindsIEC61511" in tests,
# Second-generation port: plcAutomation domain, controlling-authority
# index with real source URLs, checklist knowledge, and free-text
# standards routing (from the updated upstream I&E Trainer handoff).
"plcAutomation domain exists with a pathway":"case plcAutomation" in engine and "case .plcAutomation:" in engine,
"code knowledge cites real https authorities, not copied text":"public let sourceURL: URL" in codeknowledge and 'authority: "NFPA 70E"' in codeknowledge,
"uglys reference is scoped to hands-on domains only":"static func references(for domain: EEVeraMentorDomain)" in codeknowledge and ".naturalGas, .coalMining, .rotatingEquipment, .processSafety:" in codeknowledge,
"safety checklist has verify/doNotInfer/escalateWhen per entry":"public let verify: [String]" in safetyknowledge and "public let doNotInfer: [String]" in safetyknowledge and "public let escalateWhen: [String]" in safetyknowledge,
"standards navigator routes free text to hazards and authorities, not the gate":"static func route(question: String" in navigator and "enum EEVeraStandardsHazard" in navigator,
"reply always carries controllingAuthorities and standardsRoute":"controllingAuthorities: [EEVeraCodeReference]" in engine and "standardsRoute: EEVeraStandardsRoute" in engine,
"UI surfaces controlling authorities and standards routing":"vera.controllingAuthorities" in ui and "vera.standardsRoute" in ui,
"tests cover the second-generation port":"everyReferenceHasAWellFormedHTTPSURL" in tests and "plcQuestionRoutesToControlSystemHazardWithOnlineEditStop" in tests and "controlsFamilyCoversOnlineEditDiscipline" in tests,
# Persona system prompt: staged for a future LLM-backed provider, inert
# for the current offline deterministic one. Regression-guard the hard
# safety/tone boundaries so a future prompt edit can't silently drop them.
"specification file exists with version and system prompt":"public static let version" in spec and "public static let systemPrompt" in spec,
"system prompt declares the never-flirtatious hard boundary":"No flirtation, innuendo, romantic framing" in spec,
"system prompt declares safety is never softened for tone":"safety confirmations are never cut for tone or brevity" in spec,
"persona safety invariants are separately testable, not just prose":"public static let personaSafetyInvariants: [String]" in spec,
"envelope helper exists for a future provider's request context":"public static func envelope(for context: EEVeraMentorContext)" in spec and "struct RequestEnvelope" in spec,
"UI discloses spec version and that no model is actually installed":"vera.specVersion" in ui and "no on-device or connected model is installed" in ui,
"tests cover spec invariants, EOR/AHJ boundary, and envelope round-trip":"systemPromptContainsEveryPersonaSafetyInvariantVerbatim" in tests and "envelopeRoundTripsThroughJSON" in tests,
# Equipment expertise: the 10 requested gas-facility systems, each with
# real diagnostic content and citations that must resolve against the
# actual reference index (never an invented citation id).
"all 10 requested equipment families are present":equipment.count('.init(id: "') >= 10,
"equipment families cover ESD/blowdown, LEL detection, TEG, and safety PLCs":all(s in equipment for s in ['id: "esd-shutdown-blowdown"','id: "lel-toxic-gas-detection"','id: "teg-dehydration-skid"','id: "safety-plc-rtu-cause-effect"']),
"equipment match() is keyword-scored and domain-agnostic":"static func match(query: String" in equipment,
"reply always carries equipmentExpertise":"equipmentExpertise: [EEVeraEquipmentFamily]" in engine and "EEVeraEquipmentExpertise.match(query: query)" in engine,
"UI surfaces equipment expertise in the reply":"vera.equipmentExpertise" in ui,
"tests cover all 10 families, citation-id integrity, and query matching":"allTenRequestedFamiliesArePresentWithUniqueIDs" in tests and "everyCitationIDResolvesToARealReferenceIndexEntry" in tests and "tegQueryMatchesTheDehydrationSkidFamily" in tests,
# Third-generation port: step-by-step field technique playbooks, and a
# real (gated, inert-everywhere-it-builds-today) on-device provider.
"field techniques exist with sequence/evidence/stop conditions":"public let sequence: [String]" in techniques and "public let stopConditions: [String]" in techniques,
"technique search is keyword-scored, no acceptance values given":"static func search(_ query: String" in techniques,
"Apple Foundation Models provider is gated behind canImport, never unconditional":"#if canImport(FoundationModels)" in foundationprovider and "#endif" in foundationprovider,
"foundation provider refuses enrichment on anything but confirmedSafe":"safety.status == .confirmedSafe" in foundationprovider,
"foundation provider falls back to offline on unavailability and on error":foundationprovider.count("EEVeraOfflineProvider().reply(for: context, safety: safety)") >= 2,
"provider resolver exists and defaults every non-FoundationModels build to offline":"enum EEVeraMentorProviderResolver" in capabilities and "return EEVeraOfflineProvider()" in capabilities,
"runtime reply() consults the resolver instead of a hardcoded provider":"EEVeraMentorProviderResolver.provider()" in engine,
"tests cover field techniques and resolver fallback safety":"allNineTechniquesArePresentWithUniqueIDs" in tests and "allowOnDevicePolicyStillResolvesToOfflineOnThisBuild" in tests,
}
for k,v in checks.items(): print(("PASS" if v else "FAIL"),k)
raise SystemExit(0 if all(checks.values()) else 1)
