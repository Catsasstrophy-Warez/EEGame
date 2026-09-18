import Foundation

public enum EEProductionWorld: String, Sendable, Codable, CaseIterable { case training, naturalGas, coalMining, electronicsBench, technicalLibrary, instructorStudio, sandbox }
public enum EEEngineeringSurface: String, Sendable, Codable, CaseIterable { case physical, oneLine, elementary, loopSheet, pAndID, plc, hmi, historian, thermal, vibration, network, maintenance, workOrder }
public struct EEIdentityBinding: Sendable, Codable, Equatable { public var surface: EEEngineeringSurface; public var reference: String; public init(_ surface:EEEngineeringSurface,_ reference:String){self.surface=surface;self.reference=reference} }
public struct EEUniversalIdentity: Sendable, Codable, Equatable { public var id:String; public var world:EEIndustrialWorld?; public var bindings:[EEIdentityBinding]; public init(id:String,world:EEIndustrialWorld?,bindings:[EEIdentityBinding]){self.id=id;self.world=world;self.bindings=bindings} }
public struct EEUniversalGoldenThread: Sendable, Codable, Equatable {
 public var identities:[EEUniversalIdentity]
 public init(){ identities=[
  .init(id:"PIT-401",world:.naturalGas,bindings:[.init(.physical,"COMP2/JB4/PIT401"),.init(.pAndID,"PIT-401"),.init(.loopSheet,"LOOP-401"),.init(.plc,"PIT401_PV"),.init(.hmi,"UNIT2.DISCH"),.init(.historian,"PIT401_PV")]),
  .init(id:"CV-NR-OL",world:.coalMining,bindings:[.init(.physical,"North Ridge Overland Conveyor"),.init(.oneLine,"NR-OL-DRIVE"),.init(.elementary,"CV-NR-OL-CTRL"),.init(.plc,"CV_NR_OL"),.init(.historian,"CV_NR_OL_AMPS"),.init(.maintenance,"CV-NR-OL")]),
  .init(id:"FAN-NR-MAIN",world:.coalMining,bindings:[.init(.physical,"North Ridge Main Fan"),.init(.oneLine,"NR-HV-FAN"),.init(.elementary,"FAN-NR-MAIN-CTRL"),.init(.plc,"NR_MAIN_FAN"),.init(.vibration,"FAN-NR-MAIN"),.init(.maintenance,"FAN-NR-MAIN")]) ] }
 public func identity(_ id:String)->EEUniversalIdentity?{identities.first{$0.id==id}}
}

public struct EEProductionInstrumentState:Sendable,Codable,Equatable { public var kind:EEInstrumentKind; public var mode:String; public var range:String; public var accuracyPercent:Double; public var resolution:Double; public var batteryPercent:Double; public var fuseHealthy:Bool; public init(kind:EEInstrumentKind,mode:String="auto",range:String="auto",accuracyPercent:Double=0.5,resolution:Double=0.01,batteryPercent:Double=100,fuseHealthy:Bool=true){self.kind=kind;self.mode=mode;self.range=range;self.accuracyPercent=accuracyPercent;self.resolution=resolution;self.batteryPercent=batteryPercent;self.fuseHealthy=fuseHealthy} }
public struct EEInstrumentEvidence:Sendable,Codable,Equatable { public var time:Double; public var instrument:EEInstrumentKind; public var identity:String; public var quantity:String; public var value:Double; public var unit:String; public var provenance:String }
public struct EEUniversalInstrumentFramework:Sendable,Codable,Equatable { public var instruments:[EEProductionInstrumentState]=EEInstrumentKind.allCases.map{.init(kind:$0)}; public var evidence:[EEInstrumentEvidence]=[]; public init(){}; public mutating func record(time:Double,instrument:EEInstrumentKind,identity:String,quantity:String,value:Double,unit:String){evidence.append(.init(time:time,instrument:instrument,identity:identity,quantity:quantity,value:value,unit:unit,provenance:"simulation-truth"))} }

public struct EEUnifiedForensicFrame:Sendable,Codable,Equatable { public var time:Double; public var world:EEIndustrialWorld; public var values:[String:Double]; public var events:[String] }
public struct EEUnifiedForensicTimeline:Sendable,Codable,Equatable { public var frames:[EEUnifiedForensicFrame]=[]; public init(){}; public mutating func append(_ f:EEUnifiedForensicFrame){frames.append(f);if frames.count>14400{frames.removeFirst(frames.count-14400)}}; public func nearest(_ t:Double,world:EEIndustrialWorld)->EEUnifiedForensicFrame?{frames.filter{$0.world==world}.min{abs($0.time-t)<abs($1.time-t)}} }

public enum EECausalFault:String,Sendable,Codable,CaseIterable { case looseTermination, instrumentDrift, networkLatency, draggingIdler, blockedChute, pumpWear, valveDegradation, coolingFouling }
public struct EEGeneratedScenario:Sendable,Codable,Equatable { public var id:String; public var world:EEIndustrialWorld; public var rootFaults:[EECausalFault]; public var symptom:String; public var evidenceTargets:[String]; public var seed:UInt64 }
public struct EECausalScenarioGenerator:Sendable,Codable,Equatable { public init(){}; public func generate(world:EEIndustrialWorld,seed:UInt64)->EEGeneratedScenario { let allowed:[EECausalFault] = world == .coalMining ? [.draggingIdler,.blockedChute,.pumpWear,.looseTermination,.instrumentDrift,.networkLatency] : [.valveDegradation,.coolingFouling,.looseTermination,.instrumentDrift,.networkLatency,.pumpWear]; let a=allowed[Int(seed % UInt64(allowed.count))]; let b=allowed[Int((seed/7+3) % UInt64(allowed.count))]; return .init(id:"SCN-\(seed)",world:world,rootFaults:a==b ? [a]:[a,b],symptom:world == .coalMining ? "Production/electrical evidence diverges across the coal system" : "Process/control evidence diverges across the gas station",evidenceTargets:world == .coalMining ? ["belt current","idler temperature","PLC","historian"]:["process pressure","loop current","PLC","historian"],seed:seed) } }

public struct EEProductionIntegrationRev45:Sendable,Codable,Equatable {
 public var gas=EEForensicPlantRev40(); public var coal=EECoalMiningRev44(); public var goldenThread=EEUniversalGoldenThread(); public var instruments=EEUniversalInstrumentFramework(); public var timeline=EEUnifiedForensicTimeline(); public var generator=EECausalScenarioGenerator(); public var selectedWorld:EEProductionWorld = .training
 public init(){}
 public mutating func tickGas(_ seconds:Double){gas.tick(seconds:seconds);let t=gas.rev39.base.living.shift.time;timeline.append(.init(time:t,world:.naturalGas,values:["suctionPSI":gas.header.suctionPSI,"dischargePSI":gas.header.dischargePSI,"dcBusV":gas.vfd.dcBusV],events:[]))}
 public mutating func tickCoal(_ seconds:Double){coal.tick(seconds:seconds);let f=coal.recorder.frames.last;timeline.append(.init(time:coal.time,world:.coalMining,values:["beltAmps":f?.beltAmps ?? 0,"maxIdlerC":f?.maxIdlerC ?? 0,"methane":f?.methanePercent ?? 0,"mediumSG":f?.prepSG ?? 0],events:[]))}
}
