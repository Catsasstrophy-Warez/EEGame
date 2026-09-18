import Foundation
import ElectricalCore
import CircuitMNA

// Rev69: topology-aware instruments, reference-backed transmitter service, protocol/CAN depth,
// tiered forensics, adaptive stepping and identity synchronization.

public enum EEInstrumentInsertionMode69: String, Sendable, Codable { case none, voltageParallel, currentSeries, loopCalibratorSeries }
public struct EETopologyInstrument69: Sendable, Codable, Equatable {
    public var mode: EEInstrumentInsertionMode69 = .none
    public var nodeA: NodeID = 1
    public var nodeB: NodeID = 0
    public var voltageInputOhms = 10_000_000.0
    public var seriesBurdenOhms = 8.0
    public init() {}
    /// Returns a modified topology. Series insertion is represented by replacing a selected resistor with two legs and the instrument burden.
    public func parallelInserted(into circuit: Circuit) -> Circuit {
        guard mode == .voltageParallel else { return circuit }
        var c=circuit; c.resistors.append(.init(a:nodeA,b:nodeB,resistance:max(1,voltageInputOhms))); return c
    }
    public func seriesInserted(into circuit: Circuit, resistorIndex: Int) -> Circuit? {
        guard mode == .currentSeries || mode == .loopCalibratorSeries, circuit.resistors.indices.contains(resistorIndex) else { return nil }
        let original=circuit.resistors[resistorIndex]; var c=circuit; let inserted=c.nodeCount; c.nodeCount += 1
        c.resistors[resistorIndex] = .init(a:original.a,b:inserted,resistance:original.resistance)
        c.resistors.append(.init(a:inserted,b:original.b,resistance:max(1e-6,seriesBurdenOhms)))
        return c
    }
}

public struct EEInsulationTransient69: Sendable, Codable, Equatable {
    public var testVoltage=500.0; public var insulationOhms=100_000_000.0; public var capacitanceF=1e-6; public var voltage=0.0
    public init() {}
    public mutating func charge(dt:Double) { let tau=max(1e-9,insulationOhms*capacitanceF); voltage += (testVoltage-voltage)*(1-exp(-max(0,dt)/tau)) }
    public mutating func discharge(throughOhms:Double,dt:Double) { let tau=max(1e-9,max(1,throughOhms)*capacitanceF); voltage *= exp(-max(0,dt)/tau) }
    public var storedEnergyJ:Double { 0.5*capacitanceF*voltage*voltage }
    public var touchSafeEducational:Bool { abs(voltage) < 30 }
}

public enum EEReferenceKind69:String,Sendable,Codable { case pressure, current, voltage, resistance, temperature }
public struct EEReferenceStandard69:Sendable,Codable,Equatable { public var id:String; public var kind:EEReferenceKind69; public var value:Double; public var uncertainty:Double; public var unit:String; public init(id:String,kind:EEReferenceKind69,value:Double,uncertainty:Double,unit:String){self.id=id;self.kind=kind;self.value=value;self.uncertainty=max(0,uncertainty);self.unit=unit} }
public struct EETrimResult69:Sendable,Codable,Equatable { public var action:EETransmitterTrimAction67; public var before:Double; public var after:Double; public var reference:Double; public var combinedUncertainty:Double; public var accepted:Bool }
public struct EETransmitterProcedure69:Sendable,Codable,Equatable {
    public var service=EETransmitterService67(); public var history:[EETrimResult69]=[]; public init(){}
    public mutating func perform(_ action:EETransmitterTrimAction67, observed:Double, reference:EEReferenceStandard69, deviceUncertainty:Double, tolerance:Double)->EETrimResult69 { let before=observed; service.apply(action,reference:reference.value,observed:observed); let combined=sqrt(reference.uncertainty*reference.uncertainty+deviceUncertainty*deviceUncertainty); let after:Double
        switch action { case .sensorZero,.sensorSpan: after=reference.value; case .outputFourMA: after=4; case .outputTwentyMA: after=20; case .rerange: after=reference.value }
        let r=EETrimResult69(action:action,before:before,after:after,reference:reference.value,combinedUncertainty:combined,accepted:abs(after-reference.value)+combined <= tolerance); history.append(r); return r }
}

