import Foundation
import ElectricalCore
import CircuitMNA

public enum IOTruthFault: String, Sendable, Codable, Equatable { case none, openConductor, shortToCommon, shortToSupply, highResistance, blownFuse, failedChannel, forced, staleNetwork }
public struct DigitalInputElectricalModel: Sendable, Equatable {
    public var supplyVolts=24.0; public var fieldClosed=false; public var seriesResistanceOhms=4.0; public var inputResistanceOhms=3_000.0
    public var thresholdOnVolts=15.0; public var thresholdOffVolts=5.0; public var fault:IOTruthFault = .none; public var forcedState:Bool?
    public init(){}
    public func terminalVoltage() -> Double {
        if fault == .blownFuse || fault == .openConductor { return 0 }
        if fault == .shortToCommon { return 0 }
        if fault == .shortToSupply { return supplyVolts }
        guard fieldClosed else { return 0 }
        let r = seriesResistanceOhms + (fault == .highResistance ? 2_000 : 0)
        return supplyVolts * inputResistanceOhms / (inputResistanceOhms + r)
    }
    public func observed(previous:Bool=false) -> Bool {
        if let forcedState { return forcedState }
        if fault == .failedChannel { return false }
        let v=terminalVoltage(); if previous { return v > thresholdOffVolts }; return v >= thresholdOnVolts
    }
}

public struct AnalogInputElectricalModel: Sendable, Equatable {
    public var loopMilliamps=12.0; public var shuntOhms=250.0; public var adcFullScaleVolts=5.0; public var adcCounts=32767.0; public var fault:IOTruthFault = .none; public var leakageMilliamps=0.0
    public init(){}
    public var effectiveMilliamps:Double { switch fault { case .openConductor,.blownFuse: return 0; case .shortToCommon: return 0; case .shortToSupply: return 22; default: return max(0,loopMilliamps+leakageMilliamps) } }
    public var terminalVolts:Double { effectiveMilliamps/1000 * shuntOhms }
    public var rawCounts:Int { Int((min(adcFullScaleVolts,max(0,terminalVolts))/adcFullScaleVolts*adcCounts).rounded()) }
}

public enum TruthLayer: String, CaseIterable, Sendable, Codable { case process, sensor, transmitter, fieldCable, barrier, ioTerminal, adc, plcEngineering, network, hmi }
public struct TruthObservation: Sendable, Equatable { public var layer:TruthLayer; public var value:Double; public init(_ layer:TruthLayer,_ value:Double){self.layer=layer;self.value=value} }
public struct GoldenThreadTrace: Sendable, Equatable {
    public var observations:[TruthObservation]; public var tolerance:Double
    public init(_ observations:[TruthObservation],tolerance:Double=0.01){self.observations=observations;self.tolerance=tolerance}
    public var firstDivergence:TruthLayer? { guard let first=observations.first else{return nil}; return observations.dropFirst().first{abs($0.value-first.value)>tolerance}?.layer }
}

public struct PanelPointToPoint: Sendable, Equatable { public var from:String;public var to:String;public var wireNumber:String;public var continuityOhms:Double; public init(from:String,to:String,wireNumber:String,continuityOhms:Double=0.05){self.from=from;self.to=to;self.wireNumber=wireNumber;self.continuityOhms=continuityOhms} }
public struct PanelNetlist: Sendable, Equatable {
    public var connections:[PanelPointToPoint]=[]; public init(){}
    public mutating func land(from:String,to:String,wireNumber:String,resistance:Double=0.05){connections.append(.init(from:from,to:to,wireNumber:wireNumber,continuityOhms:resistance))}
    public func connected(_ a:String,_ b:String,maxOhms:Double=1) -> Bool { connections.contains{(($0.from==a && $0.to==b)||($0.from==b && $0.to==a)) && $0.continuityOhms<=maxOhms} }
}

public struct EventLocalizedStepper: Sendable, Equatable {
    public var tolerance=1e-6; public init(){}
    public func crossingTime(t0:Double,t1:Double,f0:Double,f1:Double,target:Double) -> Double? { let a=f0-target,b=f1-target; guard a==0 || b==0 || a.sign != b.sign else{return nil}; if abs(f1-f0)<tolerance{return t0}; let u=(target-f0)/(f1-f0); return t0+(t1-t0)*min(1,max(0,u)) }
}

public struct NonlinearDiode: Sendable, Equatable { public var saturationCurrent=1e-12;public var thermalVoltage=0.02585;public init(){};public func current(voltage:Double)->Double{saturationCurrent*(exp(min(40,voltage/thermalVoltage))-1)};public func conductance(voltage:Double)->Double{saturationCurrent/thermalVoltage*exp(min(40,voltage/thermalVoltage))} }
public struct DiodeNewtonSolver: Sendable, Equatable {
    public var maxIterations=50;public var tolerance=1e-9;public init(){}
    public func solve(sourceVolts:Double,seriesOhms:Double,diode:NonlinearDiode = .init()) -> (voltage:Double,iterations:Int,converged:Bool) { var v=min(0.7,max(0,sourceVolts)); for i in 1...maxIterations { let e=exp(min(40,v/diode.thermalVoltage)); let f=(sourceVolts-v)/seriesOhms-diode.saturationCurrent*(e-1); let df = -1/seriesOhms-diode.saturationCurrent/diode.thermalVoltage*e; let nv=v-f/df; if abs(nv-v)<tolerance{return(nv,i,true)};v=min(sourceVolts,max(-5,nv)) };return(v,maxIterations,false) }
}

public struct Rev15CopperToHMI: Sendable {
    public var digital=DigitalInputElectricalModel(); public var analog=AnalogInputElectricalModel(); public var processValue=50.0; public init(){}
    public mutating func trace() -> GoldenThreadTrace { analog.loopMilliamps=4+16*processValue/100; let engineering=max(0,min(100,(Double(analog.rawCounts)/analog.adcCounts*analog.adcFullScaleVolts/analog.shuntOhms*1000-4)/16*100)); return GoldenThreadTrace([.init(.process,processValue),.init(.sensor,processValue),.init(.transmitter,processValue),.init(.fieldCable,processValue),.init(.barrier,processValue),.init(.ioTerminal,engineering),.init(.adc,engineering),.init(.plcEngineering,engineering),.init(.network,engineering),.init(.hmi,engineering)],tolerance:1) }
}
