import Foundation
import ElectricalCore
import CircuitMNA

// Rev19: simulation-backed prediction, diagnostic topology partitioning,
// intermittent-fault capture, degradation/prognostics, and condition monitoring.

public enum DiagnosticObservable: String, Sendable, Codable, CaseIterable {
    case lineVoltage, controlVoltage, motorRunning, receiverPressure, transmitterMA, plcInput, networkFresh
}

public enum ObservationBand: String, Sendable, Codable { case veryLow, low, normal, high, veryHigh, falseState, trueState, stale }

public struct PlantObservation: Sendable, Equatable, Codable {
    public var observable: DiagnosticObservable
    public var value: Double
    public var band: ObservationBand
    public init(_ observable: DiagnosticObservable, _ value: Double, _ band: ObservationBand) { self.observable=observable; self.value=value; self.band=band }
}

public extension IndustrialTrainingPlant {
    func observation(_ observable: DiagnosticObservable) -> PlantObservation {
        switch observable {
        case .lineVoltage: return .init(observable,lineVoltage,lineVoltage < 400 ? .low:.normal)
        case .controlVoltage: return .init(observable,controlVoltage,controlVoltage < 20 ? .low:.normal)
        case .motorRunning: return .init(observable,motorRunning ? 1:0,motorRunning ? .trueState:.falseState)
        case .receiverPressure:
            let p=compressor.receiver.pressurePSI; return .init(observable,p,p < 25 ? .low:(p>130 ? .high:.normal))
        case .transmitterMA:
            let m=compressor.transmitterMA; return .init(observable,m,m < 3.8 ? .veryLow:(m>20.5 ? .veryHigh:.normal))
        case .plcInput: return .init(observable,plcInput ? 1:0,plcInput ? .trueState:.falseState)
        case .networkFresh: return .init(observable,networkFresh ? 1:0,networkFresh ? .trueState:.stale)
        }
    }
}

public struct SimulationBackedPredictor: Sendable {
    public var horizon: Double
    public var dt: Double
    public init(horizon:Double=2,dt:Double=0.02){self.horizon=max(dt,horizon);self.dt=max(0.0001,dt)}
    public func predict(base:IndustrialTrainingPlant, injecting fault:GenericFault, observables:[DiagnosticObservable]) -> [PlantObservation] {
        var clone=base; clone.faults.insert(fault)
        let n=max(1,Int((horizon/dt).rounded(.up))); for _ in 0..<n { clone.step(dt:dt) }
        return observables.map{clone.observation($0)}
    }
    public func predictionMatrix(base:IndustrialTrainingPlant, hypotheses:[String:GenericFault], observables:[DiagnosticObservable]) -> [String:[DiagnosticObservable:ObservationBand]] {
        var out:[String:[DiagnosticObservable:ObservationBand]]=[:]
        for (id,fault) in hypotheses { var row:[DiagnosticObservable:ObservationBand]=[:]; for o in predict(base:base,injecting:fault,observables:observables){row[o.observable]=o.band}; out[id]=row }
        return out
    }
}

public struct ModelGeneratedTestPlanner: Sendable {
    public init(){}
    public func candidates(base:IndustrialTrainingPlant, hypotheses:[DiagnosticHypothesis], faultMap:[String:GenericFault], observables:[DiagnosticObservable]) -> [DiagnosticTestCandidate] {
        let matrix=SimulationBackedPredictor().predictionMatrix(base:base,hypotheses:faultMap,observables:observables)
        return observables.map { obs in
            var p:[String:PredictedObservation]=[:]
            for h in hypotheses { guard let b=matrix[h.id]?[obs] else{continue}; p[h.id]=Self.convert(b) }
            return .init(id:"MODEL-\(obs.rawValue)",title:"Measure \(obs.rawValue)",safe:true,cost:1,predictions:p)
        }
    }
    private static func convert(_ b:ObservationBand)->PredictedObservation { switch b {case .veryLow,.low:return .low;case .normal:return .normal;case .high,.veryHigh:return .high;case .falseState:return .falseState;case .trueState:return .trueState;case .stale:return .stale} }
}

public struct DiagnosticPathNode: Identifiable, Hashable, Sendable, Codable { public var id:String; public var domain:HypothesisDomain; public init(_ id:String,_ domain:HypothesisDomain){self.id=id;self.domain=domain} }
public struct DiagnosticPath: Sendable, Codable {
    public var nodes:[DiagnosticPathNode]
    public init(_ nodes:[DiagnosticPathNode]){self.nodes=nodes}
    public func midpoint(in candidates:Set<String>) -> DiagnosticPathNode? { let filtered=nodes.filter{candidates.contains($0.id)}; guard !filtered.isEmpty else{return nil}; return filtered[(filtered.count-1)/2] }
    public func partition(at id:String,candidates:Set<String>)->(upstream:Set<String>,downstream:Set<String>){guard let i=nodes.firstIndex(where:{$0.id==id}) else{return([],[])};return(Set(nodes[...i].map(\.id)).intersection(candidates),Set(nodes[i...].map(\.id)).intersection(candidates))}
}

