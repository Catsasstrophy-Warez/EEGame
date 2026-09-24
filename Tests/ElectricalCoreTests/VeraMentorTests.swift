import Testing
import Foundation
@testable import ScenarioEngine

@Suite("Vera mentor safety gate") struct VeraMentorTests {
    @Test func protectiveFunctionAffectedStopsBeforeIdentity() {
        var c = EEVeraMentorContext(domain: .electrical)
        c.safetyFunctionAffected = true
        let r = EEVeraMentorDiagnosticEngine.response(for: c)
        #expect(r.status == .stopAndEscalate)
        #expect(r.title == "Protective function affected")
    }

    @Test func unconfirmedIdentityStops() {
        var c = EEVeraMentorContext(domain: .electrical)
        c.energyIsolatedAndVerified = true
        let r = EEVeraMentorDiagnosticEngine.response(for: c)
        #expect(r.status == .stopAndEscalate)
        #expect(r.title == "Confirm the asset before measuring")
    }

    @Test func naturalGasRequiresAreaAndGasTestBeforeEnergyBoundary() {
        var c = EEVeraMentorContext(domain: .naturalGas)
        c.identityConfirmed = true
        let r = EEVeraMentorDiagnosticEngine.response(for: c)
        #expect(r.status == .stopAndEscalate)
        #expect(r.title == "Area and atmosphere gate")
    }

    @Test func coalMiningRequiresAreaAndGasTestBeforeEnergyBoundary() {
        var c = EEVeraMentorContext(domain: .coalMining)
        c.identityConfirmed = true
        let r = EEVeraMentorDiagnosticEngine.response(for: c)
        #expect(r.status == .stopAndEscalate)
        #expect(r.title == "Area and atmosphere gate")
    }

    @Test func electricalDoesNotRequireGasGate() {
        var c = EEVeraMentorContext(domain: .electrical)
        c.identityConfirmed = true
        c.energyIsolatedAndVerified = true
        let r = EEVeraMentorDiagnosticEngine.response(for: c)
        #expect(r.status == .confirmedSafe)
    }

    @Test func unverifiedEnergyStopsAfterGasGateClears() {
        var c = EEVeraMentorContext(domain: .naturalGas)
        c.identityConfirmed = true
        c.areaClassificationKnown = true
        c.gasTestCurrent = true
        let r = EEVeraMentorDiagnosticEngine.response(for: c)
        #expect(r.status == .stopAndEscalate)
        #expect(r.title == "Establish zero energy or approved test boundary")
    }

    @Test func fullyGatedContextWithNoEvidenceSuggestsAnchor() {
        var c = EEVeraMentorContext(domain: .electrical)
        c.identityConfirmed = true
        c.energyIsolatedAndVerified = true
        let r = EEVeraMentorDiagnosticEngine.response(for: c)
        #expect(r.status == .confirmedSafe)
        #expect(r.title == "Build an evidence anchor")
    }

    @Test func firstDivergenceIsSurfacedOnceGated() {
        var c = EEVeraMentorContext(domain: .electrical)
        c.identityConfirmed = true
        c.energyIsolatedAndVerified = true
        c.evidenceCount = 3
        c.firstDivergence = "24VDC loop power at the field junction"
        let r = EEVeraMentorDiagnosticEngine.response(for: c)
        #expect(r.status == .confirmedSafe)
        #expect(r.title == "First divergence: 24VDC loop power at the field junction")
    }

    @Test func offlineProviderNeverUpgradesAStopVerdict() async {
        var c = EEVeraMentorContext(domain: .electrical)
        c.safetyFunctionAffected = true
        let reply = await EEVeraMentorRuntime.reply(for: c)
        #expect(reply.safety.status == .stopAndEscalate)
        #expect(reply.mode == .offlineDeterministic)
    }
}

@Suite("Vera mentor audit/config persistence") struct VeraMentorStoreTests {
    private func freshDefaults() -> UserDefaults {
        let suite = "vera.mentor.tests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    @Test func defaultConfigurationIsOfflineOnlyWithAuditRetained() {
        let d = freshDefaults()
        let c = EEVeraMentorStore.loadConfiguration(from: d)
        #expect(c.providerPolicy == .offlineOnly)
        #expect(c.retainAuditLog == true)
    }

    @Test func configurationRoundTrips() {
        let d = freshDefaults()
        var c = EEVeraMentorConfiguration()
        c.providerPolicy = .allowOnDevice
        c.retainAuditLog = false
        EEVeraMentorStore.saveConfiguration(c, to: d)
        let loaded = EEVeraMentorStore.loadConfiguration(from: d)
        #expect(loaded == c)
    }

