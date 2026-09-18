import Foundation
import Testing
@testable import ScenarioEngine
@Suite("Rev48 interactive forensics") struct Rev48InteractiveForensicsTests {
 @Test func benchWiringHasContinuity(){var b=EEBenchWorkspace48();b.wire("PS1:+","R1:1");#expect(b.continuity("PS1:+","R1:1"));#expect(!b.continuity("PS1:+","R1:2"))}
 @Test func benchWireCanBeRemoved(){var b=EEBenchWorkspace48();b.wire("PS1:+","R1:1");b.removeWire("W1");#expect(!b.continuity("PS1:+","R1:1"))}
 @Test func trainingHasEightStagesPerSchool(){let t=EETrainingProgram48();#expect(t.qualifications.count == EETrainingSchool.allCases.count);#expect(t.qualifications.allSatisfy{$0.stages.count == EETrainingStage48.allCases.count})}
 @Test func trainingQualificationCompletes(){var t=EETrainingProgram48();for s in EETrainingStage48.allCases{t.pass(s,school:.fundamentals,evidence:1)};let q=t.qualifications.first{$0.school == .fundamentals};#expect(q?.complete == true);#expect(q?.evidenceCount == 8)}
 @Test func dmmRequiresTwoPoints(){var p=EEInteractiveInstrumentSystem48();#expect(!p.place(.dmm,on:"PIT-401",points:["T1"]).valid);#expect(p.place(.dmm,on:"PIT-401",points:["T1","T2"]).valid)}
 @Test func thermalCameraNeedsOneTarget(){var p=EEInteractiveInstrumentSystem48();#expect(p.place(.thermalCamera,on:"CV-NR-OL",points:["bearing-4"]).valid)}
 @Test func navigationWorldsAreSeparated(){let n=EENavigableWorld48(spatial:EESpatialWorldRev47());#expect(n.neighbors(of:"COMP-2",world:.naturalGas).contains("PIT-401"));#expect(!n.neighbors(of:"COMP-2",world:.coalMining).contains("PIT-401"))}
 @Test func coalTravelTimeExists(){let n=EENavigableWorld48(spatial:EESpatialWorldRev47());#expect(n.travelTime(from:"CPP-A-HMC",to:"TLO-WB-1",world:.coalMining) == 160)}
 @Test func plannerSuggestsDiscriminatingTests(){let p=EEDiagnosticPlanner48();let tests=p.nextTests(board:EEEvidenceBoardRev47(),world:.coalMining,asset:"CV-NR-OL");#expect(tests.contains{$0.id == "T-VDROP"});#expect(tests.contains{$0.id == "T-THERM"})}
 @Test func validPlacementCreatesEvidence(){var x=EERev48InteractiveForensics();let e=x.measure(world:.naturalGas,asset:"PIT-401",channelID:"gas.discharge",instrument:.dmm,points:["+","-"]);#expect(e != nil);#expect(x.base.board.cards.count == 1);#expect(e?.provenance == "simulation-truth")}
 @Test func invalidPlacementCannotCreateEvidence(){var x=EERev48InteractiveForensics();let e=x.measure(world:.naturalGas,asset:"PIT-401",channelID:"gas.discharge",instrument:.dmm,points:["+"]);#expect(e == nil);#expect(x.base.board.cards.isEmpty)}
 @Test func rev48RoundTrip() throws {let x=EERev48InteractiveForensics();let d=try JSONEncoder().encode(x);let y=try JSONDecoder().decode(EERev48InteractiveForensics.self,from:d);#expect(x == y)}
}
