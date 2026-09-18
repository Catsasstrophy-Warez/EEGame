import Foundation
import ElectricalCore
import CircuitMNA

// Rev18: model-based diagnostic intelligence. The hidden physical fault remains in the
// simulation; this layer reasons over evidence without turning the diagnosis into a script.

public enum HypothesisDomain: String, Sendable, Codable, CaseIterable {
    case supply, protection, wiring, io, logic, drive, actuator, pneumatic, process, feedback, network, mechanical, instrumentation
}

public struct DiagnosticHypothesis: Identifiable, Hashable, Sendable, Codable {
    public var id: String
    public var title: String
    public var domain: HypothesisDomain
    public var prior: Double
    public var posterior: Double
    public var active: Bool
    public init(id:String,title:String,domain:HypothesisDomain,prior:Double=1){self.id=id;self.title=title;self.domain=domain;self.prior=max(0,prior);self.posterior=max(0,prior);self.active=true}
}

public enum PredictedObservation: String, Sendable, Codable { case low, normal, high, open, closed, trueState, falseState, stale, invalid }
public struct DiagnosticTestCandidate: Identifiable, Sendable, Codable {
    public var id:String; public var title:String; public var instrument:InstrumentKind?; public var safe:Bool; public var cost:Double
    public var predictions:[String:PredictedObservation]
    public init(id:String,title:String,instrument:InstrumentKind?=nil,safe:Bool=true,cost:Double=1,predictions:[String:PredictedObservation]){self.id=id;self.title=title;self.instrument=instrument;self.safe=safe;self.cost=max(0,cost);self.predictions=predictions}
}
public struct DiagnosticTestScore: Sendable, Equatable { public var testID:String; public var informationGain:Double; public var utility:Double }

public struct HypothesisEngine: Sendable {
    public var hypotheses:[DiagnosticHypothesis]
    public var evidenceCount=0
    public init(_ hypotheses:[DiagnosticHypothesis]){self.hypotheses=hypotheses;normalize()}
    public mutating func normalize(){let s=hypotheses.filter(\.active).reduce(0){$0+$1.posterior};guard s>0 else{return};for i in hypotheses.indices where hypotheses[i].active{hypotheses[i].posterior/=s}}
    public var entropy:Double { hypotheses.filter(\.active).reduce(0){a,h in let p=h.posterior; return a + (p>0 ? -p*log2(p):0)} }
    public mutating func observe(test:DiagnosticTestCandidate,result:PredictedObservation,reliability:Double=0.98){let r=min(max(reliability,0.5),0.999999);for i in hypotheses.indices where hypotheses[i].active{let expected=test.predictions[hypotheses[i].id];let likelihood=(expected == result) ? r : (1-r);hypotheses[i].posterior *= likelihood};evidenceCount += 1;normalize()}
    public mutating func eliminate(below threshold:Double=0.001){for i in hypotheses.indices where hypotheses[i].posterior<threshold{hypotheses[i].active=false;hypotheses[i].posterior=0};normalize()}
    public func score(_ test:DiagnosticTestCandidate)->DiagnosticTestScore { guard test.safe else{return .init(testID:test.id,informationGain:0,utility:-Double.infinity)};let current=entropy;var groups:[PredictedObservation:Double]=[:];for h in hypotheses where h.active{if let o=test.predictions[h.id]{groups[o,default:0]+=h.posterior}};var expectedEntropy=0.0;for (_,mass) in groups where mass>0{var e=0.0;for h in hypotheses where h.active{guard test.predictions[h.id] != nil else{continue};let sameMass=mass; if sameMass>0, let groupObs=test.predictions[h.id], groups[groupObs]==mass { let p=h.posterior/sameMass; if p>0 {e += -p*log2(p)} }};expectedEntropy += mass*e};let gain=max(0,current-expectedEntropy);return .init(testID:test.id,informationGain:gain,utility:gain/(1+test.cost))}
    public func bestTest(from tests:[DiagnosticTestCandidate])->DiagnosticTestScore? { tests.map(score).filter{$0.utility.isFinite}.max{$0.utility<$1.utility} }
    public var leaders:[DiagnosticHypothesis]{hypotheses.filter(\.active).sorted{$0.posterior>$1.posterior}}
}