public enum EEDPExamFinding69:String,Sendable,Codable { case incomplete, validZeroIsolation, equalizedBeforeIsolation, ventedLiveSide, restorationIncomplete }
public struct EEDPPracticalExam69:Sendable,Codable,Equatable { public var procedure=EEDPQualification68(); public var zeroVerified=false; public var asLeftRestored=false; public init(){}; public mutating func perform(_ step:EEDPProcedureStep68){procedure.perform(step);if step == .verifyZero {zeroVerified=true};if step == .restoreHigh && procedure.manifold.highBlock && procedure.manifold.lowBlock && !procedure.manifold.equalize && !procedure.manifold.highVent && !procedure.manifold.lowVent {asLeftRestored=true}}
    public var finding:EEDPExamFinding69 { if procedure.unsafeSequence{return .equalizedBeforeIsolation};if zeroVerified && !asLeftRestored{return .restorationIncomplete};if zeroVerified && asLeftRestored{return .validZeroIsolation};return .incomplete } }

public struct EEAdaptiveTransientStep69:Sendable,Codable,Equatable { public var minimum=0.00005; public var maximum=0.02; public var current=0.001; public var targetError=1e-4; public init(){}; public mutating func update(estimatedError:Double)->Double { if estimatedError > targetError*2 {current=max(minimum,current*0.5)} else if estimatedError < targetError*0.25 {current=min(maximum,current*1.5)};return current } }

public enum EEPLCExecutableInstruction69:String,Sendable,Codable { case xic,xio,ton,ctu,geq,mov,ote }
public struct EEPLCInstructionState69:Sendable,Codable,Equatable { public var rung:String; public var instruction:EEPLCExecutableInstruction69; public var input:Double; public var accumulator:Double; public var output:Double }
public struct EEPLCExecution69:Sendable,Codable,Equatable { public var timerAccum:[String:Double]=[:]; public var counterAccum:[String:Int]=[:]; public var traces:[EEPLCInstructionState69]=[]; public init(){}
    @discardableResult public mutating func execute(rung:String,instruction:EEPLCExecutableInstruction69,input:Double,preset:Double=0,dt:Double=0.01)->Double { var out=0.0; var acc=0.0; switch instruction {case .xic:out=input != 0 ? 1:0;case .xio:out=input == 0 ? 1:0;case .ton:let a=(timerAccum[rung] ?? 0)+(input != 0 ? dt:-(timerAccum[rung] ?? 0));timerAccum[rung]=max(0,a);acc=timerAccum[rung] ?? 0;out=acc>=preset ? 1:0;case .ctu:if input != 0 {counterAccum[rung,default:0]+=1};acc=Double(counterAccum[rung] ?? 0);out=acc>=preset ? 1:0;case .geq:out=input>=preset ? 1:0;case .mov:out=input;case .ote:out=input != 0 ? 1:0};traces.append(.init(rung:rung,instruction:instruction,input:input,accumulator:acc,output:out));return out }
}

public enum EEProtocolFunction69:String,Sendable,Codable { case readHolding,readInput,writeSingle,writeMultiple,response,exception }
public struct EEProtocolTransaction69:Identifiable,Sendable,Codable,Equatable { public var id:Int;public var requestTime:Double;public var responseTime:Double?;public var function:EEProtocolFunction69;public var address:Int;public var quantity:Int;public var values:[Int];public var exceptionCode:Int? }
public struct EEProtocolEngine69:Sendable,Codable,Equatable { public var transactions:[EEProtocolTransaction69]=[];public init(){};public mutating func request(time:Double,function:EEProtocolFunction69,address:Int,quantity:Int=1,values:[Int]=[],latency:Double=0.004,delivered:Bool=true,exception:Int?=nil){transactions.append(.init(id:transactions.count,requestTime:time,responseTime:delivered ? time+max(0,latency):nil,function:exception == nil ? function:.exception,address:address,quantity:quantity,values:values,exceptionCode:exception))} }

