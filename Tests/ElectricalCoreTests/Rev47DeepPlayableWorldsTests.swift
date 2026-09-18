import Foundation
import Testing
@testable import ScenarioEngine
@Suite("Rev47 deep playable worlds") struct Rev47DeepPlayableWorldsTests {
 @Test func benchMeasurementUsesNodeTruth(){var x=EEElectronicsBenchRev47();x.placeRed("PS+");x.placeBlack("PS-");let e=x.measure();#expect(e?.value == 24);#expect(x.evidence.last?.provenance == "simulation-truth")}
 @Test func trainingHasAllSchools(){let x=EETrainingCenterRev47();#expect(x.lessons.count == EETrainingSchool.allCases.count)}
 @Test func trainingProgress(){var x=EETrainingCenterRev47();x.complete("TR-1");#expect(x.xp == 100);#expect(x.lessons[0].completed)}
 @Test func spatialWorldsRemainSeparated(){let x=EESpatialWorldRev47();#expect(x.assets(in:.naturalGas).allSatisfy{$0.world == .naturalGas});#expect(x.assets(in:.coalMining).allSatisfy{$0.world == .coalMining})}
 @Test func goldenThreadIncludesSpatialAssets(){let x=EERev47DeepPlayableWorlds();#expect(x.identities.identities.contains{$0.id=="COMP-2" && $0.world == .naturalGas});#expect(x.identities.identities.contains{$0.id=="TLO-WB-1" && $0.world == .coalMining})}
 @Test func evidenceBoardUpdates(){var b=EEEvidenceBoardRev47();b.ingest(.init(id:"E1",time:0,world:.coalMining,identity:"CV-NR-OL",kind:.thermal,statement:"hot idler",value:"90 C",supports:["H-MECH"],contradicts:[]));#expect(b.ranked.first?.id == "H-MECH")}
 @Test func worldInstrumentCaptureCreatesEvidence(){var x=EERev47DeepPlayableWorlds();let e=x.capture(world:.naturalGas,channelID:"gas.discharge",instrument:.dmm);#expect(e != nil);#expect(x.board.cards.count == 1)}
 @Test func coalCaptureStaysCoal(){var x=EERev47DeepPlayableWorlds();_ = x.capture(world:.coalMining,channelID:"coal.beltAmps",instrument:.clampMeter);#expect(x.board.cards.last?.world == .coalMining)}
 @Test func rev47RoundTrip() throws {let x=EERev47DeepPlayableWorlds();let d=try JSONEncoder().encode(x);let y=try JSONDecoder().decode(EERev47DeepPlayableWorlds.self,from:d);#expect(x == y)}
}