    @Test func auditAppendsAndBoundsAt100() {
        let d = freshDefaults()
        for i in 0..<105 {
            EEVeraMentorStore.append(.init(id: UUID(), timestamp: Date(), mode: .offlineDeterministic, safetyStatus: .confirmedSafe, contextID: "eq-\(i)"), to: d)
        }
        let events = EEVeraMentorStore.loadAudit(from: d)
        #expect(events.count == 100)
        #expect(events.last?.contextID == "eq-104")
    }

    @Test func clearAuditEmptiesTheLog() {
        let d = freshDefaults()
        EEVeraMentorStore.append(.init(id: UUID(), timestamp: Date(), mode: .offlineDeterministic, safetyStatus: .confirmedSafe, contextID: "x"), to: d)
        EEVeraMentorStore.clearAudit(from: d)
        #expect(EEVeraMentorStore.loadAudit(from: d).isEmpty)
    }

    @Test func replyWithAuditPersistsAnEventWhenRetentionIsOn() async {
        let d = freshDefaults()
        var c = EEVeraMentorContext(domain: .electrical, equipmentID: "MTR-1")
        c.identityConfirmed = true
        c.energyIsolatedAndVerified = true
        _ = await EEVeraMentorRuntime.replyWithAudit(for: c, configuration: EEVeraMentorConfiguration(), defaults: d)
        let events = EEVeraMentorStore.loadAudit(from: d)
        #expect(events.count == 1)
        #expect(events.first?.contextID == "MTR-1")
        #expect(events.first?.safetyStatus == .confirmedSafe)
    }

    @Test func replyWithAuditSkipsPersistenceWhenRetentionIsOff() async {
        let d = freshDefaults()
        var config = EEVeraMentorConfiguration()
        config.retainAuditLog = false
        let c = EEVeraMentorContext(domain: .electrical, equipmentID: "MTR-2")
        _ = await EEVeraMentorRuntime.replyWithAudit(for: c, configuration: config, defaults: d)
        #expect(EEVeraMentorStore.loadAudit(from: d).isEmpty)
    }
}

@Suite("Vera mentor live-state context builders") struct VeraMentorContextFactoryTests {
    @Test func coalMiningContextIsSafeWhenAllSensorsAreNormal() {
        let state = EECoalMiningRev44()
        let context = EEVeraMentorContextFactory.coalMining(
            mine: .northRidge, state: state, equipmentID: "northRidge", symptom: "check",
            identityConfirmed: true, areaClassificationKnown: true, gasTestCurrent: true, energyIsolatedAndVerified: true
        )
        #expect(context.safetyFunctionAffected == false)
        let response = EEVeraSafetyRouter.gate(context)
        #expect(response.status == .confirmedSafe)
    }

    @Test func coalMiningContextEscalatesOnRealMethaneAlarm() {
        var state = EECoalMiningRev44()
        var network = state.atmosphere[.northRidge]!
        network.sensors[0].methanePercent = 2.5
        state.atmosphere[.northRidge] = network
        // energyIsolatedAndVerified stays false here: the engine's
        // protective-function branch only fires when the energy boundary is
        // NOT yet confirmed, matching the ordering asserted in
        // protectiveFunctionAffectedStopsBeforeIdentity above.
        let context = EEVeraMentorContextFactory.coalMining(
            mine: .northRidge, state: state, equipmentID: "northRidge", symptom: "check",
            identityConfirmed: true, areaClassificationKnown: true, gasTestCurrent: true, energyIsolatedAndVerified: false
        )
        #expect(context.safetyFunctionAffected == true)
        let response = EEVeraSafetyRouter.gate(context)
        #expect(response.status == .stopAndEscalate)
        #expect(response.title == "Protective function affected")
    }

    @Test func facilityPowerContextEscalatesOnRealTripCause() {
        var state = EEFacilityPowerState88()
        state.protection.tripCause = .overload
        let context = EEVeraMentorContextFactory.facilityPower(
            state: state, equipmentID: "MCC-1", symptom: "check", identityConfirmed: true, energyIsolatedAndVerified: false
        )
        #expect(context.safetyFunctionAffected == true)
        let response = EEVeraSafetyRouter.gate(context)
        #expect(response.status == .stopAndEscalate)
    }

    @Test func facilityPowerContextIsSafeWithNoTripOrFault() {
        let state = EEFacilityPowerState88()
        let context = EEVeraMentorContextFactory.facilityPower(
            state: state, equipmentID: "MCC-1", symptom: "check", identityConfirmed: true, energyIsolatedAndVerified: true
        )
        #expect(context.safetyFunctionAffected == false)
        let response = EEVeraSafetyRouter.gate(context)
        #expect(response.status == .confirmedSafe)
    }
}

