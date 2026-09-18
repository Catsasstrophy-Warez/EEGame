import Foundation
import Testing
@testable import ScenarioEngine

@Suite("Rev86 causal depth")
struct Rev86CausalDepthTests {
    @Test func timeCurrentCurveInterpolates() {
        let c = EETimeCurrentCurve86(points: [.init(1, 100), .init(10, 0.1)])
        let mid = c.clearingSeconds(at: sqrt(10.0))
        #expect(mid > 2 && mid < 5)
    }
    @Test func breakerHasThermalMemory() {
        var b = EEBreakerState86(); b.ratingA = 10
        for _ in 0..<200 { b.integrate(currentA: 25, dt: 0.1); if b.isOpen { break } }
        #expect(b.thermalMemory01 > 0)
    }
    @Test func hotDegradedContactRaisesResistance() {
        var c = EEContactState86(); c.degradation01 = 0.8
        let cold = c.effectiveResistanceOhm
        c.temperatureC = 120
        #expect(c.effectiveResistanceOhm > cold)
    }
    @Test func motorStartProducesSag() {
        var s = EEDeepMachineState86()
        s.contactor.phase = .closed; s.contactor.mainContactClosed = true; s.contactor.armaturePosition01 = 1
        EEDeepCausalMachine86.step(&s, dt: 0.002)
        EEDeepCausalMachine86.step(&s, dt: 0.002)
        #expect(s.motor.currentA > s.motor.ratedCurrentA)
        #expect(s.lastFeederVoltageV < s.feederNominalV)
    }
    @Test func discreteInputUsesThresholdAndFilter() {
        var di = EEDiscreteInputState86()
        for _ in 0..<20 { di.sample(voltageV: 24, dt: 0.001) }
        #expect(di.logicalState)
        for _ in 0..<30 { di.sample(voltageV: 0, dt: 0.001) }
        #expect(!di.logicalState)
    }
    @Test func analogLoopIsMNASolvedAndComplianceLimited() {
        let ok = EEAnalogLoopSolver86.solve(commandMA: 12, supplyV: 24, wireOhm: 250, burdenOhm: 250, complianceV: 8)
        #expect(ok.converged); #expect(abs(ok.currentMA - 12) < 0.01)
        let limited = EEAnalogLoopSolver86.solve(commandMA: 20, supplyV: 12, wireOhm: 500, burdenOhm: 500, complianceV: 8)
        #expect(limited.complianceLimited); #expect(limited.currentMA < 20)
    }
    @Test func lowZCollapsesHighImpedanceGhostVoltage() {
        let dmm = EEDMMSolver86.measure(sourceV: 67, sourceResistanceOhm: 2_000_000, inputResistanceOhm: 10_000_000)
        let loz = EEDMMSolver86.measure(sourceV: 67, sourceResistanceOhm: 2_000_000, inputResistanceOhm: 3_000)
        #expect(dmm.volts > 40); #expect(loz.volts < 1)
    }
    @Test func scopeAndSOEAreObservers() {
        var s = EEDeepMachineState86(); let before = s.control
        s.evidence.scope.append(time: 0, channel: "X", value: 1)
        s.evidence.transition(time: 0, identity: "X", property: "state", old: "0", new: "1")
        #expect(s.control == before); #expect(s.evidence.scope.samples.count == 1); #expect(s.evidence.soe.count == 1)
    }
    @Test func firstDivergenceFindsMeasuredDifference() {
        var a = EECausalEvidence86(), b = EECausalEvidence86()
        a.scope.append(time: 0, channel: "V", value: 24); b.scope.append(time: 0, channel: "V", value: 23)
        #expect(EEDeepCausalMachine86.firstDivergence(reference: a, observed: b)?.value == 23)
    }
    @Test func saveReloadPreservesDeepPhysicalMemory() throws {
        var s = EEDeepMachineState86(); s.breaker.thermalMemory01 = 0.42; s.contactor.contact.temperatureC = 83
        let data = try JSONEncoder().encode(s); let r = try JSONDecoder().decode(EEDeepMachineState86.self, from: data)
        #expect(r.breaker.thermalMemory01 == 0.42); #expect(r.contactor.contact.temperatureC == 83)
    }
}
