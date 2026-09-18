import Foundation
import ElectricalCore
import CircuitMNA

// MARK: - Rev63 Integrated I&E / Controls Simulation
// Physical models are intentionally educational/generic, not manufacturer/site acceptance criteria.

public struct EEImpulseLine63: Sendable, Codable, Equatable {
    public var processPressure: Double; public var pluggedFraction: Double; public var leakFraction: Double; public var trappedGasFraction: Double; public var sensedPressure: Double
    public init(processPressure:Double=100, pluggedFraction:Double=0, leakFraction:Double=0, trappedGasFraction:Double=0, sensedPressure:Double=100){self.processPressure=processPressure;self.pluggedFraction=pluggedFraction;self.leakFraction=leakFraction;self.trappedGasFraction=trappedGasFraction;self.sensedPressure=sensedPressure}
    public mutating func step(dt:Double){let restriction=max(0.02,1-pluggedFraction);let tau=0.15/restriction + 2.5*trappedGasFraction;let target=processPressure*(1-min(0.95,leakFraction));sensedPressure += (target-sensedPressure)*min(1,dt/max(0.01,tau))}
}

public struct EETransmitter63: Sendable, Codable, Equatable {
    public var lrv:Double; public var urv:Double; public var zeroShift:Double; public var spanFactor:Double; public var dampingSeconds:Double; public var outputMA:Double=4
    public init(lrv:Double=0,urv:Double=200,zeroShift:Double=0,spanFactor:Double=1,dampingSeconds:Double=0.2){self.lrv=lrv;self.urv=urv;self.zeroShift=zeroShift;self.spanFactor=spanFactor;self.dampingSeconds=dampingSeconds}
    public mutating func step(input:Double,dt:Double){let span=max(1e-9,urv-lrv);let fraction=min(1.05,max(-0.05,((input+zeroShift-lrv)/span)*spanFactor));let target=4+16*fraction;outputMA += (target-outputMA)*min(1,dt/max(0.001,dampingSeconds))}
}

public struct EELoopResult63: Sendable, Codable, Equatable { public var requestedMA:Double; public var actualMA:Double; public var transmitterVoltage:Double; public var complianceLimited:Bool; public var aiVoltage:Double }
public struct EECurrentLoop63: Sendable, Codable, Equatable {
    public var supplyV=24.0; public var wireOhms=20.0; public var barrierOhms=100.0; public var aiOhms=250.0; public var transmitterMinimumV=10.5
    public init(){}
    public func solve(requestedMA:Double) -> EELoopResult63 {
        let r=max(1e-9,wireOhms+barrierOhms+aiOhms);let maxA=max(0,(supplyV-transmitterMinimumV)/r);let requestedA=max(0,requestedMA/1000);let actualA=min(requestedA,maxA);let txV=supplyV-actualA*r
        return .init(requestedMA:requestedMA,actualMA:actualA*1000,transmitterVoltage:txV,complianceLimited:actualA+1e-12<requestedA,aiVoltage:actualA*aiOhms)
    }
    public func solveWithMNA(requestedMA:Double) throws -> EELoopResult63 {
        // Equivalent physical loop is solved through CircuitMNA to cross-check loop voltage/current truth.
        let requestedA=max(0,requestedMA/1000); let r=max(1e-9,wireOhms+barrierOhms+aiOhms)
        let maxA=max(0,(supplyV-transmitterMinimumV)/r); let actual=min(requestedA,maxA)
        let c=Circuit(nodeCount:3,resistors:[.init(a:1,b:2,resistance:r),.init(a:2,b:0,resistance:1e9)],currentSources:[.init(from:0,to:2,amperes:actual)],voltageSources:[.init(positive:1,negative:0,volts:supplyV)])
        let s=try ReferenceDCSolver().solve(c); let drop=s.nodeVoltages[1]-s.nodeVoltages[2]
        return .init(requestedMA:requestedMA,actualMA:actual*1000,transmitterVoltage:supplyV-drop,complianceLimited:actual+1e-12<requestedA,aiVoltage:actual*aiOhms)
    }
}

public struct EECalibrationPoint63: Sendable, Codable, Equatable { public var applied:Double; public var expectedMA:Double; public var observedMA:Double; public var errorPercentSpan:Double }
public struct EECalibrationBench63: Sendable, Codable, Equatable {
    public init(){}
    public func run(transmitter:EETransmitter63, points:[Double]=[0,0.25,0.5,0.75,1,0.5,0]) -> [EECalibrationPoint63] { let span=max(1e-9,transmitter.urv-transmitter.lrv);return points.map{f in let input=transmitter.lrv+span*f;let observed=4+16*min(1.05,max(-0.05,((input+transmitter.zeroShift-transmitter.lrv)/span)*transmitter.spanFactor));let expected=4+16*f;return .init(applied:input,expectedMA:expected,observedMA:observed,errorPercentSpan:(observed-expected)/16*100)} }
}

