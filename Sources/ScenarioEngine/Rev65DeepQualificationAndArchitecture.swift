import Foundation
import ElectricalCore
import CircuitMNA

// Rev65 deep qualification + architecture. Educational simulation only; not a field procedure or regulatory classification engine.
public enum EEOperatingMode65:String,Sendable,Codable,CaseIterable{case offlineVirtualCommissioning,onlineLiveSimulation,forensicReplay}
public enum EEViewport65:String,Sendable,Codable,CaseIterable{case physical,schematic,diagnostics,actions,plc,hmi,historian,goldenThread}
public struct EEViewportSnapshot65:Sendable,Codable,Equatable{public var time:Double;public var values:[String:Double];public var highlightedIdentity:String?;public var alarms:[String]}
public struct EESynchronizedWorkspace65:Sendable,Codable,Equatable{
 public var mode:EEOperatingMode65 = .onlineLiveSimulation; public var enabled:Set<EEViewport65>=[.physical,.schematic,.diagnostics,.actions]; public var highlightedIdentity:String?; public var snapshot=EEViewportSnapshot65(time:0,values:[:],highlightedIdentity:nil,alarms:[]); public init(){}
 public mutating func publish(from r:EEQualificationRuntime64){let rig=r.board.rig;snapshot = .init(time:rig.time,values:["process":rig.impulse.processPressure,"sensed":rig.impulse.sensedPressure,"mA":rig.transmitter.outputMA,"raw":Double(rig.plc.rawAI),"eu":rig.plc.engineeringValue],highlightedIdentity:highlightedIdentity,alarms:[])}
}

public enum EEScopeCoupling65:String,Sendable,Codable{case dc,ac}
public enum EEScopeAcquisition65:String,Sendable,Codable{case sample,average,peakDetect}
public struct EEScopeConfiguration65:Sendable,Codable,Equatable{public var sampleRateHz=10_000.0;public var seconds=0.05;public var pretriggerFraction=0.25;public var holdoff=0.0;public var coupling:EEScopeCoupling65 = .dc;public var probeAttenuation=10.0;public var bandwidthHz=20_000_000.0;public var acquisition:EEScopeAcquisition65 = .sample;public init(){}}
public struct EEScopeTrace65:Sendable,Codable,Equatable{public var dt:Double;public var samples:[Double];public var triggerIndex:Int;public var min:Double{samples.min() ?? 0};public var max:Double{samples.max() ?? 0};public var mean:Double{samples.isEmpty ? 0:samples.reduce(0,+)/Double(samples.count)}}
public enum EEScopeEngine65 { public static func acquire(configuration:EEScopeConfiguration65,signal:(Double)->Double)->EEScopeTrace65{let n=max(2,Int(configuration.sampleRateHz*configuration.seconds));let dt=1/configuration.sampleRateHz;var s=[Double]();s.reserveCapacity(n);var prev=0.0;for i in 0..<n{var v=signal(Double(i)*dt);if configuration.coupling == .ac {let a=exp(-2*Double.pi*5*dt);let hp=a*((s.last ?? 0)+v-prev);prev=v;v=hp};s.append(v/configuration.probeAttenuation)};return .init(dt:dt,samples:s,triggerIndex:Int(Double(n)*configuration.pretriggerFraction))} }

public struct EEValveSignaturePoint65:Sendable,Codable,Equatable{public var command:Double;public var position:Double;public var error:Double}
public enum EEValveSignature65{public static func stroke(_ source:EEValvePositioner63,steps:Int=21)->[EEValveSignaturePoint65]{var v=source;var out:[EEValveSignaturePoint65]=[];for i in 0..<steps{v.command=Double(i)/Double(max(1,steps-1));for _ in 0..<10{v.step(dt:0.05)};out.append(.init(command:v.command,position:v.position,error:v.command-v.position))};for i in stride(from:steps-1,through:0,by:-1){v.command=Double(i)/Double(max(1,steps-1));for _ in 0..<10{v.step(dt:0.05)};out.append(.init(command:v.command,position:v.position,error:v.command-v.position))};return out}}

public struct EEPacketEvent65:Identifiable,Sendable,Codable,Equatable{public var id:Int;public var time:Double;public var delivered:Bool;public var latencyMS:Double;public var source:String;public var destination:String}
public enum EEPacketTimeline65{public static func capture(network:EENetwork63,count:Int=64,period:Double=0.02)->[EEPacketEvent65]{(0..<count).map{let ok=network.delivered(sequence:$0);return .init(id:$0,time:Double($0)*period,delivered:ok,latencyMS:network.latencyMS,source:"PLC",destination:"HMI")}}}
public struct EECANWaveform65:Sendable,Codable,Equatable{public var time:[Double];public var canH:[Double];public var canL:[Double]}
public enum EECANScope65{public static func capture(_ can:EECANPhysical63,bits:[Bool]=[true,false,true,true,false],samplesPerBit:Int=16)->EECANWaveform65{var t:[Double]=[],h:[Double]=[],l:[Double]=[];let degraded = !can.healthyTermination;for (b,bit) in bits.enumerated(){for s in 0..<samplesPerBit{let x=Double(b*samplesPerBit+s);t.append(x);let ring=degraded ? 0.35*exp(-Double(s)/5)*sin(Double(s)*1.8):0;h.append((bit ? 3.5:2.5)+ring);l.append((bit ? 1.5:2.5)-ring)}};return .init(time:t,canH:h,canL:l)}}

public enum EEHazardEnvironment65:String,Sendable,Codable,CaseIterable{case ordinary,flammableGasOrVapor,combustibleDust,undergroundMine}
public struct EEHazardAssessment65:Sendable,Codable,Equatable{public var environment:EEHazardEnvironment65;public var energySources:[String];public var atmosphereIndicators:[String:Double];public var requiredResearch:[String];public var siteProcedureRequired:Bool=true}
public enum EEHazardTraining65 { public static func assessment(for world:EEIndustrialWorld)->EEHazardAssessment65{switch world{case .naturalGas:return .init(environment:.flammableGasOrVapor,energySources:["electrical","pressure","rotating","stored pneumatic"],atmosphereIndicators:["gas":0],requiredResearch:["adopted electrical code","area classification drawing","site electrical safety procedure"]);case .coalMining:return .init(environment:.undergroundMine,energySources:["electrical","hydraulic","mechanical","stored gravitational"],atmosphereIndicators:["methane":0,"CO":0],requiredResearch:["applicable mine safety requirements","approved equipment requirements","mine ventilation plan"])}}}

public struct EEForensicCursor65:Sendable,Codable,Equatable{public var time:Double=0;public var identity:String?;public init(){};public func nearest(in replay:EEForensicReplay63)->EEReplayFrame63?{replay.frames.min{abs($0.time-time)<abs($1.time-time)}}}
public struct EERev65DeepQualificationAndArchitecture:Sendable,Codable{public var base=EERev64PhysicalInstrumentQualification();public var workspace=EESynchronizedWorkspace65();public var scope=EEScopeConfiguration65();public var cursor=EEForensicCursor65();public init(){};public mutating func tick(dt:Double){base.runtime.tick(dt:dt);workspace.publish(from:base.runtime);cursor.time=base.runtime.board.rig.time}}
