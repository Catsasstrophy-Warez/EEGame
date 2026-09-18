import Foundation

// Rev28 — industrial component library, commissioning sheets, hidden workmanship defects,
// and vendor-aware terminal maps. Educational simulation only; manufacturer instructions govern real work.

public enum IndustrialComponentKind: String, Sendable, Codable, CaseIterable {
    case terminal, fuseTerminal, disconnectTerminal, relay, contactor, overload, breaker, powerSupply, plc, remoteIO, signalConditioner, barrier, network, transmitter, positioner, burnerController
}
public struct ComponentFootprint: Sendable, Codable, Hashable { public var widthMM:Double; public var heightMM:Double; public var depthMM:Double; public init(_ w:Double,_ h:Double,_ d:Double){widthMM=w;heightMM=h;depthMM=d} }
public struct ComponentDefinition: Sendable, Codable, Hashable {
    public var id:String; public var kind:IndustrialComponentKind; public var footprint:ComponentFootprint; public var heatWatts:Double; public var terminals:[TerminalDefinition]; public var notes:[String]
    public init(id:String,kind:IndustrialComponentKind,footprint:ComponentFootprint,heatWatts:Double=0,terminals:[TerminalDefinition]=[],notes:[String]=[]){self.id=id;self.kind=kind;self.footprint=footprint;self.heatWatts=heatWatts;self.terminals=terminals;self.notes=notes}
}
public enum IndustrialComponentLibrary {
    public static let feedThrough = ComponentDefinition(id:"TB-FEED",kind:.terminal,footprint:.init(6,50,40),terminals:[TerminalLibrary.pushInSignal])
    public static let fuseTerminal = ComponentDefinition(id:"TB-FUSE",kind:.fuseTerminal,footprint:.init(8,60,45),terminals:[TerminalDefinition(id:"FUSE-IN",technology:.fusedDisconnect,minAreaMM2:0.2,maxAreaMM2:6,stripMinMM:8,stripMaxMM:14,accepted:[.bare,.ferrule])])
    public static let knifeDisconnect = ComponentDefinition(id:"TB-DISC",kind:.disconnectTerminal,footprint:.init(7,55,42),terminals:[TerminalDefinition(id:"DISC",technology:.knifeDisconnect,minAreaMM2:0.2,maxAreaMM2:4,stripMinMM:8,stripMaxMM:12,accepted:[.bare,.ferrule])],notes:["visible selective signal isolation/test boundary"])
    public static let analogIsolator = ComponentDefinition(id:"ISO-AI",kind:.signalConditioner,footprint:.init(12,100,115),heatWatts:1.2,terminals:[TerminalLibrary.pushInSignal],notes:["generic isolated 4-20 mA conditioner"])
    public static let remoteAI = ComponentDefinition(id:"RIO-AI",kind:.remoteIO,footprint:.init(25,110,80),heatWatts:2.5,terminals:[TerminalLibrary.pushInSignal],notes:["generic remote analog input module"])
}

public enum InstrumentTerminalRole: String, Sendable, Codable { case loopPositive, loopNegative, sensorPositive, sensorNegative, shield, airSupply, pneumaticOutput, travelFeedback, canHigh, canLow, serialA, serialB, dcPositive, dcCommon, earth, pilotPositive, pilotNegative, lowFirePositive, lowFireNegative, highFirePositive, highFireNegative, ignition, flameSense }
public struct DeviceTerminal: Sendable, Codable, Hashable { public var id:String; public var role:InstrumentTerminalRole; public init(_ id:String,_ role:InstrumentTerminalRole){self.id=id;self.role=role} }
public struct DeviceTerminalMap: Sendable, Codable, Hashable {
    public var device:String; public var terminals:[DeviceTerminal]
    public init(device:String,terminals:[DeviceTerminal]){self.device=device;self.terminals=terminals}
    public func terminal(for role:InstrumentTerminalRole)->DeviceTerminal?{terminals.first{$0.role == role}}
    public var duplicateRoles:[InstrumentTerminalRole]{Dictionary(grouping:terminals,by:{$0.role}).filter{$0.value.count>1}.map{$0.key}}
}
public enum FieldDeviceMaps {
    public static let twoWireTransmitter = DeviceTerminalMap(device:"2WIRE-TX",terminals:[.init("+",.loopPositive),.init("-",.loopNegative),.init("SH",.shield)])
    public static let dvc = DeviceTerminalMap(device:"DVC",terminals:[.init("LOOP+",.loopPositive),.init("LOOP-",.loopNegative),.init("AIR-SUP",.airSupply),.init("OUT",.pneumaticOutput),.init("FB",.travelFeedback),.init("SH",.shield)])
    public static let burner = DeviceTerminalMap(device:"BMS",terminals:[.init("DC+",.dcPositive),.init("COM",.dcCommon),.init("EGND",.earth),.init("PIL+",.pilotPositive),.init("PIL-",.pilotNegative),.init("LOW+",.lowFirePositive),.init("LOW-",.lowFireNegative),.init("HIGH+",.highFirePositive),.init("HIGH-",.highFireNegative),.init("IGN",.ignition),.init("ION",.flameSense)])
    public static let canNode = DeviceTerminalMap(device:"CAN-NODE",terminals:[.init("CAN-H",.canHigh),.init("CAN-L",.canLow),.init("DC+",.dcPositive),.init("COM",.dcCommon),.init("SH",.shield)])
    public static let rs485Node = DeviceTerminalMap(device:"RS485-NODE",terminals:[.init("A",.serialA),.init("B",.serialB),.init("COM",.dcCommon),.init("SH",.shield)])
}

