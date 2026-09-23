import Foundation
import Testing
@testable import ScenarioEngine

@Suite("Rev50 physicalized forensics") struct Rev50PhysicalizedForensicsTests {
 @Test func facilityGeometryPreservesWorldBoundary(){let m=EERev50PhysicalizedForensics();#expect(m.geometry.paths.allSatisfy{$0.world == .naturalGas || $0.world == .coalMining});#expect(m.geometry.path(from:"COMP-2",to:"CV-NR-OL",world:.naturalGas) == nil)}
 @Test func undergroundPathGetsTravelMode(){let m=EERev50PhysicalizedForensics();#expect(m.geometry.paths.contains{$0.world == .coalMining && $0.mode == .mineRide})}
 @Test func cabinetPointRequiresAccess(){var m=EERev50PhysicalizedForensics();let denied=m.place(instrument:.dmm,role:.red,pointID:"VFD2-DC");#expect(!denied);m.openAccess(for:"VFD-2");let allowed=m.place(instrument:.dmm,role:.red,pointID:"VFD2-DC");#expect(allowed)}
 @Test func dmmRequiresBothProbes(){var m=EERev50PhysicalizedForensics();m.openAccess(for:"VFD-2");let r=m.place(instrument:.dmm,role:.red,pointID:"VFD2-DC");#expect(r);let first=m.measure(world:.naturalGas,asset:"VFD-2",pointID:"VFD2-DC",instrument:.dmm);#expect(first == nil);let b=m.place(instrument:.dmm,role:.black,pointID:"VFD2-L1");#expect(b);let second=m.measure(world:.naturalGas,asset:"VFD-2",pointID:"VFD2-DC",instrument:.dmm);#expect(second != nil)}
 @Test func clampUsesConductorPlacement(){var m=EERev50PhysicalizedForensics();let p=m.place(instrument:.clampMeter,role:.clamp,pointID:"CVNR-MTR");#expect(p);let e=m.measure(world:.coalMining,asset:"CV-NR-OL",pointID:"CVNR-MTR",instrument:.clampMeter);#expect(e != nil)}
 @Test func thermalUsesSurfaceSensor(){var m=EERev50PhysicalizedForensics();let p=m.place(instrument:.thermalCamera,role:.sensor,pointID:"CVNR-IDLER");#expect(p);let e=m.measure(world:.coalMining,asset:"CV-NR-OL",pointID:"CVNR-IDLER",instrument:.thermalCamera);#expect(e != nil)}
 @Test func overlayStaysInWorld(){let m=EERev50PhysicalizedForensics();let t=m.base.base.base.base.timeline.gas.last?.time ?? 0;#expect(m.overlay(world:.naturalGas,time:t)?.world == .naturalGas)}
 @Test func bayesUpdatesHypothesis(){var m=EERev50PhysicalizedForensics();let c=EEEvidenceCard47(id:"E-X",time:0,world:.coalMining,identity:"CV-NR-OL",kind:.thermal,statement:"localized hot idler",value:"95 C",supports:[],contradicts:[]);m.base.base.base.board.ingest(c);let before=m.base.base.base.board.hypotheses.first{$0.id=="H-MECH"}!.probability;let applied=m.applyLikelihoods(to:"E-X",values:[.init(hypothesisID:"H-MECH",ifTrue:4,ifFalse:0.25)]);#expect(applied);let after=m.base.base.base.board.hypotheses.first{$0.id=="H-MECH"}!.probability;#expect(after > before)}
 @Test func benchShortHasConsequences(){var b=EEPhysicalBench50();b.base.workspace.wire("PS1:+","PS1:-");b.energize(seconds:0.1);#expect(b.lastConsequences.contains(.supplyStressed));#expect(b.lastConsequences.contains(.breakerTripped))}
 @Test func goldenThreadStillContainsPhysicalPoints(){let m=EERev50PhysicalizedForensics();#expect(!m.base.golden.related("CVNR-IDLER").isEmpty)}
 @Test func roundTrip() throws {let matches=try runOnLargeStack{()->Bool in let m=EERev50PhysicalizedForensics();let d=try JSONEncoder().encode(m);let r=try JSONDecoder().decode(EERev50PhysicalizedForensics.self,from:d);return r.geometry.paths.count == m.geometry.paths.count};#expect(matches)}
}
