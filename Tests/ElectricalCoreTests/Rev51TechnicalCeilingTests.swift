import Foundation
import Testing
@testable import ScenarioEngine

@Suite("Rev51 technical ceiling") struct Rev51TechnicalCeilingTests {
 @Test func mnaBenchSolvesFreeformLoad(){var m=EECircuitMNABench51();let a=m.wire("PS1:+","R1:1");let b=m.wire("R1:2","PS1:-");#expect(a);#expect(b);m.energize();let r=m.solve();#expect(r.state == .solved);#expect(abs((m.measure(red:"PS1:+",black:"PS1:-") ?? 0)-24)<0.01);#expect(r.sourceCurrentsA.count==1)}
 @Test func mnaBenchSupportsArbitraryComponent(){var m=EECircuitMNABench51();let a=m.add(id:"R2",kind:.resistor,terminals:["R2:1","R2:2"],value:120);let b=m.wire("PS1:+","R2:1");let c=m.wire("R2:2","PS1:-");#expect(a);#expect(b);#expect(c);m.energize();let r=m.solve();#expect(r.state == .solved);#expect(abs(r.sourceCurrentsA[0]) > 0.19)}
 @Test func openBenchReportsZeroCurrentButRealVoltage(){var m=EECircuitMNABench51();m.energize();let r=m.solve();#expect(r.state == .solved);#expect(abs(r.sourceCurrentsA[0]) < 0.000001);#expect(abs((m.measure(red:"PS1:+",black:"PS1:-") ?? 0)-24)<0.01)}
 @Test func switchCanChangeTopology(){var m=EECircuitMNABench51();let a=m.add(id:"S1",kind:.switchDevice,terminals:["S1:1","S1:2"],value:0);let b=m.wire("PS1:+","S1:1");let c=m.wire("S1:2","R1:1");let d=m.wire("R1:2","PS1:-");#expect(a);#expect(b);#expect(c);#expect(d);m.setEnabled("S1",false);m.energize();let open=m.solve();#expect(open.state == .solved);#expect(abs(open.sourceCurrentsA[0]) < 0.000001);m.setEnabled("S1",true);let closed=m.solve();#expect(closed.state == .solved);#expect(abs(closed.sourceCurrentsA[0]) > 0.09)}
 @Test func goldenHasNoDuplicateKeys(){let m=EERev51TechnicalCeiling();#expect(m.golden.audit.duplicateKeys.isEmpty)}
 @Test func goldenIncludesTimelineOnlySources(){let m=EERev51TechnicalCeiling();#expect(m.golden.identity("MTR-2",world:.naturalGas) != nil);#expect(m.golden.identity("RET-ATM-1",world:.coalMining) != nil)}
 @Test func goldenAddsHistorianBindings(){let m=EERev51TechnicalCeiling();let i=m.golden.identity("PIT-401",world:.naturalGas);#expect(i?.bindings.contains{$0.surface == .historian && $0.reference == "gas.discharge"} == true)}
 @Test func replayStartsSynchronized(){let m=EERev51TechnicalCeiling();#expect(m.replay.gas.count==1);#expect(m.replay.coal.count==1);#expect(m.replay.gas[0].plc.scan==1);#expect(!m.replay.gas[0].network.isEmpty);#expect(!m.replay.coal[0].thermal.isEmpty)}
 @Test func advancingGasDoesNotAdvanceCoalReplay(){var m=EERev51TechnicalCeiling();let c=m.replay.coal.last!.time;m.advance(.naturalGas,seconds:1);#expect(m.replay.gas.count==2);#expect(m.replay.coal.last!.time==c)}
 @Test func replayCarriesVibrationOrders(){let m=EERev51TechnicalCeiling();#expect(m.replay.gas[0].vibration.first?.orders[1] != nil);#expect(m.replay.coal[0].vibration.contains{$0.asset=="CENT-101"})}
 @Test func replayCarriesPLCTruthChannels(){let m=EERev51TechnicalCeiling();#expect(m.replay.gas[0].plc.tags["gas.discharge"] != nil);#expect(m.replay.coal[0].plc.tags["coal.mediumSG"] != nil)}
 @Test func nearestReplayIsWorldSpecific(){var m=EERev51TechnicalCeiling();m.advance(.naturalGas,seconds:2);let f=m.frame(world:.naturalGas,time:m.replay.gas.last!.time);#expect(f?.world == .naturalGas);#expect(m.frame(world:.coalMining,time:m.replay.gas.last!.time)?.world == .coalMining)}
 @Test func roundTrip() throws {let m=EERev51TechnicalCeiling();let d=try JSONEncoder().encode(m);let r=try JSONDecoder().decode(EERev51TechnicalCeiling.self,from:d);#expect(r.replay.gas.count==m.replay.gas.count);#expect(r.golden.audit.total==m.golden.audit.total)}
}
