import Foundation
import Testing
@testable import ScenarioEngine

@Suite("Rev46 playable integration") struct Rev46PlayableIntegrationTests {
 @Test func worldsRemainIndependent(){let x=EERev46PlayableIntegration();#expect(x.gas.rev39.base.living.shift.time == 0);#expect(x.coal.world == .coalMining);#expect(x.gas.rev39.base.living.shift.time != x.coal.time || x.coal.world != .naturalGas)}
 @Test func initialTimelineCapturesBothWorlds(){let x=EERev46PlayableIntegration();#expect(x.timeline.gas.count == 1);#expect(x.timeline.coal.count == 1);#expect(x.timeline.gas[0].world == .naturalGas);#expect(x.timeline.coal[0].world == .coalMining)}
 @Test func advancingGasDoesNotAdvanceCoal(){var x=EERev46PlayableIntegration();let c=x.coal.time;x.advanceGas(5);#expect(x.coal.time == c);#expect(x.timeline.gas.count == 2)}
 @Test func advancingCoalDoesNotAdvanceGas(){var x=EERev46PlayableIntegration();let g=x.gas.rev39.base.living.shift.time;x.advanceCoal(5);#expect(x.gas.rev39.base.living.shift.time == g);#expect(x.timeline.coal.count == 2)}
 @Test func gasSnapshotCarriesForensicChannels(){let x=EERev46PlayableIntegration();let ids=Set(x.timeline.gas[0].channels.map{$0.id});#expect(ids.contains("gas.dcBus"));#expect(ids.contains("gas.rodLoad"));#expect(ids.contains("gas.discharge"))}
 @Test func coalSnapshotCarriesCrossDomainChannels(){let x=EERev46PlayableIntegration();let ids=Set(x.timeline.coal[0].channels.map{$0.id});#expect(ids.contains("coal.beltAmps"));#expect(ids.contains("coal.methane"));#expect(ids.contains("coal.mediumSG"));#expect(ids.contains("coal.train"))}
 @Test func identityGraphContainsBothIndustries(){let x=EERev46PlayableIntegration();#expect(x.identities.identity("PIT-401",world:.naturalGas) != nil);#expect(x.identities.identity("CV-NR-OL",world:.coalMining) != nil);#expect(x.identities.identity("TLO-WB-1",world:.coalMining) != nil)}
 @Test func identitySearchCrossReferencesDrawings(){let x=EERev46PlayableIntegration();#expect(x.identities.related(reference:"LOADOUT_BATCH").contains{$0.id=="TLO-WB-1"})}
 @Test func instrumentEvidenceComesFromSnapshotTruth(){var x=EERev46PlayableIntegration();let s=x.timeline.gas.last!;let e=x.instruments.capture(snapshot:s,channelID:"gas.discharge");#expect(e?.provenance == "simulation-truth");#expect(e?.identity == "PIT-401");#expect(e?.value == s.channels.first{$0.id=="gas.discharge"}!.value)}
 @Test func timelineNearestNeverCrossesWorlds(){var x=EERev46PlayableIntegration();x.advanceGas(10);x.advanceCoal(20);#expect(x.timeline.nearest(time:20,world:.naturalGas)?.world == .naturalGas);#expect(x.timeline.nearest(time:10,world:.coalMining)?.world == .coalMining)}
 @Test func roundTrip(){var x=EERev46PlayableIntegration();x.advanceGas(3);x.advanceCoal(4);let d=try! JSONEncoder().encode(x);let y=try! JSONDecoder().decode(EERev46PlayableIntegration.self,from:d);#expect(y == x)}
}
