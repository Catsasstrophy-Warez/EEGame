import Foundation

// Rev29 — unified equipment registry, synchronized Golden Thread surfaces, and physical test-point tools.
// Educational simulation. Public vendor documentation informs concepts; real manufacturer instructions govern field work.

public enum EquipmentInterfaceKind: String, Sendable, Codable, Hashable { case electrical, pneumatic, process, canBus, rs485, hart, thermal }
public enum EquipmentDiagnosticCapability: String, Sendable, Codable, Hashable { case localDisplay, analogMeasurement, hart, travel, pressure, eventLog, networkHealth, calibration }
public struct EquipmentInterface: Sendable, Codable, Hashable { public var id:String; public var kind:EquipmentInterfaceKind; public init(_ id:String,_ kind:EquipmentInterfaceKind){self.id=id;self.kind=kind} }
public struct MaintenanceDefinition: Sendable, Codable, Hashable { public var action:String; public var invalidatesCalibration:Bool; public var requiresFunctionalProof:Bool; public init(_ action:String,invalidatesCalibration:Bool=false,requiresFunctionalProof:Bool=true){self.action=action;self.invalidatesCalibration=invalidatesCalibration;self.requiresFunctionalProof=requiresFunctionalProof} }
public struct UnifiedEquipmentDefinition: Sendable, Codable, Hashable {
    public var id:String; public var kind:IndustrialComponentKind; public var footprint:ComponentFootprint; public var mounting:String
    public var terminals:DeviceTerminalMap; public var interfaces:[EquipmentInterface]; public var diagnostics:Set<EquipmentDiagnosticCapability>
    public var commissioning:[Rev28CheckKind]; public var maintenance:[MaintenanceDefinition]; public var degradation:[LatentDefectKind]
    public var drawingSymbol:String; public var realityAssetID:String; public var notes:[String]
    public init(id:String,kind:IndustrialComponentKind,footprint:ComponentFootprint,mounting:String,terminals:DeviceTerminalMap,interfaces:[EquipmentInterface],diagnostics:Set<EquipmentDiagnosticCapability>,commissioning:[Rev28CheckKind],maintenance:[MaintenanceDefinition]=[],degradation:[LatentDefectKind]=[],drawingSymbol:String,realityAssetID:String,notes:[String]=[]){self.id=id;self.kind=kind;self.footprint=footprint;self.mounting=mounting;self.terminals=terminals;self.interfaces=interfaces;self.diagnostics=diagnostics;self.commissioning=commissioning;self.maintenance=maintenance;self.degradation=degradation;self.drawingSymbol=drawingSymbol;self.realityAssetID=realityAssetID;self.notes=notes}
}
public struct IndustrialEquipmentRegistry: Sendable, Codable {
    public var definitions:[String:UnifiedEquipmentDefinition]=[:]
    public init(_ defs:[UnifiedEquipmentDefinition]=[]){for d in defs{definitions[d.id]=d}}
    public mutating func register(_ d:UnifiedEquipmentDefinition){definitions[d.id]=d}
    public subscript(_ id:String)->UnifiedEquipmentDefinition?{definitions[id]}
}

