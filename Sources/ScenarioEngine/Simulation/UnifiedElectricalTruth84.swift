import Foundation
import ElectricalCore
import CircuitMNA

public enum EETruthNode84:Int, CaseIterable, Sendable {
    case ground=0, source=1, afterDisconnect=2, afterFuse=3, plcOutput=4, terminal=5, junctionBox=6, solenoid=7
}
public struct EEUnifiedTruthSnapshot84: Equatable, Sendable {
    public var nodeVoltages:[Double]
    public var controlCurrentA:Double
    public var coilCurrentA:Double
    public var converged:Bool
    public var residual:Double
    public func voltage(_ n:EETruthNode84)->Double { nodeVoltages.indices.contains(n.rawValue) ? nodeVoltages[n.rawValue]:0 }
}
public enum EEUnifiedElectricalTruth84 {
    public static func solve(state:EECommissioningState83,sourceV:Double=24,
                             failure:EEFailureMode79 = .healthy) -> EEUnifiedTruthSnapshot84 {
        let closed=0.02, open=1e12
        let fuseOK=state.fuseAHealthy && state.fuseBHealthy && state.fuseCHealthy
        let rDisconnect=state.disconnectClosed ? closed:open
        let rFuse=fuseOK && !state.overloadTripped ? 0.06:open
        let rPLC=state.plcDO4 ? 0.05:open
        let rTerminal:Double
        switch failure {
        case .healthy:rTerminal=0.08
        case .highResistance:rTerminal=220
        case .openCircuit:rTerminal=open
        case .shortToGround:rTerminal=0.08
        }
        let rCable=0.35
        let coil=state.solenoidCoilHealthy ? 1200.0:open
        var resistors:[Resistor] = [
            .init(a:1,b:2,resistance:rDisconnect),
            .init(a:2,b:3,resistance:rFuse),
            .init(a:3,b:4,resistance:rPLC),
            .init(a:4,b:5,resistance:rTerminal),
            .init(a:5,b:6,resistance:rCable),
            .init(a:6,b:7,resistance:0.12),
            .init(a:7,b:0,resistance:coil)
        ]
        if failure == .shortToGround {
            resistors.append(.init(a:5,b:0,resistance:0.12))
        }
        let c=Circuit(nodeCount:8,resistors:resistors,voltageSources:[.init(positive:1,negative:0,volts:sourceV)])
        guard let s=try? ReferenceDCSolver().solve(c) else {
            return .init(nodeVoltages:Array(repeating:0,count:8),controlCurrentA:0,coilCurrentA:0,converged:false,residual:.infinity)
        }
        let v=s.nodeVoltages
        let sourceI=(v[1]-v[2])/rDisconnect
        let coilI=v[7]/coil
        return .init(nodeVoltages:v,controlCurrentA:sourceI,coilCurrentA:coilI,converged:s.converged,residual:s.residual)
    }
    public static func probeNode(_ n:EEProbeNode78)->EETruthNode84 {
        switch n {
        case .ground:return .ground
        case .source:return .source
        case .tb112:return .terminal
        case .sol101:return .solenoid
        case .ai04:return .junctionBox
        case .pit101:return .junctionBox
        }
    }
    public static func measure(red:EEProbeNode78,black:EEProbeNode78,truth:EEUnifiedTruthSnapshot84)->Double {
        truth.voltage(probeNode(red))-truth.voltage(probeNode(black))
    }
}