public enum CaptureTrigger: Sendable, Equatable { case threshold(Double), booleanEdge, manual }
public struct TimedSample: Sendable, Equatable, Codable { public var time:Double; public var value:Double; public init(_ time:Double,_ value:Double){self.time=time;self.value=value} }
public struct EventCaptureBuffer: Sendable {
    public var preTriggerSeconds:Double; public var postTriggerSeconds:Double; public var samples:[TimedSample]=[]; public var triggerTime:Double?; public var frozen=false
    public init(pre:Double=2,post:Double=2){preTriggerSeconds=max(0,pre);postTriggerSeconds=max(0,post)}
    public mutating func append(time:Double,value:Double){guard !frozen else{return};samples.append(.init(time,value));let keepFrom=time-preTriggerSeconds-(triggerTime == nil ? 0:postTriggerSeconds);samples.removeAll{$0.time<keepFrom};if let t=triggerTime,time>=t+postTriggerSeconds{frozen=true}}
    public mutating func trigger(at time:Double){if triggerTime == nil{triggerTime=time}}
    public var captured:[TimedSample]{guard let t=triggerTime else{return samples};return samples.filter{$0.time>=t-preTriggerSeconds && $0.time<=t+postTriggerSeconds}}
}

public struct IntermittentConnection: Sendable, Codable {
    public var baseResistanceOhms=0.01; public var degradation=0.0; public var temperatureC=25.0; public var vibration=0.0; public var seed:UInt64=1; public private(set) var dropoutCount=0
    public init(){}
    public mutating func step(currentA:Double,ambientC:Double,vibration:Double,dt:Double)->Double { self.vibration=vibration;let heat=currentA*currentA*baseResistanceOhms*(1+20*degradation);temperatureC += ((ambientC+heat*3)-temperatureC)*min(1,dt/2);degradation=min(1,degradation + max(0,temperatureC-60)*1e-6*dt + abs(vibration)*2e-6*dt);seed=seed &* 6364136223846793005 &+ 1442695040888963407;let random=Double((seed>>11)&0xFFFF)/65535;let probability=min(0.95,degradation*0.35 + max(0,temperatureC-80)/300 + abs(vibration)*0.02);if random<probability{dropoutCount += 1;return 1e9};return baseResistanceOhms*(1+50*degradation+max(0,temperatureC-25)*0.004)}
}

public enum HealthStage:String,Sendable,Codable,CaseIterable{case healthy,aging,degraded,intermittent,failed}
public struct AssetHealth:Sendable,Codable,Equatable{
    public var healthIndex=1.0; public var ageHours=0.0; public var intermittentEvents=0; public var thermalDamage=0.0
    public init(){}
    public var stage:HealthStage { if healthIndex<=0.05{return .failed};if healthIndex<0.3{return .intermittent};if healthIndex<0.6{return .degraded};if healthIndex<0.85{return .aging};return .healthy }
    public mutating func accumulate(hours:Double,temperatureC:Double,loadFraction:Double,intermittent:Bool=false){let h=max(0,hours);ageHours += h;let thermal=max(0,temperatureC-50)/100;thermalDamage += thermal*h;let wear=h*(0.00002 + max(0,loadFraction-0.7)*0.00008 + thermal*0.0001);healthIndex=max(0,healthIndex-wear);if intermittent{intermittentEvents += 1;healthIndex=max(0,healthIndex-0.01)}}
}

public struct ConditionSnapshot:Sendable,Equatable,Codable{public var time:Double;public var motorCurrentA:Double;public var vibrationMMs:Double;public var bearingTempC:Double;public var processPressure:Double;public init(time:Double,motorCurrentA:Double,vibrationMMs:Double,bearingTempC:Double,processPressure:Double){self.time=time;self.motorCurrentA=motorCurrentA;self.vibrationMMs=vibrationMMs;self.bearingTempC=bearingTempC;self.processPressure=processPressure}}
public struct ConditionBaseline:Sendable,Equatable,Codable{public var currentA:Double;public var vibrationMMs:Double;public var tempC:Double;public var pressure:Double;public init(currentA:Double,vibrationMMs:Double,tempC:Double,pressure:Double){self.currentA=currentA;self.vibrationMMs=vibrationMMs;self.tempC=tempC;self.pressure=pressure}}
public struct ConditionAssessment:Sendable,Equatable{public var anomalyScore:Double;public var findings:[String];public var warning:Bool{anomalyScore>=1}}
public struct ConditionMonitor:Sendable{
    public var baseline:ConditionBaseline; public init(baseline:ConditionBaseline){self.baseline=baseline}
    public func assess(_ x:ConditionSnapshot)->ConditionAssessment{var score=0.0;var f:[String]=[];func add(_ delta:Double,_ tolerance:Double,_ label:String){let z=abs(delta)/max(tolerance,1e-9);score += z*z;if z>=1{f.append(label)}};add(x.motorCurrentA-baseline.currentA,max(1,baseline.currentA*0.15),"motor current");add(x.vibrationMMs-baseline.vibrationMMs,max(0.5,baseline.vibrationMMs*0.5),"vibration");add(x.bearingTempC-baseline.tempC,10,"bearing temperature");add(x.processPressure-baseline.pressure,max(5,baseline.pressure*0.15),"process pressure");return .init(anomalyScore:sqrt(score),findings:f)}
}

public struct DiagnosticExperiment:Sendable,Codable{public var id:String;public var hypothesisID:String;public var variableChanged:String;public var before:[String:Double];public var after:[String:Double];public init(id:String,hypothesisID:String,variableChanged:String,before:[String:Double],after:[String:Double]){self.id=id;self.hypothesisID=hypothesisID;self.variableChanged=variableChanged;self.before=before;self.after=after}}
public struct ExperimentLedger:Sendable{public var experiments:[DiagnosticExperiment]=[];public init(){};public mutating func append(_ e:DiagnosticExperiment){experiments.append(e)};public func singleVariableDiscipline()->Bool{experiments.allSatisfy{!$0.variableChanged.isEmpty}}}