public enum Rev28CheckKind: String, Sendable, Codable { case visual, identification, termination, continuity, insulationEvidence, groundBond, power, io, loopCalibration, interlock, functionalProof, network }
public enum CommissioningResult: String, Sendable, Codable { case pending, pass, fail, notApplicable }
public struct Rev28Check: Sendable, Codable, Hashable { public var id:String; public var kind:Rev28CheckKind; public var target:String; public var required:Bool; public var result:CommissioningResult = .pending; public var evidence:String=""; public init(_ id:String,_ kind:Rev28CheckKind,_ target:String,required:Bool=true){self.id=id;self.kind=kind;self.target=target;self.required=required} }
public struct CommissioningSheet: Sendable, Codable {
    public var asset:String; public var checks:[Rev28Check]
    public init(asset:String,checks:[Rev28Check]){self.asset=asset;self.checks=checks}
    public mutating func record(_ id:String,result:CommissioningResult,evidence:String){guard let i=checks.firstIndex(where:{$0.id==id}) else{return};checks[i].result=result;checks[i].evidence=evidence}
    public var blocking:[Rev28Check]{checks.filter{$0.required && $0.result != .pass}}
    public var complete:Bool{blocking.isEmpty}
}

public enum LatentDefectKind: String, Sendable, Codable { case marginalCrimp, looseTermination, strandDamage, waterIngress, shieldGroundLoop, shortDoorServiceLoop, wrongCore, reversedPolarity }
public struct LatentWorkmanshipDefect: Sendable, Codable, Hashable {
    public var id:String; public var kind:LatentDefectKind; public var severity:Double; public var accumulatedDamage:Double=0; public var revealed=false
    public init(id:String,kind:LatentDefectKind,severity:Double){self.id=id;self.kind=kind;self.severity=max(0,min(1,severity))}
    public mutating func age(load:Double,temperatureC:Double,vibration:Double,moisture:Double,dtHours:Double){let thermal=max(0,temperatureC-25)/75;let stress=max(0,load)*0.35+thermal*0.25+max(0,vibration)*0.25+max(0,moisture)*0.15;accumulatedDamage += severity*stress*max(0,dtHours)/1000; if accumulatedDamage >= 1 {revealed=true}}
    public var addedResistanceOhms:Double { guard kind == .marginalCrimp || kind == .looseTermination || kind == .strandDamage else{return 0}; return revealed ? 0.2*severity : 0.01*severity }
}
public struct WorkmanshipHistory: Sendable, Codable { public var defects:[LatentWorkmanshipDefect]=[]; public init(){}; public mutating func age(load:Double,tempC:Double,vibration:Double,moisture:Double,hours:Double){for i in defects.indices{defects[i].age(load:load,temperatureC:tempC,vibration:vibration,moisture:moisture,dtHours:hours)}}; public var active:[LatentWorkmanshipDefect]{defects.filter{$0.revealed}} }

public struct LoopDocumentBundle: Sendable, Codable, Hashable { public var loopID:String; public var loopSheet:[String]; public var wiringSchedule:[String]; public var terminalPlan:[String]; public var ioList:[String]; public init(loopID:String,loopSheet:[String],wiringSchedule:[String],terminalPlan:[String],ioList:[String]){self.loopID=loopID;self.loopSheet=loopSheet;self.wiringSchedule=wiringSchedule;self.terminalPlan=terminalPlan;self.ioList=ioList} }
public enum Rev28DocumentFactory {
    public static func pit401()->LoopDocumentBundle { .init(loopID:"PIT-401",loopSheet:["PROCESS TAP -> PIT-401 -> CBL-401 -> JB-4 -> ISO-17 -> RIO-AI3 -> PLC:PIT401_PV -> HMI:PIT401"],wiringSchedule:["401+ PIT-401:+ -> JB-4:12","401- PIT-401:- -> JB-4:13","401A+ JB-4:12 -> ISO-17:IN+","401B+ ISO-17:OUT+ -> RIO-AI3+"],terminalPlan:["JB-4:12 401+","JB-4:13 401-","ISO-17 IN+/OUT+","RIO-AI3 +/-"],ioList:["PIT401_PV AI3 4-20mA"]) }
}

public struct Rev28TrainingCell: Sendable, Codable {
    public var components:[ComponentDefinition] = [IndustrialComponentLibrary.feedThrough,IndustrialComponentLibrary.knifeDisconnect,IndustrialComponentLibrary.analogIsolator,IndustrialComponentLibrary.remoteAI]
    public var pitMap=FieldDeviceMaps.twoWireTransmitter; public var dvcMap=FieldDeviceMaps.dvc; public var burnerMap=FieldDeviceMaps.burner
    public var sheet:CommissioningSheet; public var workmanship=WorkmanshipHistory(); public var docs=Rev28DocumentFactory.pit401()
    public init(){sheet=CommissioningSheet(asset:"PIT-401 LOOP",checks:[.init("VIS",.visual,"PIT-401"),.init("ID",.identification,"CBL-401"),.init("TERM",.termination,"JB-4"),.init("CONT",.continuity,"401+/401-"),.init("INS",.insulationEvidence,"CBL-401"),.init("PWR",.power,"24V LOOP"),.init("IO",.io,"AI3"),.init("CAL",.loopCalibration,"PIT-401"),.init("FUNC",.functionalProof,"PIT401_PV")])}
}
