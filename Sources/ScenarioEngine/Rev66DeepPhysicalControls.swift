import Foundation
import ElectricalCore
import CircuitMNA

// Rev66: deeper physical instruments, process manifolds, controls timing and bounded forensic capture.
public enum EEMeterInput66:String,Sendable,Codable{case voltage,resistance,current}
public struct EEMeterModel66:Sendable,Codable,Equatable{
 public var voltageInputOhms=10_000_000.0;public var currentBurdenOhms=10.0;public var leadOhms=0.15;public init(){}
 public func loadedVoltage(sourceV:Double,sourceOhms:Double)throws->Double{let c=Circuit(nodeCount:3,resistors:[.init(a:2,b:1,resistance:max(1,sourceOhms)),.init(a:1,b:0,resistance:voltageInputOhms)],voltageSources:[.init(positive:2,negative:0,volts:sourceV)]);return try ReferenceDCSolver().solve(c).nodeVoltages[1]}
 public func loopCurrentWithMeter(supplyV:Double,loopOhms:Double)->Double{ supplyV/max(1,loopOhms+currentBurdenOhms+2*leadOhms) }
}

public enum EEManifoldValve66:String,Sendable,Codable,CaseIterable{case highBlock,lowBlock,equalize,highVent,lowVent}
public struct EEFiveValveDPManifold66:Sendable,Codable,Equatable{
 public var highProcess=100.0,lowProcess=90.0,highSensed=100.0,lowSensed=90.0;public var highBlock=true,lowBlock=true,equalize=false,highVent=false,lowVent=false;public var highRestriction=0.0,lowRestriction=0.0;public init(){}
 public mutating func step(dt:Double){let eq=equalize ? (highSensed+lowSensed)/2:nil;let ht=highVent ? 0:(eq ?? (highBlock ? highProcess:highSensed));let lt=lowVent ? 0:(eq ?? (lowBlock ? lowProcess:lowSensed));highSensed += (ht-highSensed)*min(1,dt/max(0.02,0.1/(max(0.02,1-highRestriction))));lowSensed += (lt-lowSensed)*min(1,dt/max(0.02,0.1/(max(0.02,1-lowRestriction))))}
 public var differential:Double{highSensed-lowSensed}
}

public struct EETransmitterLayers66:Sendable,Codable,Equatable{public var sensorBias=0.0;public var sensorGain=1.0;public var lowerTrim=0.0;public var upperTrimFactor=1.0;public var lrv=0.0;public var urv=100.0;public var damping=0.2;public var outputMA=4.0;public init(){};public mutating func step(physicalInput:Double,dt:Double){let sensed=(physicalInput+sensorBias)*sensorGain;let trimmed=(sensed+lowerTrim)*upperTrimFactor;let f=min(1.05,max(-0.05,(trimmed-lrv)/max(1e-9,urv-lrv)));let target=4+16*f;outputMA += (target-outputMA)*min(1,dt/max(0.001,damping))}}

public enum EEScopeTriggerSlope66:String,Sendable,Codable{case rising,falling}
public struct EETrigger66:Sendable,Codable,Equatable{public var level=0.0;public var slope:EEScopeTriggerSlope66 = .rising;public init(){} }
public enum EETriggerAwareScope66{public static func triggerIndex(samples:[Double],trigger:EETrigger66)->Int?{guard samples.count>1 else{return nil};for i in 1..<samples.count{if trigger.slope == .rising && samples[i-1] < trigger.level && samples[i] >= trigger.level{return i};if trigger.slope == .falling && samples[i-1] > trigger.level && samples[i] <= trigger.level{return i}};return nil}}

public struct EELadderScanFrame66:Identifiable,Sendable,Codable,Equatable{public var id:Int;public var time:Double;public var inputs:[String:Bool];public var rungPower:[String:Bool];public var outputs:[String:Bool]}
public struct EEPLCScanRecorder66:Sendable,Codable,Equatable{public var frames:[EELadderScanFrame66]=[];public init(){};public mutating func append(time:Double,inputs:[String:Bool],rungs:[String:Bool],outputs:[String:Bool]){frames.append(.init(id:frames.count,time:time,inputs:inputs,rungPower:rungs,outputs:outputs))}}

public struct EERegisterTransaction66:Identifiable,Sendable,Codable,Equatable{public var id:Int;public var time:Double;public var function:String;public var address:Int;public var value:Int;public var delivered:Bool;public var latencyMS:Double}
public enum EERegisterCapture66{public static func capture(network:EENetwork63,count:Int=32)->[EERegisterTransaction66]{(0..<count).map{.init(id:$0,time:Double($0)*0.05,function:$0%2==0 ? "read":"write",address:40001+($0%8),value:100+$0,delivered:network.delivered(sequence:$0),latencyMS:network.latencyMS)}}}

public struct EECANBitTiming66:Sendable,Codable,Equatable{public var nominalBitRate=500_000.0;public var samplePoint=0.8;public var propagationDelayNS=100.0;public var commonModeLimitV=2.0;public init(){};public func quality(can:EECANPhysical63)->Double{let termination=can.healthyTermination ? 1.0:max(0,1-abs(can.measuredResistance-60)/120);let common=max(0,1-abs(can.commonModeOffsetV)/max(0.1,commonModeLimitV));let timing=max(0,1-propagationDelayNS/(1e9/nominalBitRate));return termination*common*timing}}

public struct EEForensicRing66:Sendable,Codable,Equatable{public var capacity:Int;private var storage:[EEReplayFrame63]=[];public init(capacity:Int=1200){self.capacity=max(1,capacity)};public mutating func append(_ frame:EEReplayFrame63){if storage.count==capacity{storage.removeFirst()};storage.append(frame)};public var frames:[EEReplayFrame63]{storage};public func nearest(time:Double)->EEReplayFrame63?{storage.min{abs($0.time-time)<abs($1.time-time)}}}

public struct EERev66DeepPhysicalControls:Sendable,Codable{public var base=EERev65DeepQualificationAndArchitecture();public var meter=EEMeterModel66();public var manifold=EEFiveValveDPManifold66();public var transmitter=EETransmitterLayers66();public var ladder=EEPLCScanRecorder66();public var forensic=EEForensicRing66();public init(){};public mutating func tick(dt:Double){manifold.step(dt:dt);transmitter.step(physicalInput:manifold.differential,dt:dt);base.tick(dt:dt);if let f=base.base.runtime.board.rig.replay.frames.last{forensic.append(f)};let plc=base.base.runtime.board.rig.plc;ladder.append(time:base.cursor.time,inputs:["permissive":plc.permissive,"request":plc.runRequest],rungs:["run":plc.permissive && plc.runRequest],outputs:["output":plc.output])}}
