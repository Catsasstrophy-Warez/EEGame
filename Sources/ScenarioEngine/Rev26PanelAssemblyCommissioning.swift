import Foundation

// Rev26 — executable panel assembly and commissioning workflow. Actions alter construction truth.
// Educational simulation only; not a substitute for manufacturer instructions, qualified-person procedures, or code compliance.

public enum AssemblyTool: String, Sendable, Codable { case screwdriver, torqueScrewdriver, wireStripper, ferruleCrimper, lugCrimper, cableKnife, markerPrinter, multimeter, insulationTester, loopCalibrator }
public enum AssemblyActionKind: String, Sendable, Codable { case mountRail, mountDuct, mountDevice, installTerminal, installEndStop, installJumper, cutCable, stripJacket, prepareCore, crimp, land, torque, mark, terminateShield, continuityTest, insulationTest, powerCheck, ioCheck, loopCalibrate }
public enum WorkmanshipGrade: String, Sendable, Codable { case excellent, acceptable, marginal, failed }

public struct CrimpTruth: Sendable, Codable, Hashable {
    public var hardware:TerminationHardware
    public var conductorAreaMM2:Double
    public var ferruleAreaMM2:Double
    public var compression:Double
    public init(hardware:TerminationHardware = .ferrule, conductorAreaMM2:Double = 1.5, ferruleAreaMM2:Double = 1.5, compression:Double = 1.0){self.hardware=hardware;self.conductorAreaMM2=conductorAreaMM2;self.ferruleAreaMM2=ferruleAreaMM2;self.compression=compression}
    public var grade:WorkmanshipGrade { let mismatch=abs(ferruleAreaMM2-conductorAreaMM2)/max(0.1,conductorAreaMM2); if mismatch > 0.35 || compression < 0.55 || compression > 1.45 { return .failed }; if mismatch > 0.15 || compression < 0.75 || compression > 1.25 { return .marginal }; if mismatch < 0.05 && compression >= 0.9 && compression <= 1.1 { return .excellent }; return .acceptable }
    public var addedResistanceOhms:Double { switch grade {case .excellent:return 0.0003;case .acceptable:return 0.0008;case .marginal:return 0.025;case .failed:return 0.2} }
}

public struct TorqueTruth: Sendable, Codable, Hashable {
    public var requiredNM:Double; public var appliedNM:Double
    public init(requiredNM:Double = 0.6, appliedNM:Double = 0){self.requiredNM=requiredNM;self.appliedNM=appliedNM}
    public var ratio:Double { appliedNM / max(0.001,requiredNM) }
    public var grade:WorkmanshipGrade { if ratio < 0.45 || ratio > 1.8{return .failed}; if ratio < 0.8 || ratio > 1.3{return .marginal}; if ratio >= 0.95 && ratio <= 1.05{return .excellent}; return .acceptable }
}

public struct PreparedCore: Sendable, Codable, Hashable {
    public var cableTag:String; public var coreNumber:String; public var wireNumber:String
    public var stripLengthMM:Double=0; public var strandsDamagedFraction:Double=0; public var crimp:CrimpTruth?
    public var landedTerminal:String?; public var torque:TorqueTruth?; public var markerInstalled=false
    public init(cableTag:String,coreNumber:String,wireNumber:String){self.cableTag=cableTag;self.coreNumber=coreNumber;self.wireNumber=wireNumber}
    public var electricallyReady:Bool { guard let c=crimp, c.grade != .failed, landedTerminal != nil, let t=torque, t.grade != .failed else{return false}; return stripLengthMM >= 6 && stripLengthMM <= 16 && strandsDamagedFraction < 0.2 }
    public var addedResistanceOhms:Double { (crimp?.addedResistanceOhms ?? 1.0) + (torque?.grade == .marginal ? 0.04 : torque?.grade == .failed ? 0.3 : 0.0005) + strandsDamagedFraction * 0.1 }
}

public struct AssemblyEvent: Sendable, Codable, Hashable { public var sequence:Int; public var action:AssemblyActionKind; public var target:String; public var tool:AssemblyTool?; public var successful:Bool; public var note:String; public init(sequence:Int,action:AssemblyActionKind,target:String,tool:AssemblyTool?=nil,successful:Bool=true,note:String=""){self.sequence=sequence;self.action=action;self.target=target;self.tool=tool;self.successful=successful;self.note=note} }

