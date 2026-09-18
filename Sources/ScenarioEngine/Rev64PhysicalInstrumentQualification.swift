import Foundation
import ElectricalCore
import CircuitMNA

// MARK: - Rev64 Physical Instrument / Qualification Runtime
// Educational simulation models. They are not site procedures or manufacturer acceptance criteria.

public enum EEInstrumentMode64: String, Sendable, Codable, CaseIterable { case dcVolts, dcMilliamps, ohms, loopMeasure, loopSource, loopSimulate, pressureMeasure, hart, scope, packetCapture, canPhysical }
public enum EEProbeRole64: String, Sendable, Codable { case red, black, clamp, process, communication }
public struct EEProbePlacement64: Sendable, Codable, Equatable { public var role:EEProbeRole64; public var point:String; public init(_ role:EEProbeRole64,_ point:String){self.role=role;self.point=point} }
public struct EEInstrumentReading64: Sendable, Codable, Equatable { public var value:Double?; public var unit:String; public var valid:Bool; public var explanation:String; public init(value:Double?,unit:String,valid:Bool,explanation:String){self.value=value;self.unit=unit;self.valid=valid;self.explanation=explanation} }

public struct EEVirtualInstrument64: Sendable, Codable, Equatable {
    public var mode:EEInstrumentMode64 = .dcVolts
    public var placements:[EEProbePlacement64] = []
    public var sourceMA:Double = 12
    public var inputOhms:Double = 10_000_000
    public var burdenOhms:Double = 12
    public var fuseHealthy=true
    public init(){}
    public mutating func place(_ role:EEProbeRole64, at point:String){placements.removeAll{$0.role==role};placements.append(.init(role,point))}
    public mutating func clear(){placements.removeAll()}
    public func measure(board:EEQualificationBoard63) -> EEInstrumentReading64 {
        let points=Dictionary(uniqueKeysWithValues:placements.map{($0.role,$0.point)})
        switch mode {
        case .dcVolts:
            guard points[.red] != nil, points[.black] != nil else{return .init(value:nil,unit:"V",valid:false,explanation:"Two voltage probes are required.")}
            let lr=board.rig.loop.solve(requestedMA:board.rig.transmitter.outputMA)
            return .init(value:lr.transmitterVoltage,unit:"V DC",valid:true,explanation:"Simulation-backed loop voltage")
        case .dcMilliamps,.loopMeasure:
            guard fuseHealthy else{return .init(value:nil,unit:"mA",valid:false,explanation:"Current input fuse is open.")}
            guard points[.red] != nil, points[.black] != nil else{return .init(value:nil,unit:"mA",valid:false,explanation:"Series insertion points are required.")}
            let lr=board.rig.loop.solve(requestedMA:board.rig.transmitter.outputMA)
            return .init(value:lr.actualMA,unit:"mA",valid:true,explanation:"Loop current from physical loop solver")
        case .ohms:
            guard points[.red] != nil, points[.black] != nil else{return .init(value:nil,unit:"Ω",valid:false,explanation:"Two resistance probes are required.")}
            return .init(value:board.can.measuredResistance,unit:"Ω",valid:true,explanation:"De-energized CAN termination model")
        case .loopSource,.loopSimulate:
            return .init(value:sourceMA,unit:"mA",valid:true,explanation:"Calibrator source/simulate setpoint")
        case .pressureMeasure:
            guard points[.process] != nil else{return .init(value:nil,unit:"process",valid:false,explanation:"Connect to a process test point.")}
            return .init(value:board.rig.impulse.sensedPressure,unit:"pressure",valid:true,explanation:"Impulse-system sensed pressure")
        case .hart:
            guard points[.communication] != nil else{return .init(value:nil,unit:"",valid:false,explanation:"Communication connection required.")}
            return .init(value:board.rig.transmitter.outputMA,unit:"mA PV output",valid:true,explanation:"Generic smart-transmitter diagnostic channel")
        case .scope:
            return .init(value:Double(board.rig.plc.scanCount),unit:"samples",valid:true,explanation:"Acquisition tied to synchronized simulation frames")
        case .packetCapture:
            return .init(value:board.rig.network.packetLoss*100,unit:"% loss",valid:true,explanation:"Deterministic communications model")
        case .canPhysical:
            return .init(value:board.can.measuredResistance,unit:"Ω",valid:true,explanation:"Physical CAN termination model")
        }
    }
}

public struct EEManifold64: Sendable, Codable, Equatable {
    public var highOpen=true; public var lowOpen=true; public var equalizeOpen=false; public var ventOpen=false
    public init(){}
    public mutating func apply(to impulse:inout EEImpulseLine63){
        if equalizeOpen { impulse.processPressure *= 0.5 }
        if ventOpen { impulse.processPressure *= 0.15 }
        if !highOpen || !lowOpen { impulse.pluggedFraction=max(impulse.pluggedFraction,0.85) }
    }
}