public enum Rev29EquipmentFactory {
    static let txCommission:[Rev28CheckKind] = [.visual,.identification,.termination,.continuity,.power,.io,.loopCalibration,.functionalProof]
    public static let pit = UnifiedEquipmentDefinition(id:"PIT-GENERIC",kind:.transmitter,footprint:.init(110,180,110),mounting:"field bracket/manifold",terminals:FieldDeviceMaps.twoWireTransmitter,interfaces:[.init("PROCESS",.process),.init("LOOP",.electrical),.init("HART",.hart)],diagnostics:[.localDisplay,.analogMeasurement,.hart,.calibration],commissioning:txCommission,maintenance:[.init("zero/span verification",requiresFunctionalProof:true)],degradation:[.waterIngress,.looseTermination],drawingSymbol:"PIT",realityAssetID:"instrument.pressure.generic")
    public static let tit = UnifiedEquipmentDefinition(id:"TIT-GENERIC",kind:.transmitter,footprint:.init(110,180,110),mounting:"thermowell/head",terminals:FieldDeviceMaps.twoWireTransmitter,interfaces:[.init("SENSOR",.thermal),.init("LOOP",.electrical),.init("HART",.hart)],diagnostics:[.localDisplay,.analogMeasurement,.hart,.calibration],commissioning:txCommission,maintenance:[.init("sensor/transmitter calibration")],degradation:[.waterIngress,.wrongCore],drawingSymbol:"TIT",realityAssetID:"instrument.temperature.generic")
    public static let fit = UnifiedEquipmentDefinition(id:"FIT-GENERIC",kind:.transmitter,footprint:.init(120,190,120),mounting:"field bracket/manifold",terminals:FieldDeviceMaps.twoWireTransmitter,interfaces:[.init("FLOW/DP",.process),.init("LOOP",.electrical),.init("HART",.hart)],diagnostics:[.localDisplay,.analogMeasurement,.hart,.calibration],commissioning:txCommission,maintenance:[.init("zero/span verification")],degradation:[.waterIngress,.looseTermination],drawingSymbol:"FIT",realityAssetID:"instrument.flow.generic")
    public static let lit = UnifiedEquipmentDefinition(id:"LIT-GENERIC",kind:.transmitter,footprint:.init(140,220,140),mounting:"vessel/nozzle",terminals:FieldDeviceMaps.twoWireTransmitter,interfaces:[.init("LEVEL",.process),.init("LOOP",.electrical),.init("HART",.hart)],diagnostics:[.localDisplay,.analogMeasurement,.hart,.calibration],commissioning:txCommission,maintenance:[.init("reference/echo verification")],degradation:[.waterIngress,.looseTermination],drawingSymbol:"LIT",realityAssetID:"instrument.level.generic")
    public static let dvc = UnifiedEquipmentDefinition(id:"DVC-GENERIC",kind:.positioner,footprint:.init(160,200,140),mounting:"control valve actuator",terminals:FieldDeviceMaps.dvc,interfaces:[.init("LOOP",.electrical),.init("HART",.hart),.init("AIR",.pneumatic),.init("TRAVEL",.process)],diagnostics:[.analogMeasurement,.hart,.travel,.pressure,.calibration],commissioning:[.visual,.termination,.power,.loopCalibration,.functionalProof],maintenance:[.init("replace pneumatic relay",invalidatesCalibration:true),.init("travel calibration")],degradation:[.looseTermination,.waterIngress],drawingSymbol:"DVC",realityAssetID:"finalcontrol.positioner.generic")
    public static let i2p = UnifiedEquipmentDefinition(id:"I2P-GENERIC",kind:.signalConditioner,footprint:.init(100,150,90),mounting:"field bracket",terminals:.init(device:"I2P",terminals:[.init("+",.loopPositive),.init("-",.loopNegative),.init("AIR",.airSupply),.init("OUT",.pneumaticOutput)]),interfaces:[.init("LOOP",.electrical),.init("AIR",.pneumatic)],diagnostics:[.analogMeasurement,.pressure,.calibration],commissioning:[.visual,.termination,.power,.loopCalibration,.functionalProof],maintenance:[.init("I/P calibration")],drawingSymbol:"I/P",realityAssetID:"finalcontrol.i2p.generic")
    public static let mx5 = UnifiedEquipmentDefinition(id:"MX5-CONCEPT",kind:.remoteIO,footprint:.init(180,220,60),mounting:"panel/backplate",terminals:FieldDeviceMaps.canNode,interfaces:[.init("POWER",.electrical),.init("CAN",.canBus)],diagnostics:[.networkHealth,.eventLog],commissioning:[.visual,.termination,.power,.io,.network,.functionalProof],maintenance:[.init("module replacement")],degradation:[.looseTermination,.waterIngress],drawingSymbol:"RIO",realityAssetID:"remoteio.mx5.concept",notes:["Conceptual terminal map only; exact variants require verified device documentation."])
    public static let burner = UnifiedEquipmentDefinition(id:"BMS-PF2100-CONCEPT",kind:.burnerController,footprint:.init(250,300,100),mounting:"burner control panel",terminals:FieldDeviceMaps.burner,interfaces:[.init("POWER",.electrical),.init("FIELD",.electrical),.init("FLAME",.process)],diagnostics:[.localDisplay,.eventLog,.analogMeasurement],commissioning:[.visual,.termination,.power,.interlock,.functionalProof],maintenance:[.init("controller/field wiring service")],degradation:[.looseTermination,.wrongCore,.reversedPolarity],drawingSymbol:"BMS",realityAssetID:"burner.pf2100.concept",notes:["Vendor-aware educational abstraction; not certified burner-management logic."])
    public static func registry()->IndustrialEquipmentRegistry{.init([pit,tit,fit,lit,dvc,i2p,mx5,burner])}
}

