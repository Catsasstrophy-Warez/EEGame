import Foundation

// Rev48 turns Rev47's playable surfaces into connected diagnostic workflows.
public enum EEBenchComponentKind48:String,Sendable,Codable,CaseIterable { case supply, resistor, lamp, switchDevice, relayCoil, relayContact, capacitor, diode, motor, transmitter, analogInput, plcOutput, vfd, networkNode, canTermination }
public struct EEBenchComponent48:Identifiable,Sendable,Codable,Equatable { public var id:String; public var kind:EEBenchComponentKind48; public var terminals:[String]; public var value:Double; public var enabled:Bool=true }
public struct EEBenchWire48:Identifiable,Sendable,Codable,Equatable { public var id:String; public var from:String; public var to:String; public var resistanceOhm:Double; public var healthy:Bool=true }
public struct EEBenchWorkspace48:Sendable,Codable,Equatable {
 public var components:[EEBenchComponent48]=[]; public var wires:[EEBenchWire48]=[]; public var energized=false
 public init(){components=[.init(id:"PS1",kind:.supply,terminals:["PS1:+","PS1:-"],value:24),.init(id:"R1",kind:.resistor,terminals:["R1:1","R1:2"],value:240),.init(id:"L1",kind:.lamp,terminals:["L1:1","L1:2"],value:10)]}
 public mutating func wire(_ from:String,_ to:String,resistanceOhm:Double=0.02){wires.append(.init(id:"W\(wires.count+1)",from:from,to:to,resistanceOhm:resistanceOhm))}
 public mutating func removeWire(_ id:String){wires.removeAll{$0.id==id}}
 public func terminalExists(_ id:String)->Bool{components.contains{$0.terminals.contains(id)}}
 public func continuity(_ a:String,_ b:String)->Bool{guard terminalExists(a),terminalExists(b) else{return false};var seen:Set<String>=[a];var frontier=[a];while let n=frontier.popLast(){if n==b{return true};for w in wires where w.healthy && (w.from==n || w.to==n){let next=w.from==n ? w.to:w.from;if seen.insert(next).inserted{frontier.append(next)}}};return false}
}

public enum EETrainingStage48:String,Sendable,Codable,CaseIterable { case observe, demonstrate, build, measure, commission, diagnose, repair, prove }
public struct EETrainingQualification48:Identifiable,Sendable,Codable,Equatable { public var id:String; public var school:EETrainingSchool; public var stages:[EETrainingStage48:Bool]; public var unsafeActions=0; public var evidenceCount=0; public init(school:EETrainingSchool){id="Q-\(school.rawValue)";self.school=school;stages=Dictionary(uniqueKeysWithValues:EETrainingStage48.allCases.map{($0,false)})}; public var complete:Bool{stages.values.allSatisfy{$0}} }
public struct EETrainingProgram48:Sendable,Codable,Equatable { public var qualifications:[EETrainingQualification48]=EETrainingSchool.allCases.map{.init(school:$0)}; public mutating func pass(_ stage:EETrainingStage48,school:EETrainingSchool,evidence:Int=0){guard let i=qualifications.firstIndex(where:{$0.school==school}) else{return};qualifications[i].stages[stage]=true;qualifications[i].evidenceCount += evidence} }

public enum EEPlacementRule48:String,Sendable,Codable,CaseIterable { case twoPointElectrical, aroundConductor, surfaceThermal, vibrationMount, processPort, communicationPort, nonContact }
public struct EEInstrumentPlacement48:Sendable,Codable,Equatable { public var instrument:EEInstrumentKind; public var assetID:String; public var rule:EEPlacementRule48; public var points:[String]; public var valid:Bool; public var reason:String }
public struct EEInteractiveInstrumentSystem48:Sendable,Codable,Equatable {
 public var placements:[EEInstrumentPlacement48]=[]
 public init(){}
 public func rule(for instrument:EEInstrumentKind)->EEPlacementRule48 { switch instrument {case .dmm,.insulationTester,.phaseRotationMeter,.loopCalibrator,.processCalibrator,.hartCommunicator,.oscilloscope,.pressureCalibrator,.temperatureSimulator:.twoPointElectrical;case .clampMeter,.milliampClamp:.aroundConductor;case .thermalCamera:.surfaceThermal;case .vibrationAnalyzer,.tachometer:.vibrationMount;case .networkAnalyzer,.canAnalyzer:.communicationPort} }
 public mutating func place(_ instrument:EEInstrumentKind,on asset:String,points:[String])->EEInstrumentPlacement48 {let r=rule(for:instrument);let required=(r == .twoPointElectrical ? 2:1);let valid=points.count>=required;let p=EEInstrumentPlacement48(instrument:instrument,assetID:asset,rule:r,points:points,valid:valid,reason:valid ? "placement-valid":"requires \(required) placement point(s)");placements.append(p);return p}
}

