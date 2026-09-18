import Foundation
import ElectricalCore
import CircuitMNA

// Rev68: physically connected I&E/Controls laboratory, adaptive clocks, protocol traces and synchronized forensic cursor.
public struct EECompiledStampCache68: Sendable {
    public var circuit: Circuit
    public var model: SparseMNAModel
    public var plan: CSRStampPlan66
    public init(_ circuit: Circuit) { self.circuit = circuit; self.model = SparseMNACompiler.compile(circuit); self.plan = CSRStampPlan66(matrix: model.matrix) }
    public mutating func restamp(_ updated: Circuit) { circuit = updated; FastSparseStamper66.stamp(updated, into: &model, plan: plan) }
}

public struct EEIslandBenchmark68: Sendable, Codable, Equatable {
    public var circuits: Int; public var solved: Int; public var failed: Int; public var deterministicOrder: [Int]
}
public enum EEIslandBenchmarkRunner68 {
    public static func run(_ circuits: [Circuit]) async -> EEIslandBenchmark68 {
        let r = await EEDeterministicIslandScheduler67.solve(circuits)
        return .init(circuits: circuits.count, solved: r.filter{$0.snapshot != nil}.count, failed: r.filter{$0.error != nil}.count, deterministicOrder: r.map(\.index))
    }
}

public struct EEAdaptiveMultiRate68: Sendable, Codable, Equatable {
    public var clock = EEMultiRateClock67(); public var activity = 0.0
    public init() {}
    public mutating func setActivity(_ x: Double) {
        activity = min(1,max(0,x)); clock.periods[.electrical] = activity > 0.7 ? 0.0005 : 0.002; clock.periods[.controls] = activity > 0.5 ? 0.005 : 0.02; clock.periods[.process] = activity > 0.8 ? 0.02 : 0.05
    }
}

public enum EECalibratorConnection68: String, Sendable, Codable { case disconnected, seriesMeasure, sourceIntoAI, simulateTransmitter }
public struct EELoopCalibrator68: Sendable, Codable, Equatable {
    public var connection: EECalibratorConnection68 = .disconnected; public var setpointMA = 12.0; public var burdenOhms = 8.0; public var fuseHealthy = true
    public init() {}
    public func observedMA(loopSupplyV: Double, loopOhms: Double) -> Double? {
        switch connection { case .disconnected: return nil; case .seriesMeasure: return fuseHealthy ? 1000 * loopSupplyV/max(1,loopOhms+burdenOhms) : nil; case .sourceIntoAI,.simulateTransmitter: return setpointMA }
    }
}

public enum EEMeggerConsequence68: String, Sendable, Codable { case safeTest, connectedElectronicsRisk, chargedCapacitance, inadequateIsolation }
public struct EEInsulationTest68: Sendable, Codable, Equatable {
    public var testV = 500.0; public var insulationOhms = 100_000_000.0; public var electronicsConnected = false; public var isolated = true; public var capacitanceF = 0.0
    public init() {}
    public var leakageA: Double { testV/max(1,insulationOhms) }
    public var consequence: EEMeggerConsequence68 { if !isolated { return .inadequateIsolation }; if electronicsConnected { return .connectedElectronicsRisk }; if capacitanceF > 1e-9 { return .chargedCapacitance }; return .safeTest }
}

public enum EEDPProcedureStep68: String, Sendable, Codable, CaseIterable { case isolateHigh, isolateLow, openEqualizer, ventHigh, ventLow, verifyZero, closeVents, closeEqualizer, restoreLow, restoreHigh }
public struct EEDPQualification68: Sendable, Codable, Equatable {
    public var manifold = EEFiveValveDPManifold66(); public var completed:[EEDPProcedureStep68]=[]; public var unsafeSequence=false
    public init() {}
    public mutating func perform(_ step:EEDPProcedureStep68) {
        switch step { case .isolateHigh: manifold.highBlock=false; case .isolateLow: manifold.lowBlock=false; case .openEqualizer: if manifold.highBlock || manifold.lowBlock { unsafeSequence=true }; manifold.equalize=true; case .ventHigh: manifold.highVent=true; case .ventLow: manifold.lowVent=true; case .verifyZero: break; case .closeVents: manifold.highVent=false;manifold.lowVent=false; case .closeEqualizer: manifold.equalize=false; case .restoreLow: manifold.lowBlock=true; case .restoreHigh: manifold.highBlock=true }
        completed.append(step)
    }
}

public struct EEProtocolEvent68: Identifiable, Sendable, Codable, Equatable { public var id:Int; public var time:Double; public var layer:String; public var operation:String; public var address:Int?; public var value:Double?; public var delivered:Bool; public var detail:String }
public struct EEProtocolTimeline68: Sendable, Codable, Equatable {
    public var events:[EEProtocolEvent68]=[]; public init(){}
    public mutating func append(time:Double,layer:String,operation:String,address:Int?=nil,value:Double?=nil,delivered:Bool=true,detail:String=""){ events.append(.init(id:events.count,time:time,layer:layer,operation:operation,address:address,value:value,delivered:delivered,detail:detail)) }
}

public struct EECANFault68: Sendable, Codable, Equatable { public var missingTerminator=false; public var commonModeV=0.0; public var propagationNS=0.0; public var intermittentOpenProbability=0.0; public init(){} }
public struct EECANBitSample68: Sendable, Codable, Equatable { public var timeUS:Double; public var canH:Double; public var canL:Double; public var dominant:Bool }
public enum EECANBitLab68 {
    public static func frame(bits:[Bool],bitRate:Double=500_000,fault:EECANFault68 = .init())-> [EECANBitSample68] { let bitUS=1_000_000/max(1,bitRate); return bits.enumerated().map { i,b in let ring=fault.missingTerminator && i%3==0 ? 0.35:0; let open=fault.intermittentOpenProbability>0 && i%7==0; let h=open ? 2.5 : (b ? 3.5+ring : 2.5); let l=open ? 2.5 : (b ? 1.5-ring : 2.5); return .init(timeUS:Double(i)*bitUS+fault.propagationNS/1000,canH:h+fault.commonModeV,canL:l+fault.commonModeV,dominant:b) } }
}

public enum EEForensicLayer68:String,Sendable,Codable,CaseIterable { case physical,drawing,instrument,plc,network,hmi,historian,evidence,goldenThread }
public struct EESynchronizedCursor68: Sendable, Codable, Equatable {
    public var time=0.0; public var selectedIdentity:String?; public var activeLayers:Set<EEForensicLayer68> = Set(EEForensicLayer68.allCases)
    public init(){}
    public func frame(in buffer:EEForensicCircularBuffer67)->EEReplayFrame63?{buffer.nearest(time:time)}
}

public struct EERev68SynchronizedForensicLab: Sendable, Codable {
    public var workbench=EEQualificationWorkbench67(); public var adaptive=EEAdaptiveMultiRate68(); public var calibrator=EELoopCalibrator68(); public var megger=EEInsulationTest68(); public var dp=EEDPQualification68(); public var protocols=EEProtocolTimeline68(); public var cursor=EESynchronizedCursor68()
    public init(){}
    public mutating func tick(dt:Double,activity:Double){adaptive.setActivity(activity);workbench.clock.periods=adaptive.clock.periods;workbench.advance(dt:dt);let p=workbench.base.base.base.runtime.board.rig.plc;protocols.append(time:workbench.clock.time,layer:"PLC",operation:"scan",address:Int(p.rawAI),value:p.engineeringValue,delivered:true,detail:"synchronized control scan")}
}
