import Foundation
import ElectricalCore
import CircuitMNA

// Rev20: field instrumentation, final control, Murphy MX5-style I/O modules,
// and burner-management simulation. Models are educational/vendor-aware abstractions,
// not certified safety-system implementations.

public enum InstrumentTagKind: String, Sendable, Codable, CaseIterable { case TIT, PIT, FIT, LIT }
public enum InstrumentFault: String, Sendable, Codable, Hashable { case sensorDrift, openLoop, shortLoop, upscaleAlarm, downscaleAlarm, pluggedImpulse, frozenPV, badScaling, lowLoopPower }

public struct IndicatingTransmitter: Sendable, Codable {
    public var tag: String
    public var kind: InstrumentTagKind
    public var lrv: Double
    public var urv: Double
    public var processValue: Double = 0
    public var indicatedValue: Double = 0
    public var driftEngineering: Double = 0
    public var dampingSeconds: Double = 0.25
    public var loopSupplyV: Double = 24
    public var burdenOhms: Double = 250
    public var faults: Set<InstrumentFault> = []
    private var frozenValue: Double?
    public init(tag:String, kind:InstrumentTagKind, lrv:Double, urv:Double){self.tag=tag;self.kind=kind;self.lrv=lrv;self.urv=urv}
    public mutating func step(actual:Double, dt:Double){
        processValue=actual
        if faults.contains(.frozenPV) || faults.contains(.pluggedImpulse) { if frozenValue == nil { frozenValue=indicatedValue }; return } else { frozenValue=nil }
        let target=actual+driftEngineering
        let a=dampingSeconds <= 0 ? 1 : min(1,dt/dampingSeconds)
        indicatedValue += (target-indicatedValue)*a
    }
    public var milliAmps: Double {
        if faults.contains(.openLoop) { return 0 }
        if faults.contains(.downscaleAlarm) { return 3.6 }
        if faults.contains(.upscaleAlarm) { return 21.5 }
        let span=max(1e-9,urv-lrv); let pct=min(1,max(0,(indicatedValue-lrv)/span)); let commanded=4+16*pct
        let compliance=max(0,loopSupplyV-12)/max(1,burdenOhms)*1000
        return min(commanded,compliance)
    }
}

public enum FlowTechnology: String, Sendable, Codable { case differentialPressure, magnetic, coriolis, vortex, turbine }
public struct FlowMeterTruth: Sendable, Codable {
    public var tag:String; public var technology:FlowTechnology; public var maxFlow:Double; public var actualFlow:Double=0; public var zeroOffset:Double=0; public var pluggedPrimary=false
    public init(tag:String="FIT-101",technology:FlowTechnology = .differentialPressure,maxFlow:Double=100){self.tag=tag;self.technology=technology;self.maxFlow=maxFlow}
    public var measuredFlow:Double { pluggedPrimary ? 0 : max(0,actualFlow+zeroOffset) }
    public var milliAmps:Double { 4+16*min(1,measuredFlow/max(1e-9,maxFlow)) }
}

public enum IPFault:String,Sendable,Codable{case none,noAir,pluggedNozzle,outputLeak,coilOpen,miscalibrated}
public struct I2PTransducer:Sendable,Codable{
    public var inputMA=4.0; public var supplyPSI=20.0; public var fault:IPFault = .none; public var zeroPSI=3.0; public var spanPSI=12.0
    public init(){}
    public var outputPSI:Double { if fault == .noAir || fault == .coilOpen{return 0}; let p=min(1,max(0,(inputMA-4)/16)); var out=zeroPSI+spanPSI*p; if fault == .outputLeak{out*=0.45};if fault == .pluggedNozzle{out=min(out,5)};if fault == .miscalibrated{out+=2};return min(supplyPSI,max(0,out)) }
}

public enum DVCFault:String,Sendable,Codable,Hashable{case airSupplyLow,travelFeedbackFault,stuckValve,excessFriction,loopOpen}
public struct DVCValveController:Sendable,Codable{
    public var commandMA=4.0; public var supplyPSI=30.0; public var travelPercent=0.0; public var faults:Set<DVCFault>=[]; public var friction=0.03; public var hartHealthy=true
    public init(){}
    public mutating func step(dt:Double){ guard !faults.contains(.loopOpen) else{return}; let desired=min(100,max(0,(commandMA-4)/16*100)); if faults.contains(.stuckValve){return}; let airFactor=min(1,max(0,supplyPSI/20)); let frictionPenalty=faults.contains(.excessFriction) ? 0.2:1; let rate=80*airFactor*frictionPenalty; let delta=min(abs(desired-travelPercent),rate*dt);travelPercent += desired>=travelPercent ? delta:-delta }
    public var deviationPercent:Double { abs(min(100,max(0,(commandMA-4)/16*100))-travelPercent) }
    public var diagnosticAlert:Bool { faults.contains(.travelFeedbackFault) || deviationPercent>10 || supplyPSI<15 }
}

public enum MX5ChannelType:String,Sendable,Codable{case digitalInput,digitalOutput,analogInput,thermocouple,frequency}
public struct MX5Channel:Sendable,Codable,Equatable{public var name:String;public var type:MX5ChannelType;public var value:Double=0;public var forced:Double?;public init(_ name:String,_ type:MX5ChannelType){self.name=name;self.type=type}; public var effective:Double{forced ?? value}}
public struct MX5Module:Sendable,Codable{
    public var nodeID:Int; public var canTermination=false; public var rs485Termination=false; public var online=true; public var channels:[MX5Channel]
    public init(nodeID:Int=1,channels:[MX5Channel]=[]){self.nodeID=nodeID;self.channels=channels}
    public func validate(on bus:[MX5Module])->[String]{var x:[String]=[];if bus.filter({$0.nodeID==nodeID}).count>1{x.append("duplicate node id")};if bus.filter(\.canTermination).count != 1{x.append("CAN termination count")};return x}
}