public enum GoldenSurface: String, Sendable, Codable, CaseIterable { case cabinet, loopSheet, wiringDiagram, terminalPlan, ioList, plcTag, hmi }
public struct GoldenIdentityBinding: Sendable, Codable, Hashable { public var identity:String; public var surface:GoldenSurface; public var objectID:String; public init(_ identity:String,_ surface:GoldenSurface,_ objectID:String){self.identity=identity;self.surface=surface;self.objectID=objectID} }
public struct SynchronizedGoldenThread: Sendable, Codable {
    public var bindings:[GoldenIdentityBinding]
    public init(bindings:[GoldenIdentityBinding]){self.bindings=bindings}
    public func highlight(identity:String)->[GoldenSurface:String]{Dictionary(uniqueKeysWithValues:bindings.filter{$0.identity==identity}.map{($0.surface,$0.objectID)})}
    public func identity(surface:GoldenSurface,objectID:String)->String?{bindings.first{$0.surface==surface && $0.objectID==objectID}?.identity}
    public static func pit401()->Self{.init(bindings:[.init("PIT401_SIGNAL",.cabinet,"WIRE:401+"),.init("PIT401_SIGNAL",.loopSheet,"PIT-401"),.init("PIT401_SIGNAL",.wiringDiagram,"401+"),.init("PIT401_SIGNAL",.terminalPlan,"JB-4:12"),.init("PIT401_SIGNAL",.ioList,"AI3"),.init("PIT401_SIGNAL",.plcTag,"PIT401_PV"),.init("PIT401_SIGNAL",.hmi,"PIT401")])}
}

public enum FieldToolKind: String, Sendable, Codable { case dmm, clampMeter, insulationTester, loopCalibrator, processCalibrator, hartCommunicator, pressureSource, temperatureSimulator, oscilloscope, thermalCamera, networkAnalyzer }
public enum ToolMode: String, Sendable, Codable { case measureVoltage, measureCurrent, sourceCurrent, simulateTransmitter, hart, pressure, temperature, scope, thermal, network }
public struct PhysicalTestPoint: Sendable, Codable, Hashable { public var id:String; public var identity:String; public var energized:Bool; public var voltage:Double; public var currentMA:Double; public var pressurePSI:Double; public var temperatureF:Double; public init(id:String,identity:String,energized:Bool=false,voltage:Double=0,currentMA:Double=0,pressurePSI:Double=0,temperatureF:Double=70){self.id=id;self.identity=identity;self.energized=energized;self.voltage=voltage;self.currentMA=currentMA;self.pressurePSI=pressurePSI;self.temperatureF=temperatureF} }
public enum FieldEvidenceValidity: String, Sendable, Codable { case valid, ambiguous, unsafe }
public struct FieldToolEvidence: Sendable, Codable, Hashable { public var instrument:String; public var quantity:String; public var testPoint:String; public var value:Double; public var validity:FieldEvidenceValidity; public init(instrument:String,quantity:String,testPoint:String,value:Double,validity:FieldEvidenceValidity = .valid){self.instrument=instrument;self.quantity=quantity;self.testPoint=testPoint;self.value=value;self.validity=validity} }
public struct FieldTool: Sendable, Codable {
    public var id:String; public var kind:FieldToolKind; public var mode:ToolMode; public var sourceMA:Double=12; public var externalLoopPower=false
    public init(id:String,kind:FieldToolKind,mode:ToolMode){self.id=id;self.kind=kind;self.mode=mode}
    public func use(on p:PhysicalTestPoint)->FieldToolEvidence {
        switch mode {
        case .measureVoltage: return .init(instrument:id,quantity:"V",testPoint:p.id,value:p.voltage)
        case .measureCurrent: return .init(instrument:id,quantity:"mA",testPoint:p.id,value:p.currentMA)
        case .sourceCurrent: return .init(instrument:id,quantity:"mA source",testPoint:p.id,value:sourceMA)
        case .simulateTransmitter: return .init(instrument:id,quantity:"mA simulated",testPoint:p.id,value:externalLoopPower ? sourceMA : 0,validity:externalLoopPower ? .valid : .ambiguous)
        case .pressure: return .init(instrument:id,quantity:"psi",testPoint:p.id,value:p.pressurePSI)
        case .temperature: return .init(instrument:id,quantity:"degF",testPoint:p.id,value:p.temperatureF)
        default: return .init(instrument:id,quantity:mode.rawValue,testPoint:p.id,value:0)
        }
    }
}

public struct TestDisconnectBoundary: Sendable, Codable { public var id:String; public var fieldPoint:PhysicalTestPoint; public var systemPoint:PhysicalTestPoint; public var open=false; public init(id:String,fieldPoint:PhysicalTestPoint,systemPoint:PhysicalTestPoint){self.id=id;self.fieldPoint=fieldPoint;self.systemPoint=systemPoint}; public var fieldIsolated:Bool{open} }

public struct Rev29TrainingCell: Sendable, Codable {
    public var registry=Rev29EquipmentFactory.registry(); public var golden=SynchronizedGoldenThread.pit401(); public var rev28=Rev28TrainingCell()
    public var disconnect=TestDisconnectBoundary(id:"DISC-401",fieldPoint:.init(id:"DISC-401-F",identity:"PIT401_SIGNAL",currentMA:12),systemPoint:.init(id:"DISC-401-S",identity:"PIT401_SIGNAL",currentMA:12))
    public init(){}
}
