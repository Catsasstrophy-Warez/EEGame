import Foundation
import ElectricalCore
import CircuitMNA

// Rev17: generic diagnostic action/evidence engine, richer instruments, pneumatic package,
// and deterministic fault-driven troubleshooting without scripted solution paths.

public enum DiagnosticVerb: String, Sendable, Codable, CaseIterable { case observe, operate, inspect, isolate, lock, verify, probe, disconnect, reconnect, jumper, force, calibrate, adjust, replace, energize, test }
public enum InstrumentKind: String, Sendable, Codable, CaseIterable { case dmm, clampMeter, megger, phaseRotation, loopCalibrator, pressureGauge, manometer, processCalibrator, oscilloscope, thermalCamera }
public enum MeasurementValidity: String, Sendable, Codable { case valid, unsafe, ambiguous, outOfRange, instrumentMisconfigured }
public enum MeasurementQuantity: String, Sendable, Codable { case voltsAC, voltsDC, ohms, ampsAC, ampsDC, milliamps, megohms, pressurePSI, differentialPressure, temperatureC, frequencyHz, phaseRotation }

public struct DiagnosticTarget: Hashable, Sendable, Codable { public var id:String; public init(_ id:String){self.id=id} }
public struct InstrumentConfiguration: Sendable, Codable, Equatable { public var instrument:InstrumentKind; public var quantity:MeasurementQuantity; public var range:Double?; public init(_ instrument:InstrumentKind,_ quantity:MeasurementQuantity,range:Double? = nil){self.instrument=instrument;self.quantity=quantity;self.range=range} }
public struct MeasurementEvidence: Sendable, Codable, Equatable, Identifiable {
    public var id:UUID; public var time:Double; public var instrument:InstrumentKind; public var quantity:MeasurementQuantity; public var red:DiagnosticTarget?; public var black:DiagnosticTarget?; public var value:Double?; public var text:String?; public var validity:MeasurementValidity; public var provenance:String
    public init(time:Double,instrument:InstrumentKind,quantity:MeasurementQuantity,red:DiagnosticTarget? = nil,black:DiagnosticTarget? = nil,value:Double? = nil,text:String? = nil,validity:MeasurementValidity = .valid,provenance:String){id=UUID();self.time=time;self.instrument=instrument;self.quantity=quantity;self.red=red;self.black=black;self.value=value;self.text=text;self.validity=validity;self.provenance=provenance}
}
public struct DiagnosticActionRecord: Sendable, Codable, Equatable, Identifiable { public var id:UUID=UUID(); public var time:Double; public var verb:DiagnosticVerb; public var target:DiagnosticTarget; public var accepted:Bool; public var detail:String; public init(time:Double,verb:DiagnosticVerb,target:DiagnosticTarget,accepted:Bool,detail:String){self.time=time;self.verb=verb;self.target=target;self.accepted=accepted;self.detail=detail} }
public struct DiagnosticCaseFile: Sendable, Codable, Equatable { public var actions:[DiagnosticActionRecord]=[]; public var measurements:[MeasurementEvidence]=[]; public var hypotheses:[String]=[]; public var conclusion:String?; public init(){}; public var validEvidence:[MeasurementEvidence]{measurements.filter{$0.validity == .valid}} }

public enum GenericFault: String, Sendable, Codable, CaseIterable { case weldedContactor, openConductor, highResistance, blownFuse, stuckSolenoid, pneumaticLeak, boundCylinder, transmitterDrift, pluggedImpulse, staleNetwork, failedIOChannel }
public struct DiagnosticWorld: Sendable {
    public var time=0.0; public var energized=true; public var locked=false; public var zeroVerified=false; public var disconnected:Set<DiagnosticTarget>=[]; public var replaced:Set<DiagnosticTarget>=[]; public var faults:[DiagnosticTarget:GenericFault]=[:]; public var caseFile=DiagnosticCaseFile(); public init(){}
    public mutating func advance(){time += 0.1}
}
public struct UniversalDiagnosticEngine: Sendable {
    public var world=DiagnosticWorld(); public init(world:DiagnosticWorld = .init()){self.world=world}
    @discardableResult public mutating func act(_ verb:DiagnosticVerb,on target:DiagnosticTarget,detail:String="") -> Bool {
        world.advance(); var ok=true; var d=detail
        switch verb {
        case .isolate: world.energized=false; world.zeroVerified=false; d = d.isEmpty ? "Energy source isolated." : d
        case .lock: ok = !world.energized; if ok {world.locked=true}; d = ok ? "Isolation secured." : "Cannot lock an energized state."
        case .verify: ok = !world.energized && world.locked; if ok {world.zeroVerified=true}; d = ok ? "Zero-energy state verified." : "Isolation and lock required before verification."
        case .disconnect: ok = !world.energized && world.locked && world.zeroVerified; if ok {world.disconnected.insert(target)}; d = ok ? "Connection physically isolated." : "Verified zero-energy state required."
        case .reconnect: world.disconnected.remove(target); d = "Connection restored."
        case .replace: ok = !world.energized && world.zeroVerified; if ok {world.replaced.insert(target);world.faults.removeValue(forKey:target)}; d = ok ? "Component replaced." : "Replacement requires verified isolation."
        case .energize: ok = !world.locked && world.disconnected.isEmpty; if ok {world.energized=true;world.zeroVerified=false}; d = ok ? "System energized." : "Cannot energize with lock or disconnected conductors."
        default: break
        }
        world.caseFile.actions.append(.init(time:world.time,verb:verb,target:target,accepted:ok,detail:d)); return ok
    }
    public mutating func measure(_ config:InstrumentConfiguration,red:DiagnosticTarget? = nil,black:DiagnosticTarget? = nil,value:Double? = nil,text:String? = nil,requiresDead:Bool=false,requiresIsolation:DiagnosticTarget? = nil,provenance:String="simulation truth") -> MeasurementEvidence {
        world.advance(); var validity:MeasurementValidity = .valid
        if requiresDead && (world.energized || !world.zeroVerified) { validity = .unsafe }
        if let t=requiresIsolation, !world.disconnected.contains(t) { validity = .ambiguous }
        if let r=config.range, let value, abs(value)>r { validity = .outOfRange }
        let e=MeasurementEvidence(time:world.time,instrument:config.instrument,quantity:config.quantity,red:red,black:black,value:value,text:text,validity:validity,provenance:provenance); world.caseFile.measurements.append(e); return e
    }
}