public enum FlameState:String,Sendable,Codable{case absent,pilot,main}
public enum BurnerTrip:String,Sendable,Codable,Hashable{case esd,highTemperature,highPressure,lowPressure,lowLevel,proofOfClosure,flameFailure,ignitionFailure}
public enum BurnerPhase:String,Sendable,Codable{case idle,precheck,ignition,pilotProve,mainTrial,running,shutdown,lockout}
public struct BurnerInputs:Sendable,Codable{public var start=false;public var esdHealthy=true;public var proofOfClosure=true;public var highPressureOK=true;public var lowPressureOK=true;public var levelOK=true;public var highTempOK=true;public var flame:FlameState = .absent;public init(){}}
public struct BurnerOutputs:Sendable,Codable,Equatable{public var ignition=false;public var pilot=false;public var main=false;public var status=false;public init(){}}
public struct BurnerEvent:Sendable,Codable,Equatable{public var time:Double;public var text:String;public init(_ t:Double,_ s:String){time=t;text=s}}

public struct BurnerManagementSystem:Sendable,Codable{
    public var phase:BurnerPhase = .idle; public var inputs=BurnerInputs(); public var outputs=BurnerOutputs(); public var trips:Set<BurnerTrip>=[]; public var time=0.0; public var phaseTime=0.0; public var events:[BurnerEvent]=[]
    public var ignitionTrialSeconds=2.0; public var pilotProveSeconds=0.5; public var mainTrialSeconds=2.0
    public init(){}
    mutating func transition(_ p:BurnerPhase,_ why:String){phase=p;phaseTime=0;events.append(.init(time,"\(p.rawValue): \(why)"))}
    public mutating func step(dt:Double){time+=dt;phaseTime+=dt
        if !inputs.esdHealthy {trip(.esd);return};if !inputs.highTempOK{trip(.highTemperature);return};if !inputs.highPressureOK{trip(.highPressure);return};if !inputs.lowPressureOK{trip(.lowPressure);return};if !inputs.levelOK{trip(.lowLevel);return}
        switch phase {
        case .idle: outputs=BurnerOutputs(); if inputs.start{transition(.precheck,"start request")}
        case .precheck: if !inputs.proofOfClosure{trip(.proofOfClosure)} else {outputs.ignition=true;outputs.pilot=true;transition(.ignition,"permissives proven")}
        case .ignition: outputs.ignition=true;outputs.pilot=true;if inputs.flame == .pilot || inputs.flame == .main{transition(.pilotProve,"pilot flame detected")}else if phaseTime>=ignitionTrialSeconds{trip(.ignitionFailure)}
        case .pilotProve: outputs.pilot=true;if inputs.flame == .absent{trip(.flameFailure)}else if phaseTime>=pilotProveSeconds{outputs.main=true;transition(.mainTrial,"pilot proven")}
        case .mainTrial: outputs.pilot=true;outputs.main=true;if inputs.flame == .main{outputs.status=true;transition(.running,"main flame proven")}else if phaseTime>=mainTrialSeconds{trip(.flameFailure)}
        case .running: outputs.pilot=true;outputs.main=true;outputs.status=true;if inputs.flame == .absent{trip(.flameFailure)};if !inputs.start{transition(.shutdown,"stop request")}
        case .shutdown: outputs=BurnerOutputs();transition(.idle,"outputs safe")
        case .lockout: outputs=BurnerOutputs()
        }
    }
    public mutating func trip(_ reason:BurnerTrip){trips.insert(reason);outputs=BurnerOutputs();if phase != .lockout{transition(.lockout,"trip \(reason.rawValue)")}}
    public mutating func reset(){guard inputs.esdHealthy && inputs.highTempOK && inputs.highPressureOK && inputs.lowPressureOK && inputs.levelOK else{return};trips=[];outputs=BurnerOutputs();transition(.idle,"manual reset")}
}

public struct BurnerTrain:Sendable,Codable{
    public var processTIT=IndicatingTransmitter(tag:"TIT-201",kind:.TIT,lrv:0,urv:1200)
    public var fuelPIT=IndicatingTransmitter(tag:"PIT-202",kind:.PIT,lrv:0,urv:30)
    public var vesselLIT=IndicatingTransmitter(tag:"LIT-203",kind:.LIT,lrv:0,urv:100)
    public var fuelFIT=FlowMeterTruth(tag:"FIT-204",technology:.differentialPressure,maxFlow:100)
    public var fuelValve=DVCValveController(); public var legacyI2P=I2PTransducer(); public var bms=BurnerManagementSystem(); public var mx5=MX5Module(nodeID:5,channels:[.init("Flame",.digitalInput),.init("TIT",.thermocouple),.init("PIT",.analogInput),.init("LIT",.analogInput),.init("FuelFlow",.analogInput)])
    public init(){}
    public mutating func step(dt:Double,temperatureF:Double,pressurePSI:Double,levelPercent:Double,flow:Double){processTIT.step(actual:temperatureF,dt:dt);fuelPIT.step(actual:pressurePSI,dt:dt);vesselLIT.step(actual:levelPercent,dt:dt);fuelFIT.actualFlow=flow;mx5.channels[1].value=processTIT.indicatedValue;mx5.channels[2].value=fuelPIT.milliAmps;mx5.channels[3].value=vesselLIT.milliAmps;mx5.channels[4].value=fuelFIT.milliAmps;fuelValve.step(dt:dt);bms.step(dt:dt)}
}
