import Testing
import Foundation
@testable import ScenarioEngine

@Suite("Rev49 deep integration") struct Rev49DeepIntegrationTests {
 @Test func travelConsumesPersistentWorldTime(){var m=EERev49DeepIntegration();let g=m.base.base.base.gas.rev39.base.living.shift.time;let moved=m.travel(to:"VFD-2",world:.naturalGas);#expect(moved);#expect(m.shiftTime[.naturalGas] == 55);#expect(m.base.base.base.gas.rev39.base.living.shift.time > g)}
 @Test func travelCannotCrossWorlds(){var m=EERev49DeepIntegration();let moved=m.travel(to:"COMP-2",world:.coalMining);#expect(!moved);#expect(m.currentAsset[.coalMining] == "LW-NR")}
 @Test func atlasHasHierarchyAndElevation(){let m=EERev49DeepIntegration();let a=m.atlas.asset("LW-NR",world:.coalMining);#expect(a?.address.level == "Longwall District");#expect((a?.address.elevationM ?? 0) < 0)}
 @Test func testPointsRejectWrongInstrument(){let r=EETestPointRegistry49();let p=r.points.first{$0.id=="CVNR-MTR"}!;#expect(r.accepts(.clampMeter,point:p));#expect(!r.accepts(.thermalCamera,point:p))}
 @Test func measurementLinksEvidenceToTimeline(){var m=EERev49DeepIntegration();let e=m.measure(world:.coalMining,asset:"CV-NR-OL",pointID:"CVNR-MTR",instrument:.clampMeter);#expect(e != nil);let id=m.base.base.board.cards.last!.id;let replay=m.replay(forEvidence:id);#expect(replay?.0.assetID == "CV-NR-OL");#expect(replay?.1.world == .coalMining)}
 @Test func informationGainRanksTests(){let m=EERev49DeepIntegration();let ranked=m.rankedTests(world:.coalMining,asset:"CV-NR-OL");#expect(!ranked.isEmpty);#expect(ranked.allSatisfy{$0.expectedBits > 0})}
 @Test func goldenThreadIncludesTestPointsAndSpatialHierarchy(){let m=EERev49DeepIntegration();let hits=m.golden.related("CVNR-IDLER");#expect(hits.contains{$0.id=="CV-NR-OL"});#expect(m.golden.related("Dense Medium Floor").contains{$0.id=="CPP-A-HMC"})}
 @Test func benchShortTripsProtection(){var b=EEDeepBench49();b.workspace.wire("PS1:+","PS1:-");b.energize(seconds:0.1);#expect(b.protection.state == .breakerTripped);#expect(!b.workspace.energized)}
 @Test func benchNormalLoadStaysHealthy(){var b=EEDeepBench49();b.workspace.wire("PS1:+","R1:1");b.workspace.wire("R1:2","PS1:-");b.energize(seconds:1);#expect(b.protection.state == .healthy);#expect(b.workspace.energized)}
 @Test func gasAndCoalTimeRemainIndependent(){var m=EERev49DeepIntegration();let moved=m.travel(to:"VFD-2",world:.naturalGas);#expect(moved);#expect(m.shiftTime[.coalMining] == 0)}
 @Test func roundTrip() throws {let matches=try runOnLargeStack{()->Bool in let m=EERev49DeepIntegration();let d=try JSONEncoder().encode(m);return try JSONDecoder().decode(EERev49DeepIntegration.self,from:d)==m};#expect(matches)}
}