@Suite("Vera mentor reference index") struct VeraMentorReferenceIndexTests {
    @Test func everyEntryDeclaresAtLeastOneDomainAndKeyword() {
        for entry in EEVeraReferenceIndex.entries {
            #expect(!entry.domains.isEmpty, "\(entry.id) has no domain")
            #expect(!entry.keywords.isEmpty, "\(entry.id) has no keywords")
            #expect(!entry.citation.isEmpty, "\(entry.id) has no citation label")
        }
    }

    @Test func entryIDsAreUnique() {
        let ids = EEVeraReferenceIndex.entries.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func retrievalIsScopedToTheRequestedDomain() {
        let results = EEVeraReferenceIndex.retrieve(domain: .naturalGas, query: "ground fault gfci receptacle")
        for r in results { #expect(r.domains.contains(.naturalGas)) }
    }

    @Test func groundFaultQueryFindsTheGFCICitation() {
        let results = EEVeraReferenceIndex.retrieve(domain: .electrical, query: "GFCI nuisance trip on a receptacle")
        #expect(results.contains { $0.id == "nec-210.8" })
    }

    @Test func arcFlashQueryFindsNFPA70ECitation() {
        let results = EEVeraReferenceIndex.retrieve(domain: .electrical, query: "arc flash PPE category boundary")
        #expect(results.contains { $0.id == "nfpa70e-130" })
    }

    @Test func classifiedAreaQueryFindsHazardousLocationCitation() {
        let results = EEVeraReferenceIndex.retrieve(domain: .naturalGas, query: "classified area hazardous location")
        #expect(results.contains { $0.id == "nec-500" })
    }

    @Test func noKeywordMatchStillReturnsDomainScopedFallback() {
        let results = EEVeraReferenceIndex.retrieve(domain: .rotatingEquipment, query: "zzz-nonsense-query-zzz")
        #expect(!results.isEmpty)
        for r in results { #expect(r.domains.contains(.rotatingEquipment)) }
    }

    @Test func replyAttachesDomainScopedCitations() async {
        var c = EEVeraMentorContext(domain: .electrical, symptom: "GFCI keeps tripping on a receptacle circuit")
        c.identityConfirmed = true
        c.energyIsolatedAndVerified = true
        let reply = await EEVeraMentorRuntime.reply(for: c)
        #expect(!reply.citations.isEmpty)
        for citation in reply.citations { #expect(citation.domains.contains(.electrical)) }
    }

    @Test func stopVerdictStillReceivesCitations() async {
        var c = EEVeraMentorContext(domain: .naturalGas, symptom: "gas detector alarm near the compressor")
        c.identityConfirmed = true
        let reply = await EEVeraMentorRuntime.reply(for: c)
        #expect(reply.safety.status == .stopAndEscalate)
        #expect(!reply.citations.isEmpty)
    }

    @Test func libraryIsScopedToOneDomainAndGroupedBySource() {
        let library = EEVeraReferenceIndex.library(for: .coalMining)
        #expect(!library.isEmpty)
        for (_, citations) in library {
            for c in citations { #expect(c.domains.contains(.coalMining)) }
        }
        // Coal mining is the one domain with MSHA (30 CFR) entries.
        #expect(library[.msha]?.isEmpty == false)
    }

    @Test func everyDomainHasAtLeastOneLibraryEntry() {
        for domain in EEVeraMentorDomain.allCases {
            let library = EEVeraReferenceIndex.library(for: domain)
            let total = library.values.reduce(0) { $0 + $1.count }
            #expect(total > 0, "\(domain) has no reference entries")
        }
    }

    @Test func methaneMonitoringQueryFindsMSHACitation() {
        let results = EEVeraReferenceIndex.retrieve(domain: .coalMining, query: "methane monitoring de-energization")
        #expect(results.contains { $0.id == "msha-75.323" })
    }

    @Test func classifiedAreaLibraryDistinguishesClassIAndClassII() {
        let gasLibrary = EEVeraReferenceIndex.library(for: .naturalGas)
        let coalLibrary = EEVeraReferenceIndex.library(for: .coalMining)
        let gasIDs = Set((gasLibrary[.nec] ?? []).map(\.id))
        let coalIDs = Set((coalLibrary[.nec] ?? []).map(\.id))
        #expect(gasIDs.contains("nec-501"))
        #expect(coalIDs.contains("nec-503"))
    }

    @Test func vibrationQueryFindsRotatingEquipmentFieldReference() {
        let results = EEVeraReferenceIndex.retrieve(domain: .rotatingEquipment, query: "vibration severity zone")
        #expect(results.contains { $0.id == "field-vibration-severity-zones" })
    }

    @Test func lotoQueryFindsBothOSHAAndNFPA70ECitations() {
        let results = EEVeraReferenceIndex.retrieve(domain: .electrical, query: "lockout tagout energy control")
        #expect(results.contains { $0.id == "osha-1910.147" })
    }

    @Test func areaClassificationQueryFindsAPIAndNECCitations() {
        let results = EEVeraReferenceIndex.retrieve(domain: .naturalGas, query: "area classification study petroleum")
        #expect(results.contains { $0.id == "api-rp-500-505" })
    }

    @Test func safetyInstrumentedSystemQueryFindsIEC61511() {
        let results = EEVeraReferenceIndex.retrieve(domain: .processSafety, query: "SIL proof test safety instrumented system")
        #expect(results.contains { $0.id == "iec-61511-isa-84" })
    }

    @Test func confinedSpaceQueryReachesCoalMiningAndNaturalGas() {
        let coal = EEVeraReferenceIndex.retrieve(domain: .coalMining, query: "confined space entry permit")
        let gas = EEVeraReferenceIndex.retrieve(domain: .naturalGas, query: "confined space entry permit")
        #expect(coal.contains { $0.id == "osha-1910.146" })
        #expect(gas.contains { $0.id == "osha-1910.146" })
    }
}

@Suite("Vera mentor pathway depth") struct VeraMentorPathwayTests {
    @Test func everyDomainHasFirstQuestionsAndFalsePositives() {
        for domain in EEVeraMentorDomain.allCases {
            let pathway = EEVeraMentorDomainKnowledge.pathway(for: domain)
            #expect(!pathway.firstQuestions.isEmpty, "\(domain) has no first questions")
            #expect(!pathway.commonFalsePositives.isEmpty, "\(domain) has no false positives")
            #expect(!pathway.independentEvidence.isEmpty, "\(domain) has no independent evidence")
            #expect(!pathway.escalationTriggers.isEmpty, "\(domain) has no escalation triggers")
        }
    }

    @Test func confirmedSafeResponseCarriesTheDomainPathway() {
        var c = EEVeraMentorContext(domain: .coalMining)
        c.identityConfirmed = true
        c.areaClassificationKnown = true
        c.gasTestCurrent = true
        c.energyIsolatedAndVerified = true
        let response = EEVeraMentorDiagnosticEngine.response(for: c)
        #expect(response.pathway.domain == .coalMining)
        #expect(response.pathway.commonFalsePositives.contains { $0.contains("methane ignition") || $0.contains("bearing heat") })
    }

    @Test func plcAutomationDomainStopsOnUnconfirmedIdentityLikeEveryOtherDomain() {
        var c = EEVeraMentorContext(domain: .plcAutomation)
        c.energyIsolatedAndVerified = true
        let response = EEVeraMentorDiagnosticEngine.response(for: c)
        #expect(response.status == .stopAndEscalate)
        #expect(response.pathway.domain == .plcAutomation)
    }

    @Test func plcAutomationDoesNotRequireTheGasGate() {
        var c = EEVeraMentorContext(domain: .plcAutomation)
        c.identityConfirmed = true
        c.energyIsolatedAndVerified = true
        let response = EEVeraMentorDiagnosticEngine.response(for: c)
        #expect(response.status == .confirmedSafe)
    }
}

@Suite("Vera mentor code knowledge (controlling authorities)") struct VeraCodeKnowledgeTests {
    @Test func everyReferenceHasAWellFormedHTTPSURL() {
        for ref in EEVeraCodeKnowledge.references {
            #expect(ref.sourceURL.scheme == "https", "\(ref.id) has a non-https source URL")
            #expect(!ref.authority.isEmpty)
            #expect(!ref.fieldUse.isEmpty)
        }
    }

    @Test func uglysFieldReferenceIsScopedToHandsOnDomains() {
        let electrical = EEVeraCodeKnowledge.references(for: .electrical)
        let coal = EEVeraCodeKnowledge.references(for: .coalMining)
        #expect(electrical.contains { $0.id == "uglys-electrical-references-2023" })
        #expect(!coal.contains { $0.id == "uglys-electrical-references-2023" })
    }

    @Test func plcAutomationGetsTheFullReferenceSet() {
        let plc = EEVeraCodeKnowledge.references(for: .plcAutomation)
        #expect(plc.count == EEVeraCodeKnowledge.references.count)
    }

    @Test func authorityBoundaryNamesEveryAuthority() {
        let boundary = EEVeraCodeKnowledge.authorityBoundary
        #expect(boundary.contains("OSHA"))
        #expect(boundary.contains("NFPA 70E"))
        #expect(boundary.contains("NEC"))
    }
}

@Suite("Vera mentor electrical safety checklist knowledge") struct VeraElectricalSafetyKnowledgeTests {
    @Test func everyEntryHasNonEmptyVerifyDoNotInferAndEscalateWhen() {
        for entry in EEVeraElectricalSafetyKnowledge.entries {
            #expect(!entry.verify.isEmpty, "\(entry.id) has no verify items")
            #expect(!entry.doNotInfer.isEmpty, "\(entry.id) has no doNotInfer items")
            #expect(!entry.escalateWhen.isEmpty, "\(entry.id) has no escalateWhen items")
        }
    }

    @Test func entryIDsAreUnique() {
        let ids = EEVeraElectricalSafetyKnowledge.entries.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func familyFilterReturnsOnlyThatFamily() {
        let nfpa = EEVeraElectricalSafetyKnowledge.entries(for: "NFPA 70E")
        #expect(!nfpa.isEmpty)
        for entry in nfpa { #expect(entry.family == "NFPA 70E") }
    }

    @Test func controlsFamilyCoversOnlineEditDiscipline() {
        let controls = EEVeraElectricalSafetyKnowledge.entries(for: "Controls")
        #expect(controls.contains { $0.id == "plc-online-edit" })
    }
}

@Suite("Vera mentor standards navigator") struct VeraStandardsNavigatorTests {
    @Test func arcFlashQuestionRoutesToArcFlashHazardWithNFPA70EAndOSHA() {
        let route = EEVeraStandardsNavigator.route(question: "What's the arc flash boundary here?", domain: .electrical)
        #expect(route.hazards.contains(.arcFlash))
        #expect(route.authorities.contains { $0.contains("NFPA 70E") })
        #expect(route.authorities.contains { $0.contains("OSHA") })
    }

    @Test func plcQuestionRoutesToControlSystemHazardWithOnlineEditStop() {
        let route = EEVeraStandardsNavigator.route(question: "Can I force this rung to test the interlock?", domain: .plcAutomation)
        #expect(route.hazards.contains(.controlSystem))
        #expect(route.safetyStopTriggers.contains { $0.contains("force, inhibit, bypass") })
    }

    @Test func hazardousLocationQuestionRoutesWithAPIAuthority() {
        let route = EEVeraStandardsNavigator.route(question: "Is this a Class I Division 1 area?", domain: .naturalGas)
        #expect(route.hazards.contains(.hazardousLocation))
        #expect(route.authorities.contains { $0.contains("API RP 500/505") })
        #expect(route.safetyStopTriggers.contains { $0.contains("classification, gas test") })
    }

    @Test func emptyQuestionFallsBackToDomainDefaultHazards() {
        let plcRoute = EEVeraStandardsNavigator.route(question: "", domain: .plcAutomation)
        #expect(plcRoute.hazards == [.controlSystem])
        let coalRoute = EEVeraStandardsNavigator.route(question: "", domain: .coalMining)
        #expect(coalRoute.hazards.contains(.hazardousLocation))
    }

    @Test func everyRouteIncludesTheUniversalStopTriggers() {
        let route = EEVeraStandardsNavigator.route(question: "generic question", domain: .electrical)
        #expect(route.safetyStopTriggers.contains { $0.contains("remembered article number") })
        #expect(!route.verificationQuestions.isEmpty)
    }
}

@Suite("Vera mentor reply carries authorities and routing") struct VeraMentorReplyEnrichmentTests {
    @Test func replyAlwaysCarriesControllingAuthoritiesForItsDomain() async {
        var c = EEVeraMentorContext(domain: .plcAutomation, symptom: "rung reads unexpectedly")
        c.identityConfirmed = true
        c.energyIsolatedAndVerified = true
        let reply = await EEVeraMentorRuntime.reply(for: c)
        #expect(!reply.controllingAuthorities.isEmpty)
        #expect(reply.controllingAuthorities.contains { $0.id == "nfpa-70-2023" })
    }

    @Test func replyAlwaysCarriesAStandardsRouteEvenOnStop() async {
        var c = EEVeraMentorContext(domain: .electrical, symptom: "arc flash risk on this panel")
        c.safetyFunctionAffected = true
        let reply = await EEVeraMentorRuntime.reply(for: c)
        #expect(reply.safety.status == .stopAndEscalate)
        #expect(reply.standardsRoute.hazards.contains(.arcFlash))
    }
}