public struct EECalibrationSession64: Sendable, Codable, Equatable {
    public var appliedFractions:[Double]=[0,0.25,0.5,0.75,1,0.5,0]
    public var asFound:[EECalibrationPoint63]=[]; public var asLeft:[EECalibrationPoint63]=[]
    public init(){}
    public mutating func captureAsFound(_ tx:EETransmitter63){asFound=EECalibrationBench63().run(transmitter:tx,points:appliedFractions)}
    public mutating func captureAsLeft(_ tx:EETransmitter63){asLeft=EECalibrationBench63().run(transmitter:tx,points:appliedFractions)}
    public var maxAsLeftError:Double { asLeft.map{abs($0.errorPercentSpan)}.max() ?? .infinity }
}

public struct EEPLCScanTrace64: Identifiable, Sendable, Codable, Equatable { public var id:Int; public var raw:Int; public var engineering:Double; public var permissive:Bool; public var request:Bool; public var output:Bool }
public struct EEPLCScanMicroscope64: Sendable, Codable, Equatable {
    public var traces:[EEPLCScanTrace64]=[]; public init(){}
    public mutating func capture(_ plc:EEPLCScan63){traces.append(.init(id:traces.count,raw:plc.rawAI,engineering:plc.engineeringValue,permissive:plc.permissive,request:plc.runRequest,output:plc.output))}
}

public enum EETruthLayer64:String,Sendable,Codable,CaseIterable { case process, impulse, transmitter, loop, rawIO, scaling, logic, network, hmi, historian }
public struct EEFirstDivergence64: Sendable,Codable,Equatable { public var layer:EETruthLayer64; public var reason:String }
public enum EEFirstDivergenceAnalyzer64 {
    public static func analyze(_ b:EEQualificationBoard63) -> EEFirstDivergence64? {
        let r=b.rig
        if abs(r.impulse.processPressure-r.impulse.sensedPressure)>5 { return .init(layer:.impulse,reason:"Process and impulse-system sensed pressure disagree.") }
        let ideal=4+16*((r.impulse.sensedPressure-r.transmitter.lrv)/max(1e-9,r.transmitter.urv-r.transmitter.lrv))
        if abs(ideal-r.transmitter.outputMA)>0.5 { return .init(layer:.transmitter,reason:"Transmitter output disagrees with sensed pressure and configured range.") }
        let lr=r.loop.solve(requestedMA:r.transmitter.outputMA)
        if abs(lr.actualMA-r.transmitter.outputMA)>0.2 { return .init(layer:.loop,reason:"Delivered loop current differs from transmitter request.") }
        let expectedRaw=Int((lr.actualMA-4)/16*32767)
        if abs(expectedRaw-r.plc.rawAI)>100 { return .init(layer:.rawIO,reason:"PLC raw input disagrees with loop current.") }
        let f=Double(r.plc.rawAI-r.plc.scaleRawMin)/Double(max(1,r.plc.scaleRawMax-r.plc.scaleRawMin)); let expectedEU=r.plc.euMin+f*(r.plc.euMax-r.plc.euMin)
        if abs(expectedEU-r.plc.engineeringValue)>0.5 { return .init(layer:.scaling,reason:"Engineering value disagrees with raw input scaling.") }
        if let last=r.replay.frames.last, last.values[.network] == 0 { return .init(layer:.network,reason:"Latest representation update was not delivered.") }
        if let last=r.replay.frames.last, let h=last.values[.hmi], abs(h-r.plc.engineeringValue)>0.5 { return .init(layer:.hmi,reason:"HMI representation differs from controller engineering value.") }
        return nil
    }
}

public struct EEQualificationRuntime64: Sendable,Codable,Equatable {
    public var board=EEQualificationBoard63(); public var instrument=EEVirtualInstrument64(); public var manifold=EEManifold64(); public var calibration=EECalibrationSession64(); public var microscope=EEPLCScanMicroscope64(); public var selectedTime=0.0
    public init(){}
    public mutating func tick(dt:Double){manifold.apply(to:&board.rig.impulse);board.rig.step(dt:dt);microscope.capture(board.rig.plc);selectedTime=board.rig.time}
    public mutating func captureEvidence(id:String){let reading=instrument.measure(board:board);board.evidence.append(.init(id:id,time:board.rig.time,testPointID:instrument.placements.first?.point ?? "unplaced",evidence:.voltage,value:reading.value,text:reading.explanation,provenance:"Rev64 simulation truth"))}
}

public struct EEScenarioDefinition64: Sendable,Codable,Equatable {
    public var id:String; public var title:String; public var assets:[String]; public var faultFamilies:[String]; public var documents:[String]; public var instruments:[EEInstrumentMode64]; public var seed:Int
    public init(id:String,title:String,assets:[String],faultFamilies:[String],documents:[String],instruments:[EEInstrumentMode64],seed:Int){self.id=id;self.title=title;self.assets=assets;self.faultFamilies=faultFamilies;self.documents=documents;self.instruments=instruments;self.seed=seed}
}
public enum EEScenarioLoader64 { public static func decode(_ data:Data)throws->[EEScenarioDefinition64]{try JSONDecoder().decode([EEScenarioDefinition64].self,from:data)} }

public struct EERev64PhysicalInstrumentQualification: Sendable,Codable { public var base=EERev63IntegratedIEControlsSimulation(); public var runtime=EEQualificationRuntime64(); public init(){} }
