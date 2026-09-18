import Foundation
import Testing
@testable import ScenarioEngine

@Suite("Rev85 continuous causal machine")
struct Rev85ContinuousCausalMachineTests {
    @Test func healthyLoopPropagatesElectricalToProcessToPLC() {
        var s = EEMachineState85()
        EEContinuousCausalMachine85.run(&s, duration: 3.0)
        #expect(s.electrical.converged)
        #expect(s.actuator.coilCurrentA > 0.005)
        #expect(s.actuator.valvePosition01 > 0.5)
        #expect(s.process.pressurePSI > 550)
        #expect(s.instrumentation.actualLoopCurrentMA > 4)
        #expect(s.plc.processValuePSI > 500)
        #expect(!s.evidence.isEmpty)
    }

    @Test func degradedTerminalChangesPhysicsWithoutAuthoredSymptoms() {
        var healthy = EEMachineState85()
        var degraded = EEMachineState85()
        EEContinuousCausalMachine85.inject(.init(targetIdentity: "TB1:12", kind: .degradedTerminal, severity01: 1), into: &degraded)
        EEContinuousCausalMachine85.run(&healthy, duration: 1.0)
        EEContinuousCausalMachine85.run(&degraded, duration: 1.0)
        #expect(degraded.parameters.terminalResistanceOhm > healthy.parameters.terminalResistanceOhm)
        #expect(degraded.thermal.terminalTemperatureC > healthy.thermal.terminalTemperatureC)
        #expect(degraded.electrical.nodeVoltages[6] < healthy.electrical.nodeVoltages[6])
    }

    @Test func openDisconnectCollapsesControlPath() {
        var s = EEMachineState85()
        s.commissioning.disconnectClosed = false
        EEContinuousCausalMachine85.run(&s, duration: 0.1)
        #expect(abs(s.electrical.nodeVoltages[6]) < 0.01)
        #expect(s.actuator.coilCurrentA < 0.001)
    }

    @Test func weakSupplyCreatesSag() {
        var healthy = EEMachineState85()
        var weak = EEMachineState85()
        EEContinuousCausalMachine85.inject(.init(targetIdentity: "PS1", kind: .weakSupply, severity01: 1), into: &weak)
        EEContinuousCausalMachine85.step(&healthy, dt: 0.01)
        EEContinuousCausalMachine85.step(&weak, dt: 0.01)
        #expect(weak.electrical.nodeVoltages[2] < healthy.electrical.nodeVoltages[2])
    }

    @Test func valveBindingPropagatesToProcessAndInstrument() {
        var healthy = EEMachineState85()
        var bound = EEMachineState85()
        EEContinuousCausalMachine85.inject(.init(targetIdentity: "XV-101", kind: .valveBinding, severity01: 0.9), into: &bound)
        EEContinuousCausalMachine85.run(&healthy, duration: 4.0)
        EEContinuousCausalMachine85.run(&bound, duration: 4.0)
        #expect(bound.actuator.valvePosition01 < healthy.actuator.valvePosition01)
        #expect(bound.process.pressurePSI < healthy.process.pressurePSI)
        #expect(bound.instrumentation.actualLoopCurrentMA < healthy.instrumentation.actualLoopCurrentMA)
    }

    @Test func scalingErrorDoesNotChangePhysicalProcess() {
        var baseline = EEMachineState85()
        var scaled = EEMachineState85()
        EEContinuousCausalMachine85.inject(.init(targetIdentity: "AI-04", kind: .plcScalingError, severity01: 1), into: &scaled)
        EEContinuousCausalMachine85.run(&baseline, duration: 2.0)
        EEContinuousCausalMachine85.run(&scaled, duration: 2.0)
        #expect(abs(scaled.process.pressurePSI - baseline.process.pressurePSI) < 0.001)
        #expect(abs(scaled.instrumentation.actualLoopCurrentMA - baseline.instrumentation.actualLoopCurrentMA) < 0.001)
        #expect(scaled.plc.processValuePSI != baseline.plc.processValuePSI)
    }

    @Test func evidenceIsObservational() {
        var a = EEMachineState85()
        var b = EEMachineState85()
        EEContinuousCausalMachine85.run(&a, duration: 0.5)
        EEContinuousCausalMachine85.run(&b, duration: 0.5)
        b.evidence.removeAll()
        #expect(a.electrical == b.electrical)
        #expect(a.thermal == b.thermal)
        #expect(a.actuator == b.actuator)
        #expect(a.process == b.process)
    }

    @Test func saveReloadPreservesThermalMemoryAndLatentFaults() throws {
        var s = EEMachineState85()
        EEContinuousCausalMachine85.inject(.init(targetIdentity: "TB1:12", kind: .degradedTerminal, severity01: 0.7), into: &s)
        EEContinuousCausalMachine85.run(&s, duration: 0.5)
        let data = try JSONEncoder().encode(s)
        let restored = try JSONDecoder().decode(EEMachineState85.self, from: data)
        #expect(restored.thermal == s.thermal)
        #expect(restored.parameters == s.parameters)
        #expect(restored.rev85LatentState == s.rev85LatentState)
    }
}