public struct MultiFaultAssessment: Sendable, Equatable {
    public var confirmed:Set<String>=[]; public var unresolved:Set<String>=[]
    public init(){}
    public var complete:Bool{unresolved.isEmpty && !confirmed.isEmpty}
    public mutating func confirm(_ id:String){confirmed.insert(id);unresolved.remove(id)}
    public mutating func require(_ id:String){if !confirmed.contains(id){unresolved.insert(id)}}
}

public enum DMMJack: String, Sendable, Codable { case common, voltsOhms, milliamp, amp }
public enum DMMMode: String, Sendable, Codable { case voltsAC, voltsDC, resistance, currentMilliamp, currentAmp, continuity }
public struct DeepDMM: Sendable {
    public var redJack:DMMJack = .voltsOhms; public var blackJack:DMMJack = .common; public var mode:DMMMode = .voltsDC; public var fuseIntact=true; public var inputImpedanceOhms=10_000_000.0
    public init(){}
    public func configurationValid()->Bool { guard blackJack == .common else{return false};switch mode{case .voltsAC,.voltsDC,.resistance,.continuity:return redJack == .voltsOhms;case .currentMilliamp:return redJack == .milliamp && fuseIntact;case .currentAmp:return redJack == .amp}}
    public mutating func exposeCurrentMode(acrossVolts:Double,shuntOhms:Double=0.1)->Bool {guard mode == .currentMilliamp && redJack == .milliamp else{return false};let amps=abs(acrossVolts)/max(shuntOhms,1e-9);if amps>0.5{fuseIntact=false;return true};return false}
}

public enum LoopCalibratorMode:String,Sendable,Codable {case measure,source,simulateTransmitter}
public struct DeepLoopCalibrator:Sendable {public var mode:LoopCalibratorMode = .measure;public var commandedMA=4.0;public init(){};public mutating func setPercent(_ p:Double){commandedMA=4+16*min(max(p,0),100)/100};public func outputMA(externalLoopPower:Bool)->Double?{switch mode{case .measure:return nil;case .source:return commandedMA;case .simulateTransmitter:return externalLoopPower ? commandedMA:nil}}}

public struct IndustrialTrainingPlant: Sendable {
    public var lineVoltage=480.0; public var controlVoltage=24.0; public var driveCommand=false; public var motorRunning=false; public var compressor=CompressorPackage(); public var plcInput=true; public var networkFresh=true; public var faults:Set<GenericFault>=[]
    public init(){}
    public mutating func step(dt:Double){let powerOK=lineVoltage>400 && !faults.contains(.blownFuse);let commandOK=driveCommand && networkFresh;motorRunning=powerOK && commandOK && !faults.contains(.openConductor);compressor.running=motorRunning;if faults.contains(.pneumaticLeak){compressor.downstreamDemandSCFM=70}else{compressor.downstreamDemandSCFM=10};compressor.transmitter.impulsePlugged=faults.contains(.pluggedImpulse);compressor.transmitter.driftPSI=faults.contains(.transmitterDrift) ? 15:0;compressor.step(dt:dt);plcInput = !faults.contains(.failedIOChannel)}
}

public struct Rev18DiagnosticLibrary {
    public static func actuatorNoMoveHypotheses()->[DiagnosticHypothesis]{[
        .init(id:"H1",title:"24 VDC/output path failure",domain:.wiring),.init(id:"H2",title:"Failed output channel",domain:.io),.init(id:"H3",title:"Solenoid coil/spool failure",domain:.actuator),.init(id:"H4",title:"Low pneumatic supply",domain:.pneumatic),.init(id:"H5",title:"Cylinder/mechanical bind",domain:.mechanical),.init(id:"H6",title:"Feedback path failure",domain:.feedback)]}
    public static func actuatorTests()->[DiagnosticTestCandidate]{[
        .init(id:"T1",title:"Measure voltage at solenoid coil",instrument:.dmm,cost:1,predictions:["H1":.low,"H2":.low,"H3":.normal,"H4":.normal,"H5":.normal,"H6":.normal]),
        .init(id:"T2",title:"Measure regulated air pressure",instrument:.pressureGauge,cost:1,predictions:["H1":.normal,"H2":.normal,"H3":.normal,"H4":.low,"H5":.normal,"H6":.normal]),
        .init(id:"T3",title:"Observe physical cylinder movement",cost:0.5,predictions:["H1":.falseState,"H2":.falseState,"H3":.falseState,"H4":.falseState,"H5":.falseState,"H6":.trueState]),
        .init(id:"T4",title:"Resistance test while energized",instrument:.dmm,safe:false,cost:0.1,predictions:[:])]
    }
}