public struct EESpatialConnection48:Identifiable,Sendable,Codable,Equatable { public var id:String; public var world:EEIndustrialWorld; public var from:String; public var to:String; public var travelSeconds:Double; public var relation:String }
public struct EENavigableWorld48:Sendable,Codable,Equatable {
 public var locations:EESpatialWorldRev47; public var connections:[EESpatialConnection48]
 public init(spatial:EESpatialWorldRev47){locations=spatial;connections=[
  .init(id:"G1",world:.naturalGas,from:"SEP-101",to:"VFD-2",travelSeconds:55,relation:"inlet to MCC"),.init(id:"G2",world:.naturalGas,from:"VFD-2",to:"COMP-2",travelSeconds:35,relation:"MCC to compressor"),.init(id:"G3",world:.naturalGas,from:"COMP-2",to:"ASV-401",travelSeconds:25,relation:"compressor to recycle"),.init(id:"G4",world:.naturalGas,from:"COMP-2",to:"PIT-401",travelSeconds:20,relation:"compressor to discharge"),.init(id:"G5",world:.naturalGas,from:"PIT-401",to:"DEHY-1",travelSeconds:70,relation:"discharge to dehydration"),
  .init(id:"C1",world:.coalMining,from:"LW-NR",to:"CV-NR-OL",travelSeconds:240,relation:"longwall to haulage"),.init(id:"C2",world:.coalMining,from:"CV-NR-OL",to:"ROM-NR-1",travelSeconds:180,relation:"overland to ROM"),.init(id:"C3",world:.coalMining,from:"ROM-NR-1",to:"CPP-A-HMC",travelSeconds:95,relation:"ROM to CPP"),.init(id:"C4",world:.coalMining,from:"CPP-A-HMC",to:"THK-101",travelSeconds:75,relation:"CPP to water/refuse"),.init(id:"C5",world:.coalMining,from:"CPP-A-HMC",to:"TLO-WB-1",travelSeconds:160,relation:"clean coal to loadout") ]}
 public func neighbors(of id:String,world:EEIndustrialWorld)->[String]{connections.filter{$0.world==world && ($0.from==id || $0.to==id)}.map{$0.from==id ? $0.to:$0.from}}
 public func travelTime(from:String,to:String,world:EEIndustrialWorld)->Double?{connections.first{$0.world==world && (($0.from==from && $0.to==to)||($0.from==to && $0.to==from))}?.travelSeconds}
}

public struct EEDiagnosticTest48:Identifiable,Sendable,Codable,Equatable { public var id:String; public var title:String; public var instrument:EEInstrumentKind; public var target:String; public var discriminates:[String]; public var rationale:String }
public struct EEDiagnosticPlanner48:Sendable,Codable,Equatable {
 public init(){}
 public func nextTests(board:EEEvidenceBoardRev47,world:EEIndustrialWorld,asset:String)->[EEDiagnosticTest48]{let top=Array(board.ranked.prefix(3)).map{$0.id};var tests:[EEDiagnosticTest48]=[];if top.contains("H-WIRING") || board.cards.isEmpty {tests.append(.init(id:"T-VDROP",title:"Measure loaded voltage drop",instrument:.dmm,target:asset,discriminates:["H-WIRING","H-MECH"],rationale:"Separates connection loss from a load-side mechanical demand."))};if top.contains("H-MECH") || board.cards.isEmpty {tests.append(.init(id:"T-THERM",title:"Compare thermal pattern",instrument:.thermalCamera,target:asset,discriminates:["H-MECH","H-WIRING"],rationale:"Looks for localized friction or resistive heating."))};if top.contains("H-INST") {tests.append(.init(id:"T-LOOP",title:"Verify field signal against PLC value",instrument:.processCalibrator,target:asset,discriminates:["H-INST","H-CTRL"],rationale:"Finds the first divergence in the measurement chain."))};if top.contains("H-CTRL") {tests.append(.init(id:"T-NET",title:"Inspect communications path",instrument:.networkAnalyzer,target:asset,discriminates:["H-CTRL"],rationale:"Checks latency, loss and stale-data evidence."))};return tests}
}

public struct EERev48InteractiveForensics:Sendable,Codable,Equatable {
 public var base=EERev47DeepPlayableWorlds(); public var bench=EEBenchWorkspace48(); public var training=EETrainingProgram48(); public var placement=EEInteractiveInstrumentSystem48(); public var navigation:EENavigableWorld48; public var selectedAsset:String?; public var selectedWorld:EEIndustrialWorld = .naturalGas
 public init(){let b=EERev47DeepPlayableWorlds();base=b;navigation = .init(spatial:b.spatial)}
 public var identities:EEIdentityGraphRev47{base.identities}
 public var planner:EEDiagnosticPlanner48{.init()}
 public mutating func travel(to asset:String){selectedAsset=asset;base.spatial.selectedID=asset}
 public mutating func measure(world:EEIndustrialWorld,asset:String,channelID:String,instrument:EEInstrumentKind,points:[String])->EEInstrumentEvidence?{let p=placement.place(instrument,on:asset,points:points);guard p.valid else{return nil};return base.capture(world:world,channelID:channelID,instrument:instrument)}
}
