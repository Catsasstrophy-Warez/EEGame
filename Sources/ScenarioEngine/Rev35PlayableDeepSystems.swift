import Foundation

// Rev35 — Playable Deep Systems
// Converts Rev33/34 competitive patterns into deterministic gameplay systems.

public struct EEElectricalVisionSample: Codable, Sendable, Hashable {
    public var identity:String; public var volts:Double; public var amps:Double; public var temperatureC:Double; public var quality:Double; public var energized:Bool
    public var watts:Double { volts * amps }
}
public struct EEElectricalVisionFrame: Codable, Sendable {
    public var time:Double; public var samples:[EEElectricalVisionSample]
    public func sample(_ id:String)->EEElectricalVisionSample? { samples.first{$0.identity == id} }
}

public enum EEProbeJack:String,Codable,Sendable,CaseIterable { case common="COM", voltsOhms="VΩ", milliamp="mA", amps="A" }
public enum EEMeterFunction:String,Codable,Sendable,CaseIterable { case dcVolts, acVolts, resistance, continuity, dcMilliamps, dcAmps }
public struct EEProbePlacement:Codable,Sendable,Hashable { public var red:String?; public var black:String?; public init(red:String?=nil,black:String?=nil){self.red=red;self.black=black} }
public enum EEMeterSafetyResult:String,Codable,Sendable { case valid, openLead, wrongJack, resistanceOnEnergizedCircuit, blownFuse }
public struct EEPhysicalDMM:Codable,Sendable {
    public var function:EEMeterFunction = .dcVolts; public var redJack:EEProbeJack = .voltsOhms; public var blackJack:EEProbeJack = .common; public var placement=EEProbePlacement(); public var currentFuseHealthy=true
    public init(){}
    public func validate(energized:Bool)->EEMeterSafetyResult {
        guard placement.red != nil && placement.black != nil else { return .openLead }
        if function == .resistance || function == .continuity { return energized ? .resistanceOnEnergizedCircuit : .valid }
        if function == .dcMilliamps || function == .dcAmps {
            guard currentFuseHealthy else { return .blownFuse }
            return (redJack == .milliamp || redJack == .amps) ? .valid : .wrongJack
        }
        return redJack == .voltsOhms ? .valid : .wrongJack
    }
}

public struct EEWavePoint:Codable,Sendable,Hashable { public var t:Double; public var value:Double }
public struct EEOscilloscopeChannel:Codable,Sendable,Hashable { public var name:String; public var unit:String; public var scale:Double; public var points:[EEWavePoint] }
public struct EEOscilloscopeCapture:Codable,Sendable { public var triggerLevel:Double; public var timebaseSeconds:Double; public var channels:[EEOscilloscopeChannel] }

public struct EEThermalPixel:Codable,Sendable,Hashable { public var x:Int; public var y:Int; public var celsius:Double; public var identity:String? }
public struct EEThermalFrame:Codable,Sendable { public var width:Int; public var height:Int; public var pixels:[EEThermalPixel]; public var hottest:EEThermalPixel? { pixels.max{$0.celsius < $1.celsius} } }

public struct EELadderContact:Codable,Sendable,Hashable { public var tag:String; public var normallyClosed:Bool; public var state:Bool; public var identity:String }
public struct EELadderRung:Codable,Sendable,Hashable { public var number:Int; public var contacts:[EELadderContact]; public var outputTag:String; public var outputIdentity:String; public var energized:Bool }
public struct EELiveLadder:Codable,Sendable { public var rungs:[EELadderRung]; public func crossReference(_ tag:String)->[Int] { rungs.filter{$0.outputTag == tag || $0.contacts.contains{$0.tag == tag}}.map(\.number) } }

public struct EEInteractiveSchematicNode:Codable,Sendable,Hashable { public var identity:String; public var label:String; public var x:Double; public var y:Double }
public struct EEInteractiveSchematicEdge:Codable,Sendable,Hashable { public var from:String; public var to:String; public var conductor:String; public var energized:Bool }
public struct EEInteractiveSchematic:Codable,Sendable { public var nodes:[EEInteractiveSchematicNode]; public var edges:[EEInteractiveSchematicEdge]; public func neighbors(of id:String)->[String] { edges.flatMap{ e in e.from == id ? [e.to] : (e.to == id ? [e.from] : []) } } }

public enum EEMasteryState:String,Codable,Sendable,CaseIterable { case locked, available, learning, practiced, mastered }
public struct EESkillNode:Codable,Sendable,Hashable { public var id:String; public var title:String; public var prerequisites:[String]; public var state:EEMasteryState; public init(id:String,title:String,prerequisites:[String],state:EEMasteryState){self.id=id;self.title=title;self.prerequisites=prerequisites;self.state=state} }
public struct EESkillGraph:Codable,Sendable {
    public var nodes:[EESkillNode]; public init(nodes:[EESkillNode]){self.nodes=nodes}
    public mutating func refreshUnlocks(){ let mastered=Set(nodes.filter{$0.state == .mastered}.map(\.id)); for i in nodes.indices where nodes[i].state == .locked && Set(nodes[i].prerequisites).isSubset(of:mastered){nodes[i].state = .available} }
}

