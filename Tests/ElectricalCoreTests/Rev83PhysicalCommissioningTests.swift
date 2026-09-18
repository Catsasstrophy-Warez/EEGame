import Testing
import ScenarioEngine
@Suite("Rev83 Physical Commissioning")
struct Rev83PhysicalCommissioningTests {
    @Test func openDisconnectRemovesControlPower() {
        var s=EECommissioningState83(); s.toggle(.disconnect)
        #expect(!s.controlPowerAvailable); #expect(!s.solenoidEnergized)
    }
    @Test func anyOpenFuseInterruptsControlPower() {
        var s=EECommissioningState83(); s.toggle(.fuseB)
        #expect(!s.controlPowerAvailable)
    }
    @Test func overloadTripInterruptsActuation() {
        var s=EECommissioningState83(); s.toggle(.overload)
        #expect(!s.solenoidEnergized); #expect(!s.valveOpen)
    }
    @Test func stuckValveSeparatesElectricalAndMechanicalTruth() {
        var s=EECommissioningState83(); s.valveMechanicallyFree=false
        #expect(s.solenoidEnergized); #expect(!s.valveOpen)
    }
    @Test func cutawayReflectsMechanicalStall() {
        var s=EECommissioningState83(); s.valveMechanicallyFree=false
        let a=EEActuation83.solve(state:s,currentA:0.02)
        #expect(a.plungerPosition > 0); #expect(a.valveStemPosition == 0)
    }
    @Test func controlWireEnergizationTracksProtection() {
        var s=EECommissioningState83()
        let w=EEPhysicalNetwork83.conductors.first{$0.wireNumber=="W-1207"}!
        #expect(EEPhysicalNetwork83.energized(w,state:s))
        s.toggle(.disconnect)
        #expect(!EEPhysicalNetwork83.energized(w,state:s))
    }
}
