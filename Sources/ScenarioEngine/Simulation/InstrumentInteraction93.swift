import Foundation
import ElectricalCore
import CircuitMNA

public enum EEMeterMode93:String,Codable,CaseIterable,Sendable {case highZVolts,loZVolts,ohms}
public struct EEProbePoint93:Codable,Equatable,Hashable,Sendable {public var identity:String;public var node:Int;public init(_ identity:String,_ node:Int){self.identity=identity;self.node=node}}
public struct EEMeterConnection93:Codable,Equatable,Sendable {
 public var red=EEProbePoint93("L1",1);public var black=EEProbePoint93("GND",0);public var mode:EEMeterMode93 = .highZVolts
 public init(){}
}
public struct EEMeterResult93:Codable,Equatable,Sendable {public var volts=0.0;public var loadingCurrentA=0.0;public var inputOhms=10_000_000.0;public var valid=true;public init(){}}

public enum EEInstrumentLoadedNetwork93 {
 public static func solve(sourceV:Double,sourceOhms:Double=0.08,connection:EEMeterConnection93)throws->EEMeterResult93 {
  let rin:Double = connection.mode == .highZVolts ? 10_000_000 : connection.mode == .loZVolts ? 3_000 : 1_000
  let maxNode=max(1,connection.red.node,connection.black.node)
  var c=Circuit(nodeCount:maxNode+1)
  // Source node is node 1. Non-source probe identities are represented through a high-resistance
  // physical path until the facility topology compiler supplies their canonical branch.
  c.voltageSources.append(.init(positive:1,negative:0,volts:sourceV))
  c.resistors.append(.init(a:1,b:0,resistance:max(1e-6,sourceOhms)))
  if connection.red.node != connection.black.node {
   c.resistors.append(.init(a:connection.red.node,b:connection.black.node,resistance:rin))
  }
  let x=try ReferenceDCSolver().solve(c)
  let vr=x.nodeVoltages.indices.contains(connection.red.node) ? x.nodeVoltages[connection.red.node] : 0
  let vb=x.nodeVoltages.indices.contains(connection.black.node) ? x.nodeVoltages[connection.black.node] : 0
  var r=EEMeterResult93();r.volts=vr-vb;r.inputOhms=rin;r.loadingCurrentA=abs(r.volts)/rin;r.valid=r.volts.isFinite;return r
 }
}

public struct EECanonicalConductor93:Codable,Equatable,Sendable {
 public var identity:String;public var from:String;public var to:String;public var phase:String;public var gauge:String
 public init(_ identity:String,_ from:String,_ to:String,_ phase:String,_ gauge:String){self.identity=identity;self.from=from;self.to=to;self.phase=phase;self.gauge=gauge}
}
public enum EEFacilityHarness93 {
 public static let motorFeed=[
  EECanonicalConductor93("1L1","MCC203.BUS.L1","52-M1.LINE.L1","L1","2 AWG"),
  EECanonicalConductor93("1L2","MCC203.BUS.L2","52-M1.LINE.L2","L2","2 AWG"),
  EECanonicalConductor93("1L3","MCC203.BUS.L3","52-M1.LINE.L3","L3","2 AWG"),
  EECanonicalConductor93("2T1","M-201.LOAD.T1","MOTOR201.T1","T1","2 AWG"),
  EECanonicalConductor93("2T2","M-201.LOAD.T2","MOTOR201.T2","T2","2 AWG"),
  EECanonicalConductor93("2T3","M-201.LOAD.T3","MOTOR201.T3","T3","2 AWG"),
  EECanonicalConductor93("X1","CPT201.X1","TB201.7","CTRL","14 AWG"),
  EECanonicalConductor93("AI07+","PT201.OUT+","PLC.AI07+","SIGNAL","18 AWG SHLD")
 ]
}