public struct EEMotorAcademyExercise:Codable,Sendable,Hashable { public var lesson:EEMotorLesson; public var objective:String; public var buildIdentities:[String]; public var faultPool:[String]; public var proof:[String] }
public struct EEMotorAcademyCurriculum:Codable,Sendable {
    public init(){}; public var exercises:[EEMotorAcademyExercise] = EEMotorLesson.allCases.map{ lesson in .init(lesson:lesson,objective:"Build, explain, commission, and diagnose \(lesson.rawValue)",buildIdentities:["L1","CONTROL","K1","M1"],faultPool:["open conductor","loose termination","failed contact","misconfiguration"],proof:["visual inspection","electrical measurement","functional test"]) }
}

public struct EETechnicalSearchHit:Codable,Sendable,Hashable { public var documentID:String; public var kind:EEDocumentKind; public var identity:String; public var relevance:Int }
public struct EEIdentityDocumentIndex:Codable,Sendable {
    public var documents:[EETechnicalDocument]; public init(documents:[EETechnicalDocument]){self.documents=documents}
    public func search(_ term:String)->[EETechnicalSearchHit]{ let q=term.lowercased(); return documents.compactMap{ d in let identityMatch=d.identities.contains{$0.lowercased().contains(q)}; let titleMatch=d.title.lowercased().contains(q); guard identityMatch || titleMatch else{return nil}; return .init(documentID:d.id,kind:d.kind,identity:d.identities.first(where:{$0.lowercased().contains(q)}) ?? d.identities.first ?? "",relevance:identityMatch ? 100:60)}.sorted{$0.relevance > $1.relevance} }
}

public enum EEHistorianEventKind:String,Codable,Sendable,CaseIterable { case analog, digital, alarm, operatorAction, maintenance, configuration, trip }
public struct EEHistorianEvent:Codable,Sendable,Hashable { public var t:Double; public var kind:EEHistorianEventKind; public var identity:String; public var value:String; public var sequence:Int }
public struct EEForensicTimeline:Codable,Sendable { public var events:[EEHistorianEvent]=[]; public init(){}; public mutating func append(t:Double,kind:EEHistorianEventKind,identity:String,value:String){events.append(.init(t:t,kind:kind,identity:identity,value:value,sequence:events.count+1));events.sort{$0.t == $1.t ? $0.sequence < $1.sequence:$0.t < $1.t}}; public func window(_ a:Double,_ b:Double)->[EEHistorianEvent]{events.filter{$0.t >= a && $0.t <= b}} }

public struct EEInstructorScenario:Codable,Sendable,Hashable { public var id:String; public var title:String; public var symptom:String; public var hiddenFaults:[String]; public var allowedTools:Set<EEInstrumentKind>; public var documents:Set<EEDocumentKind>; public var guidance:EEGuidanceLevel; public var successEvidence:[String] }
public struct EEInstructorScenarioEditor:Codable,Sendable { public init(){}; public var draft=EEInstructorScenario(id:"NEW",title:"Untitled Case",symptom:"",hiddenFaults:[],allowedTools:Set(EEInstrumentKind.allCases),documents:Set(EEDocumentKind.allCases),guidance:.guided,successEvidence:[]); public mutating func hideFault(_ id:String){if !draft.hiddenFaults.contains(id){draft.hiddenFaults.append(id)}} }

public enum EEBenchPart:String,Codable,Sendable,CaseIterable { case resistor, capacitor, diode, led, transistor, relay, switchDevice, potentiometer, opAmp, logicGate, microcontroller, canTransceiver }
public struct EEElectronicsWorkbench:Codable,Sendable { public init(){}; public var parts:[EEBenchPart]=[]; public var supplyVolts:Double=0; public var outputEnabled=false; public mutating func place(_ p:EEBenchPart){parts.append(p)}; public var energized:Bool{outputEnabled && supplyVolts > 0} }

public struct EENetworkPacket:Codable,Sendable,Hashable { public var t:Double; public var protocolName:String; public var source:String; public var destination:String; public var identifier:String; public var payload:[UInt8]; public var valid:Bool; public init(t:Double,protocolName:String,source:String,destination:String,identifier:String,payload:[UInt8],valid:Bool){self.t=t;self.protocolName=protocolName;self.source=source;self.destination=destination;self.identifier=identifier;self.payload=payload;self.valid=valid} }
public struct EEPacketAnalyzer:Codable,Sendable { public init(){}; public var packets:[EENetworkPacket]=[]; public func filtered(protocolName:String?=nil,identifier:String?=nil)->[EENetworkPacket]{packets.filter{p in (protocolName == nil || p.protocolName == protocolName!) && (identifier == nil || p.identifier == identifier!)}} }

