import Testing
import ScenarioEngine

@Suite("Rev78 Interactive Measurement")
struct Rev78InteractiveMeasurementTests {
    @Test func sourceToGroundReadsSupply() {
        let c=EESimulationCoordinator75()
        let m=c.measure78(red:.source,black:.ground)
        #expect(m.volts == c.snapshot.sourceVoltage)
    }

    @Test func reversingLeadsReversesPolarity() {
        let c=EESimulationCoordinator75()
        let a=c.measure78(red:.tb112,black:.ground)
        let b=c.measure78(red:.ground,black:.tb112)
        #expect(abs(a.volts + b.volts) < 0.000001)
    }

    @Test func sameNodeReadsZero() {
        let c=EESimulationCoordinator75()
        #expect(abs(c.measure78(red:.tb112,black:.tb112).volts) < 0.000001)
    }

    @Test func terminalAndSolenoidShareCurrentProductionNode() {
        let c=EESimulationCoordinator75()
        #expect(c.nodeVoltage78(.tb112) == c.nodeVoltage78(.sol101))
    }
}
