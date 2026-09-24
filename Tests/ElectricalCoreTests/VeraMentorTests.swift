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