public enum EEIntegratedCaseState:String,Codable,Sendable { case assigned, investigating, isolated, repaired, recommissioning, verified, closed }
public struct EEIntegratedWorkOrderCase:Codable,Sendable {
    public var id="WO-401"; public var state:EEIntegratedCaseState = .assigned; public var plant=Rev32LivePlant(); public var journey=EEWorkOrderJourney(); public var timeline=EEForensicTimeline(); public var meter=EEPhysicalDMM(); public var proof=EEProofOfRepair(symptomCleared:false,rootCauseCorrected:false,gates:[])
    public init(){}
    public mutating func accept(){state = .investigating; journey.complete(.briefing); timeline.append(t:0,kind:.operatorAction,identity:id,value:"accepted")}
    public mutating func isolate(){plant.perform(.openDisconnect); state = .isolated; journey.complete(.isolation); timeline.append(t:10,kind:.digital,identity:"DISC-401",value:"OPEN")}
    public mutating func repair(){plant.perform(.repairTermination); state = .repaired; journey.complete(.repair); proof.rootCauseCorrected=true; timeline.append(t:20,kind:.maintenance,identity:"DISC-401",value:"termination repaired")}
    public mutating func recommission(){plant.perform(.closeDisconnect); state = .recommissioning; journey.complete(.calibration); journey.complete(.functionalTest); timeline.append(t:30,kind:.operatorAction,identity:"PIT-401",value:"loop/function checked")}
    public mutating func verify(){proof.symptomCleared = plant.firstDivergence == nil; proof.gates=[.init(id:"loop",title:"Loop restored",passed:proof.symptomCleared,evidenceIDs:["DISC-401"]),.init(id:"process",title:"Process indication verified",passed:abs(plant.plcPSI-plant.processPSI)<1,evidenceIDs:["PIT401_PV"])]; if proof.readyToClose {state = .verified; journey.complete(.proofOfRepair)} }
    public mutating func close(){if state == .verified {state = .closed; journey.complete(.documentation); journey.complete(.closeout); timeline.append(t:40,kind:.operatorAction,identity:id,value:"closed")}}
}

public struct Rev35PlayableDeepRuntime:Codable,Sendable {
    public var visionFrame=EEElectricalVisionFrame(time:0,samples:[.init(identity:"PIT-401",volts:24,amps:0.012,temperatureC:31,quality:1,energized:true),.init(identity:"DISC-401",volts:24,amps:0.00874,temperatureC:58,quality:0.55,energized:true)])
    public var dmm=EEPhysicalDMM()
    public var scope=EEOscilloscopeCapture(triggerLevel:12,timebaseSeconds:1,channels:[.init(name:"Loop current",unit:"mA",scale:4,points:(0..<60).map{.init(t:Double($0)/10,value:12 + sin(Double($0)/5)*0.15)})])
    public var thermal=EEThermalFrame(width:4,height:3,pixels:(0..<12).map{.init(x:$0%4,y:$0/4,celsius:$0==6 ? 58:30+Double($0%3),identity:$0==6 ? "DISC-401":nil)})
    public var ladder=EELiveLadder(rungs:[.init(number:1,contacts:[.init(tag:"START",normallyClosed:false,state:true,identity:"PB-START"),.init(tag:"STOP",normallyClosed:true,state:true,identity:"PB-STOP")],outputTag:"MOTOR_RUN",outputIdentity:"K1",energized:true),.init(number:2,contacts:[.init(tag:"PIT401_OK",normallyClosed:false,state:false,identity:"PIT401_PV")],outputTag:"DISCH_OK",outputIdentity:"PLC:DISCH_OK",energized:false)])
    public var schematic=EEInteractiveSchematic(nodes:[.init(identity:"PIT-401",label:"PIT-401",x:0,y:0),.init(identity:"JB-4:12",label:"JB",x:1,y:0),.init(identity:"DISC-401",label:"DISC",x:2,y:0),.init(identity:"ISO-17",label:"ISO",x:3,y:0),.init(identity:"MX5-AI3",label:"AI3",x:4,y:0)],edges:[.init(from:"PIT-401",to:"JB-4:12",conductor:"401+",energized:true),.init(from:"JB-4:12",to:"DISC-401",conductor:"401+",energized:true),.init(from:"DISC-401",to:"ISO-17",conductor:"401+",energized:true),.init(from:"ISO-17",to:"MX5-AI3",conductor:"401+",energized:true)])
    public var motorAcademy=EEMotorAcademyCurriculum(); public var instructor=EEInstructorScenarioEditor(); public var electronics=EEElectronicsWorkbench(); public var packets=EEPacketAnalyzer(); public var workOrder=EEIntegratedWorkOrderCase()
    public init(){}
}
