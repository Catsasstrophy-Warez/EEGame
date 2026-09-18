import Testing
import ScenarioEngine
@Suite("Rev84 Unified Electrical Truth")
struct Rev84UnifiedElectricalTruthTests {
    @Test func healthyTopologyEnergizesTerminalAndSolenoid() {
        let t=EEUnifiedElectricalTruth84.solve(state:.init())
        #expect(t.converged); #expect(t.voltage(.terminal)>20); #expect(t.voltage(.solenoid)>20); #expect(t.coilCurrentA>0)
    }
    @Test func openDisconnectCollapsesDownstreamVoltage() {
        var s=EECommissioningState83(); s.toggle(.disconnect)
        let t=EEUnifiedElectricalTruth84.solve(state:s)
        #expect(t.voltage(.source)>23); #expect(t.voltage(.terminal)<0.01); #expect(t.coilCurrentA<0.000001)
    }
    @Test func openFuseCollapsesDownstreamVoltage() {
        var s=EECommissioningState83(); s.toggle(.fuseA)
        let t=EEUnifiedElectricalTruth84.solve(state:s)
        #expect(t.voltage(.afterDisconnect)>20); #expect(t.voltage(.terminal)<0.01)
    }
    @Test func plcOutputOffCollapsesTerminalButLeavesUpstreamPower() {
        var s=EECommissioningState83(); s.plcDO4=false
        let t=EEUnifiedElectricalTruth84.solve(state:s)
        #expect(t.voltage(.afterFuse)>20); #expect(t.voltage(.terminal)<0.01)
    }
    @Test func highResistanceCreatesMeasurableVoltageDrop() {
        let t=EEUnifiedElectricalTruth84.solve(state:.init(),failure:.highResistance)
        #expect(t.voltage(.plcOutput)-t.voltage(.terminal)>1)
    }
    @Test func shortToGroundPullsTerminalLowAndRaisesSourceCurrent() {
        let healthy=EEUnifiedElectricalTruth84.solve(state:.init())
        let fault=EEUnifiedElectricalTruth84.solve(state:.init(),failure:.shortToGround)
        #expect(fault.voltage(.terminal)<healthy.voltage(.terminal))
        #expect(fault.controlCurrentA>healthy.controlCurrentA)
    }
    @Test func dmmPolarityComesFromSolvedNodes() {
        let t=EEUnifiedElectricalTruth84.solve(state:.init())
        let a=EEUnifiedElectricalTruth84.measure(red:.tb112,black:.ground,truth:t)
        let b=EEUnifiedElectricalTruth84.measure(red:.ground,black:.tb112,truth:t)
        #expect(abs(a+b)<0.000001)
    }
}
