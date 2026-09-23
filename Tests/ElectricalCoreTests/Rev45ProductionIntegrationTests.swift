import Foundation
import Testing
@testable import ScenarioEngine
@Suite("Rev45 production integration") struct Rev45ProductionIntegrationTests {
 @Test func shellModelKeepsWorldTruthSeparate(){let x=EEProductionIntegrationRev45();#expect(x.gas.rev39.base.unit.id != "");#expect(x.coal.world == .coalMining);#expect(x.coal.rev43.world == .coalMining)}
 @Test func goldenThreadGasIdentity(){let g=EEUniversalGoldenThread();let x=g.identity("PIT-401");#expect(x?.world == .naturalGas);#expect(x?.bindings.contains{$0.surface == .plc} == true)}
 @Test func goldenThreadCoalIdentity(){let g=EEUniversalGoldenThread();let x=g.identity("CV-NR-OL");#expect(x?.world == .coalMining);#expect(x?.bindings.contains{$0.surface == .oneLine} == true)}
 @Test func instrumentsProduceProvenancedEvidence(){var f=EEUniversalInstrumentFramework();f.record(time:1,instrument:.dmm,identity:"PIT-401",quantity:"loop current",value:12,unit:"mA");#expect(f.evidence.first?.provenance == "simulation-truth")}
 @Test func gasTimelineRecordsGasOnly(){var x=EEProductionIntegrationRev45();x.tickGas(1);#expect(x.timeline.frames.last?.world == .naturalGas);#expect(x.coal.time == 0)}
 @Test func coalTimelineRecordsCoalOnly(){var x=EEProductionIntegrationRev45();x.tickCoal(1);#expect(x.timeline.frames.last?.world == .coalMining)}
 @Test func timelineNearestRespectsWorld(){var t=EEUnifiedForensicTimeline();t.append(.init(time:1,world:.naturalGas,values:[:],events:[]));t.append(.init(time:1,world:.coalMining,values:[:],events:[]));#expect(t.nearest(1,world:.coalMining)?.world == .coalMining)}
 @Test func causalGeneratorIsDeterministic(){let g=EECausalScenarioGenerator();#expect(g.generate(world:.coalMining,seed:42) == g.generate(world:.coalMining,seed:42))}
 @Test func causalGeneratorDoesNotCrossIndustryFaultVocabulary(){let g=EECausalScenarioGenerator();let c=g.generate(world:.coalMining,seed:2);#expect(!c.rootFaults.contains(.valveDegradation));#expect(!c.rootFaults.contains(.coolingFouling))}
 @Test func rev45RoundTrip() throws {let matches=try runOnLargeStack{()->Bool in var x=EEProductionIntegrationRev45();x.tickGas(1);x.tickCoal(1);let d=try JSONEncoder().encode(x);return try JSONDecoder().decode(EEProductionIntegrationRev45.self,from:d)==x};#expect(matches)}
}