public struct EEValvePositioner63: Sendable, Codable, Equatable {
    public var command=0.0; public var position=0.0; public var stiction=0.03; public var airSupply=1.0; public var feedbackBias=0.0
    public init(){}
    public mutating func step(dt:Double){guard airSupply>0.15 else{return};let error=command-position;if abs(error)>stiction{position += error*min(1,dt*4*airSupply)};position=min(1,max(0,position))}
    public var indicatedPosition:Double { min(1,max(0,position+feedbackBias)) }
}

public struct EEPLCScan63: Sendable, Codable, Equatable {
    public var rawAI:Int=0; public var engineeringValue=0.0; public var scaleRawMin=0; public var scaleRawMax=32767; public var euMin=0.0; public var euMax=200.0; public var permissive=true; public var runRequest=false; public var output=false; public var scanCount=0
    public init(){}
    public mutating func scan(){let f=Double(rawAI-scaleRawMin)/Double(max(1,scaleRawMax-scaleRawMin));engineeringValue=euMin+f*(euMax-euMin);output=runRequest && permissive;scanCount += 1}
}

public struct EENetwork63: Sendable, Codable, Equatable {
    public var packetLoss=0.0; public var duplicateAddress=false; public var latencyMS=2.0; public var clockOffsetMS=0.0
    public init(){}
    public func delivered(sequence:Int)->Bool { guard !duplicateAddress else{return sequence % 3 != 0};let threshold=Int(min(100,max(0,packetLoss*100)));return ((sequence &* 37 &+ 11) % 100) >= threshold }
}
public struct EECANPhysical63: Sendable, Codable, Equatable {
    public var terminationA=120.0; public var terminationB=120.0; public var addedShuntOhms:Double?=nil; public var commonModeOffsetV=0.0
    public init(){}
    public var measuredResistance:Double { let base=1/(1/terminationA+1/terminationB);guard let s=addedShuntOhms else{return base};return 1/(1/base+1/s) }
    public var healthyTermination:Bool { measuredResistance > 50 && measuredResistance < 70 }
}

public enum EEReplayChannel63:String,Sendable,Codable,CaseIterable { case process, loopMA, rawAI, engineering, permissive, output, hmi, historian, network }
public struct EEReplayFrame63: Identifiable,Sendable,Codable,Equatable { public var id:Int; public var time:Double; public var values:[EEReplayChannel63:Double]; public init(id:Int,time:Double,values:[EEReplayChannel63:Double]){self.id=id;self.time=time;self.values=values} }
public struct EEForensicReplay63: Sendable,Codable,Equatable {
    public var frames:[EEReplayFrame63]=[]; public init(){}
    public mutating func append(time:Double,values:[EEReplayChannel63:Double]){frames.append(.init(id:frames.count,time:time,values:values))}
    public func firstDivergence(_ a:EEReplayChannel63,_ b:EEReplayChannel63,tolerance:Double)->EEReplayFrame63?{frames.first{f in guard let x=f.values[a],let y=f.values[b] else{return false};return abs(x-y)>tolerance}}
}

public struct EEIntegratedLoopRig63: Sendable,Codable,Equatable {
    public var impulse=EEImpulseLine63(); public var transmitter=EETransmitter63(); public var loop=EECurrentLoop63(); public var plc=EEPLCScan63(); public var network=EENetwork63(); public var replay=EEForensicReplay63(); public var time=0.0
    public init(){}
    public mutating func step(dt:Double){time += dt;impulse.step(dt:dt);transmitter.step(input:impulse.sensedPressure,dt:dt);let lr=loop.solve(requestedMA:transmitter.outputMA);plc.rawAI=Int((lr.actualMA-4)/16*32767);plc.scan();let delivered=network.delivered(sequence:plc.scanCount);let hmi=delivered ? plc.engineeringValue : (replay.frames.last?.values[.hmi] ?? plc.engineeringValue);replay.append(time:time,values:[.process:impulse.processPressure,.loopMA:lr.actualMA,.rawAI:Double(plc.rawAI),.engineering:plc.engineeringValue,.permissive:plc.permissive ? 1:0,.output:plc.output ? 1:0,.hmi:hmi,.historian:plc.engineeringValue,.network:delivered ? 1:0])}
}

public struct EEQualificationBoard63: Sendable,Codable,Equatable {
    public var rig=EEIntegratedLoopRig63(); public var valve=EEValvePositioner63(); public var can=EECANPhysical63(); public var evidence:[EEDiagnosticObservation62]=[]; public var diagnosed=false; public var repaired=false; public var recommissioned=false; public var documented=false
    public init(){}
    public var complete:Bool { diagnosed && repaired && recommissioned && documented && evidence.count>=6 }
}
public struct EERev63IntegratedIEControlsSimulation: Sendable,Codable { public var base=EERev62PhysicalIEControlsQualification(); public var board=EEQualificationBoard63(); public init(){} }
