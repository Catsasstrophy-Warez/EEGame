import Foundation
import Testing
@testable import ScenarioEngine

@Suite("Rev87 physical network convergence")
struct Rev87PhysicalNetworkConvergenceTests {
    @Test func phaseLossCreatesRealUnbalance() { var s=EEThreePhaseSource87(); s.phaseScale.c=0; let v=s.terminalVoltage(for:.init(10,10,10)); #expect(v.c < 1); #expect(v.maximumDeviationPU > 0.4) }
    @Test func fuseAccumulatesDamage() { var p=EEProtectionState87(); p.fuseRatingA=10; for _ in 0..<5000 { p.integrate(currentA:30,dt:0.001); if p.fuseOpen { break } }; #expect(p.fuseDamage01 > 0) }
    @Test func arcEnergyDegradesContact() { var w=EEContactWear87(); let d=w.contact.degradation01; for _ in 0..<100 { w.integrate(currentA:50,voltageV:277,opening:true,closing:false,dt:0.001) }; #expect(w.arcEnergyJ > 0); #expect(w.contact.degradation01 > d) }
    @Test func motorStartingCurrentAndSagAreCoupled() { var s=EEPhysicalNetworkState87(); s.contactor.phase = .closed; s.contactor.mainContactClosed=true; EEPhysicalNetworkMachine87.step(&s,coilVoltageV:24,fieldInputV:24,dt:0.001); #expect(s.motor.current.average > s.motor.ratedCurrentA); let v=s.source.terminalVoltage(for:s.motor.current); #expect(v.average < s.source.nominalLLV/sqrt(3)) }
    @Test func plcElectronicsQuantizeAndFilter() { var i=EEPLCInputElectronics87(); for _ in 0..<20 { i.sample(fieldV:24,dt:0.001) }; #expect(i.logical); #expect(i.adcCounts > 0); #expect(i.inputCurrentMA > 0) }
    @Test func nativeLoopIncludesBarrierAndWireCompliance() { var a=EEAnalogLoopTopology87(); a.commandMA=20; a.supplyV=12; a.positiveWireOhm=250; a.negativeWireOhm=250; a.barrierOhm=250; a.solve(); #expect(a.converged); #expect(a.complianceLimited); #expect(a.currentMA < 20) }
    @Test func ringBufferIsBounded() { var r=EETransientRing87(); r.capacity=8; for i in 0..<20 { r.append(.init(time:Double(i),channel:"X",value:Double(i))) }; #expect(r.samples.count == 8); #expect(r.samples.first?.value == 12) }
    @Test func firstDivergenceCarriesCausalCoordinates() { let a=[EEScopeSample86(time:0,channel:"V",value:24)], b=[EEScopeSample86(time:0,channel:"V",value:18)]; let d=EECausalReconstruction87.first(reference:a,observed:b); #expect(d?.index == 0); #expect(d?.observed == 18) }
    @Test func deterministicReplayFingerprintMatches() { var a=EEPhysicalNetworkState87(), b=EEPhysicalNetworkState87(); EEPhysicalNetworkMachine87.run(&a,duration:0.1); EEPhysicalNetworkMachine87.run(&b,duration:0.1); #expect(EEPhysicalNetworkMachine87.deterministicFingerprint(a) == EEPhysicalNetworkMachine87.deterministicFingerprint(b)) }
    @Test func adversarialPhaseLossChangesFingerprint() { var a=EEPhysicalNetworkState87(), b=EEPhysicalNetworkState87(); b.source.phaseScale.b=0; EEPhysicalNetworkMachine87.run(&a,duration:0.05); EEPhysicalNetworkMachine87.run(&b,duration:0.05); #expect(EEPhysicalNetworkMachine87.deterministicFingerprint(a) != EEPhysicalNetworkMachine87.deterministicFingerprint(b)) }
}