public enum EECANFrameKind69:String,Sendable,Codable { case data,error,overload }
public struct EECANFrame69:Sendable,Codable,Equatable { public var identifier:Int;public var data:[UInt8];public var kind:EECANFrameKind69;public var arbitrationWon:Bool;public var stuffBits:Int;public var crcEducational:UInt16 }
public enum EECANProtocol69 { public static func frame(identifier:Int,data:[UInt8],competingIDs:[Int]=[])->EECANFrame69 { let winner=([identifier]+competingIDs).min() ?? identifier; let raw=[UInt8((identifier>>3)&0xFF),UInt8((identifier&7)<<5)]+data; var run=0,last:UInt8?=nil,stuff=0;for byte in raw{for bit in (0..<8).reversed(){let b=(byte>>bit)&1;if b==last{run+=1}else{run=1;last=b};if run==5{stuff+=1;run=0;last=nil}}};let crc=raw.reduce(UInt16(0x1D0F)){ (($0<<5)|($0>>11)) ^ UInt16($1) };return .init(identifier:identifier,data:data,kind:.data,arbitrationWon:identifier==winner,stuffBits:stuff,crcEducational:crc)}
    public static func error(identifier:Int)->EECANFrame69 {.init(identifier:identifier,data:[],kind:.error,arbitrationWon:true,stuffBits:0,crcEducational:0)} }

public struct EETieredForensics69:Sendable,Codable,Equatable { public var fast=EEForensicCircularBuffer67(capacity:20_000);public var controls=EEForensicCircularBuffer67(capacity:6_000);public var process=EEForensicCircularBuffer67(capacity:3_600);public init(){};public mutating func record(_ f:EEReplayFrame63,fastSample:Bool=true,controlSample:Bool=true,processSample:Bool=false){if fastSample{fast.append(f)};if controlSample{controls.append(f)};if processSample{process.append(f)}};public func nearest(time:Double)->EEReplayFrame63? { [fast.nearest(time:time),controls.nearest(time:time),process.nearest(time:time)].compactMap{$0}.min{abs($0.time-time)<abs($1.time-time)} } }

public enum EEIdentitySurface69:String,Sendable,Codable,CaseIterable { case cabinet,schematic,loopSheet,terminalPlan,plc,hmi,historian,evidence,goldenThread }
public struct EEIdentityLink69:Sendable,Codable,Equatable { public var identity:String;public var surface:EEIdentitySurface69;public var locator:String }
public struct EEIdentitySynchronizer69:Sendable,Codable,Equatable { public var links:[EEIdentityLink69]=[];public var selected:String?;public init(){};public mutating func register(identity:String,surface:EEIdentitySurface69,locator:String){links.append(.init(identity:identity,surface:surface,locator:locator))};public func highlights()->[EEIdentityLink69]{guard let selected else{return []};return links.filter{$0.identity==selected}} }

public struct EERev69UnifiedIndustrialTrainingFacility:Sendable,Codable { public var base=EERev68SynchronizedForensicLab();public var insertion=EETopologyInstrument69();public var insulation=EEInsulationTransient69();public var transmitter=EETransmitterProcedure69();public var dpExam=EEDPPracticalExam69();public var adaptiveStep=EEAdaptiveTransientStep69();public var plc=EEPLCExecution69();public var protocolEngine=EEProtocolEngine69();public var tiered=EETieredForensics69();public var identities=EEIdentitySynchronizer69();public init(){identities.register(identity:"TB1:12",surface:.cabinet,locator:"MCC-A/TB1/12");identities.register(identity:"TB1:12",surface:.schematic,locator:"E-101 rung 12");identities.register(identity:"TB1:12",surface:.terminalPlan,locator:"TP-101 row 12");identities.register(identity:"TB1:12",surface:.goldenThread,locator:"GT/control/run-permissive")}
    public mutating func tick(dt:Double,activity:Double){base.tick(dt:dt,activity:activity);if let f=base.workbench.forensic.frames.last{tiered.record(f,fastSample:true,controlSample:true,processSample:Int(base.workbench.clock.time*10)%10==0)}} }