public struct PanelAssemblyRuntime: Sendable, Codable {
    public var cabinet:ConstructionCabinet
    public var prepared:[String:PreparedCore]=[:]
    public var events:[AssemblyEvent]=[]
    public var energized=false
    public var continuityPassed:Set<String>=[]; public var insulationPassed:Set<String>=[]; public var ioChecked:Set<String>=[]; public var calibrated:Set<String>=[]
    public init(cabinet:ConstructionCabinet = Rev25Factory.instrumentCabinet()){self.cabinet=cabinet}
    mutating func log(_ action:AssemblyActionKind,_ target:String,_ tool:AssemblyTool?=nil,_ ok:Bool=true,_ note:String=""){events.append(.init(sequence:events.count+1,action:action,target:target,tool:tool,successful:ok,note:note))}
    public mutating func prepare(cable:String,core:String,wire:String,stripMM:Double,damage:Double=0){let key="\(cable):\(core)"; var p=PreparedCore(cableTag:cable,coreNumber:core,wireNumber:wire);p.stripLengthMM=stripMM;p.strandsDamagedFraction=max(0,min(1,damage));prepared[key]=p;log(.prepareCore,key,.wireStripper,p.stripLengthMM >= 4 && damage < 0.5)}
    public mutating func crimp(cable:String,core:String,truth:CrimpTruth){let key="\(cable):\(core)"; guard var p=prepared[key] else{log(.crimp,key,.ferruleCrimper,false,"core not prepared");return};p.crimp=truth;prepared[key]=p;log(.crimp,key,.ferruleCrimper,truth.grade != .failed,truth.grade.rawValue)}
    public mutating func land(cable:String,core:String,on terminal:String){let key="\(cable):\(core)";guard var p=prepared[key],cabinet.cabinet.terminals[terminal] != nil else{log(.land,key,nil,false,"unknown core or terminal");return};p.landedTerminal=terminal;prepared[key]=p;log(.land,terminal,nil,true,key)}
    public mutating func torque(cable:String,core:String,requiredNM:Double,appliedNM:Double){let key="\(cable):\(core)";guard var p=prepared[key],p.landedTerminal != nil else{log(.torque,key,.torqueScrewdriver,false,"not landed");return};let t=TorqueTruth(requiredNM:requiredNM,appliedNM:appliedNM);p.torque=t;prepared[key]=p;log(.torque,p.landedTerminal ?? key,.torqueScrewdriver,t.grade != .failed,t.grade.rawValue)}
    public mutating func mark(cable:String,core:String){let key="\(cable):\(core)";guard var p=prepared[key] else{return};p.markerInstalled=true;prepared[key]=p;log(.mark,key,.markerPrinter)}
    public mutating func continuityTest(_ wire:String,passed:Bool){if passed{continuityPassed.insert(wire)};log(.continuityTest,wire,.multimeter,passed)}
    public mutating func insulationTest(_ cable:String,passed:Bool){if passed{insulationPassed.insert(cable)};log(.insulationTest,cable,.insulationTester,passed)}
    public mutating func powerCheck(passed:Bool){energized=passed && readyToEnergize;log(.powerCheck,"PANEL",.multimeter,energized)}
    public mutating func ioCheck(_ tag:String,passed:Bool){if passed{ioChecked.insert(tag)};log(.ioCheck,tag,.multimeter,passed)}
    public mutating func loopCalibrate(_ tag:String,passed:Bool){if passed{calibrated.insert(tag)};log(.loopCalibrate,tag,.loopCalibrator,passed)}
    public var constructionFindings:[String] { var a=cabinet.audit; for (k,p) in prepared {if p.stripLengthMM < 6 || p.stripLengthMM > 16 {a.append("strip length issue: \(k)")};if p.strandsDamagedFraction >= 0.2 {a.append("strand damage: \(k)")};if p.crimp?.grade == .failed || p.crimp?.grade == .marginal {a.append("crimp quality issue: \(k)")};if p.landedTerminal == nil {a.append("unlanded prepared core: \(k)")};if p.torque?.grade == .failed || p.torque?.grade == .marginal {a.append("terminal torque issue: \(k)")};if !p.markerInstalled {a.append("missing wire marker: \(k)")}}; return a }
    public var readyToEnergize:Bool { !prepared.isEmpty && prepared.values.allSatisfy{$0.electricallyReady && $0.markerInstalled} && constructionFindings.filter{$0.contains("issue") || $0.contains("unhealthy") || $0.contains("unlanded")}.isEmpty && !continuityPassed.isEmpty && !insulationPassed.isEmpty }
    public var commissioned:Bool { energized && !ioChecked.isEmpty && !calibrated.isEmpty }
}

public enum Rev26Factory {
    public static func assembledInstrumentPanel()->PanelAssemblyRuntime { var r=PanelAssemblyRuntime(); r.prepare(cable:"CBL-401",core:"1",wire:"401+",stripMM:10); r.crimp(cable:"CBL-401",core:"1",truth:.init()); r.land(cable:"CBL-401",core:"1",on:"TB1:1"); r.torque(cable:"CBL-401",core:"1",requiredNM:0.6,appliedNM:0.6); r.mark(cable:"CBL-401",core:"1"); r.continuityTest("401+",passed:true); r.insulationTest("CBL-401",passed:true); return r }
}
