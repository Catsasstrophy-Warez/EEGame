import Foundation

public typealias NodeID = Int

public struct Resistor: Sendable, Codable, Equatable { public var a: NodeID; public var b: NodeID; public var resistance: Double; public init(a: NodeID,b: NodeID,resistance: Double){precondition(resistance>0);self.a=a;self.b=b;self.resistance=resistance} }
public struct CurrentSource: Sendable, Codable, Equatable { public var from: NodeID; public var to: NodeID; public var amperes: Double; public init(from: NodeID,to: NodeID,amperes: Double){self.from=from;self.to=to;self.amperes=amperes} }
public struct VoltageSource: Sendable, Codable, Equatable { public var positive: NodeID; public var negative: NodeID; public var volts: Double; public init(positive: NodeID,negative: NodeID,volts: Double){self.positive=positive;self.negative=negative;self.volts=volts} }

public struct Circuit: Sendable, Codable, Equatable {
    public var nodeCount: Int; public var resistors:[Resistor]; public var currentSources:[CurrentSource]; public var voltageSources:[VoltageSource]
    public init(nodeCount:Int,resistors:[Resistor]=[],currentSources:[CurrentSource]=[],voltageSources:[VoltageSource]=[]){precondition(nodeCount>=1);self.nodeCount=nodeCount;self.resistors=resistors;self.currentSources=currentSources;self.voltageSources=voltageSources}
}

public enum SolverTermination: String, Sendable, Codable { case converged, singular, nonFinite, iterationLimit }
public struct SolverReport: Sendable, Equatable { public var termination:SolverTermination; public var iterations:Int; public var residual:Double; public var unknownCount:Int; public init(termination:SolverTermination,iterations:Int,residual:Double,unknownCount:Int){self.termination=termination;self.iterations=iterations;self.residual=residual;self.unknownCount=unknownCount} }
public struct ElectricalSnapshot: Sendable, Equatable { public var nodeVoltages:[Double]; public var voltageSourceCurrents:[Double]; public var report:SolverReport; public var converged:Bool { report.termination == .converged }; public var residual:Double { report.residual }; public init(nodeVoltages:[Double],voltageSourceCurrents:[Double]=[],report:SolverReport){self.nodeVoltages=nodeVoltages;self.voltageSourceCurrents=voltageSourceCurrents;self.report=report} }

public enum FaultPrimitive: Sendable, Codable, Equatable { case openCircuit; case shortCircuit(resistance:Double); case highResistance(extraOhms:Double); case insulationLeakage(toGroundOhms:Double); case intermittentOpen(dutyCycle:Double) }

public struct ThermalState: Sendable, Codable, Equatable { public var temperatureC:Double; public var ambientC:Double; public var thermalMassJPerC:Double; public var coolingWPerC:Double; public init(temperatureC:Double=25,ambientC:Double=25,thermalMassJPerC:Double=20,coolingWPerC:Double=0.2){self.temperatureC=temperatureC;self.ambientC=ambientC;self.thermalMassJPerC=thermalMassJPerC;self.coolingWPerC=coolingWPerC}; public mutating func step(powerWatts:Double,dt:Double){let cooling=max(0,temperatureC-ambientC)*coolingWPerC;temperatureC += (powerWatts-cooling)*dt/max(thermalMassJPerC,1e-9)} }

public enum MeterMode: Sendable { case dcVolts, resistance }
public struct DigitalMultimeter: Sendable { public var inputResistanceOhms:Double = 10_000_000; public init(){}; public func dcVoltage(red:NodeID,black:NodeID,in snapshot:ElectricalSnapshot)->Double?{guard red>=0,black>=0,red<snapshot.nodeVoltages.count,black<snapshot.nodeVoltages.count else{return nil};return snapshot.nodeVoltages[red]-snapshot.nodeVoltages[black]} }

public struct FuseModel: Sendable, Codable, Equatable {
    public var ratedCurrent:Double; public var accumulatedI2t:Double=0; public var tripI2t:Double; public var isOpen=false
    public init(ratedCurrent:Double,tripI2t:Double){self.ratedCurrent=ratedCurrent;self.tripI2t=tripI2t}
    public mutating func step(current:Double,dt:Double){guard !isOpen else{return};let excess=max(0,current*current-ratedCurrent*ratedCurrent);accumulatedI2t += excess*dt;if accumulatedI2t>=tripI2t{isOpen=true}}
}
public struct ConductorPhysics: Sendable, Codable, Equatable {
    public var baseResistance:Double; public var alpha:Double=0.00393; public var referenceC:Double=20; public var thermal:ThermalState
    public init(baseResistance:Double,thermal: ThermalState = .init()){self.baseResistance=baseResistance;self.thermal=thermal}
    public var resistance:Double {max(1e-12,baseResistance*(1+alpha*(thermal.temperatureC-referenceC)))}
    public mutating func step(current:Double,dt:Double){thermal.step(powerWatts:current*current*resistance,dt:dt)}
}
public struct DCMotorState: Sendable, Codable, Equatable {
    public var rpm=0.0; public var temperatureC=25.0
    public init() {}
    public mutating func step(voltage:Double,load:Double,dt:Double){let target=max(0,voltage/24*1800*(1-min(max(load,0),0.95)));rpm += (target-rpm)*min(1,dt/0.25);temperatureC += max(0,load)*dt*0.08}
}

public enum MeterJack: String, Sendable, Codable { case common, voltsOhms, current }
public enum AdvancedMeterMode: String, Sendable, Codable { case dcVolts, dcAmps, resistance }
public struct MeterFuseState: Sendable, Codable, Equatable {
    public var ratedAmps: Double = 0.5; public var accumulatedI2t: Double = 0; public var tripI2t: Double = 0.08; public var isOpen = false
    public init() {}
    public mutating func step(current: Double, dt: Double) { guard !isOpen else { return }; let e=max(0,current*current-ratedAmps*ratedAmps); accumulatedI2t += e*dt; if accumulatedI2t >= tripI2t { isOpen=true } }
}
public struct PhysicalMultimeter: Sendable, Codable, Equatable {
    public var mode: AdvancedMeterMode = .dcVolts; public var redJack: MeterJack = .voltsOhms; public var blackJack: MeterJack = .common
    public var voltageInputOhms: Double = 10_000_000; public var currentShuntOhms: Double = 0.1; public var currentFuse = MeterFuseState()
    public init() {}
    public var isLeadConfigurationValid: Bool { blackJack == .common && ((mode == .dcAmps && redJack == .current) || (mode != .dcAmps && redJack == .voltsOhms)) }
    public func voltageLoad(red: NodeID, black: NodeID) -> Resistor? { guard mode == .dcVolts, isLeadConfigurationValid else { return nil }; return .init(a:red,b:black,resistance:voltageInputOhms) }
    public mutating func currentAcross(voltage: Double, dt: Double) -> Double? { guard mode == .dcAmps, isLeadConfigurationValid, !currentFuse.isOpen else { return nil }; let i=voltage/max(currentShuntOhms,1e-9); currentFuse.step(current:i,dt:dt); return i }
}