public struct InstrumentPhysics: Sendable {
    public init(){}
    public func clampRMS(samples:[Double])->Double { guard !samples.isEmpty else{return 0}; return sqrt(samples.reduce(0){$0+$1*$1}/Double(samples.count)) }
    public func megger(insulationOhms:Double,testVolts:Double)->Double { guard insulationOhms>0 else{return .infinity}; return testVolts/insulationOhms }
    public func pressureGauge(actualPSI:Double,zeroError:Double=0)->Double { actualPSI+zeroError }
    public func loopCalibrator(percent:Double)->Double { 4 + 16*min(max(percent,0),100)/100 }
    public func thermalCamera(ambientC:Double,lossWatts:Double,thermalResistance:Double)->Double { ambientC + max(0,lossWatts)*max(0,thermalResistance) }
}

public struct CheckValve: Sendable, Codable, Equatable { public var stuckOpen=false; public var stuckClosed=false; public init(){}; public func permitsForward(upstream:Double,downstream:Double)->Bool {!stuckClosed && upstream>downstream}; public func permitsReverse(upstream:Double,downstream:Double)->Bool {stuckOpen && downstream>upstream} }
public struct PressureRegulator: Sendable, Codable, Equatable { public var setpointPSI=80.0; public var failedOpen=false; public var failedClosed=false; public init(){}; public func outlet(inlet:Double)->Double { if failedClosed{return 0}; if failedOpen{return inlet}; return min(inlet,setpointPSI) } }
public struct ReliefValve: Sendable, Codable, Equatable { public var setpointPSI=125.0; public var stuckClosed=false; public init(){}; public func relieving(_ pressure:Double)->Bool {!stuckClosed && pressure>=setpointPSI} }
public struct PressureTransmitterTruth: Sendable, Codable, Equatable { public var lrv=0.0;public var urv=150.0;public var driftPSI=0.0;public var impulsePlugged=false;public var heldPSI=0.0;public init(){};public mutating func milliamps(actualPSI:Double)->Double { let sensed=impulsePlugged ? heldPSI:actualPSI; if !impulsePlugged{heldPSI=actualPSI}; let pct=min(max((sensed+driftPSI-lrv)/max(urv-lrv,1e-9),0),1);return 4+16*pct } }
public struct CompressorPackage: Sendable {
    public var receiver=PneumaticReceiver(); public var check=CheckValve(); public var regulator=PressureRegulator(); public var relief=ReliefValve(); public var transmitter=PressureTransmitterTruth(); public var running=true; public var unloaded=false; public var downstreamDemandSCFM=10.0; public var reliefFlowSCFM=80.0; public private(set) var regulatedPSI=0.0; public private(set) var transmitterMA=4.0; public init(){}
    public mutating func step(dt:Double){let production=(running && !unloaded) ? 90.0:0;let reliefLoss=relief.relieving(receiver.pressurePSI) ? reliefFlowSCFM:0;let netProduction=check.stuckClosed ? 0:production;receiver.leakSCFM=max(0,downstreamDemandSCFM+reliefLoss);receiver.step(compressorSCFM:netProduction,dt:dt);regulatedPSI=regulator.outlet(inlet:receiver.pressurePSI);transmitterMA=transmitter.milliamps(actualPSI:receiver.pressurePSI)}
}

public struct FaultDiscriminator: Sendable {
    public init(){}
    public func candidates(command:Bool,coilVolts:Double,pressurePSI:Double,valveOpen:Bool,cylinderMoving:Bool,inputFeedback:Bool)->[String] {
        var c:[String]=[]
        if command && coilVolts<18 {c.append("electrical output path")}
        if command && coilVolts>=18 && !valveOpen {c.append("solenoid coil/spool")}
        if valveOpen && pressurePSI<25 {c.append("pneumatic supply")}
        if valveOpen && pressurePSI>=25 && !cylinderMoving {c.append("cylinder/mechanical load")}
        if cylinderMoving && !inputFeedback {c.append("limit switch/input path")}
        return c
    }
}
