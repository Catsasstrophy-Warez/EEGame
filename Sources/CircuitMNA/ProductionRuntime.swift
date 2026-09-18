import Foundation
import ElectricalCore

public struct StampAddress: Sendable, Equatable { public let aa:Int?; public let ab:Int?; public let ba:Int?; public let bb:Int? }
public struct CompiledResistorStamp: Sendable, Equatable { public let componentIndex:Int; public let address:StampAddress }

public enum CSRStampCompiler {
    public static func resistorAddresses(_ matrix: SparseMatrixCSR, circuit: Circuit) -> [CompiledResistorStamp] {
        func idx(_ r:Int,_ c:Int)->Int? { guard r >= 0 && c >= 0 && r < matrix.size else { return nil }; return (matrix.rowPointers[r]..<matrix.rowPointers[r+1]).first { matrix.columnIndices[$0] == c } }
        return circuit.resistors.enumerated().map { i,r in
            let a=r.a == 0 ? nil : r.a-1, b=r.b == 0 ? nil : r.b-1
            return .init(componentIndex:i,address:.init(aa:a.flatMap{idx($0,$0)},ab:(a != nil && b != nil) ? idx(a!,b!) : nil,ba:(a != nil && b != nil) ? idx(b!,a!) : nil,bb:b.flatMap{idx($0,$0)}))
        }
    }
}

public struct SolverWorkspace: Sendable { public var warmStart:[Double]=[]; public var lastReport:SolverReport?; public init(){} }
public struct ProductionDCSolver: Sendable {
    public var workspace=SolverWorkspace(); public var tolerance=1e-9
    public init(){}
    public mutating func solve(_ c:Circuit) throws -> ElectricalSnapshot {
        let model=SparseMNACompiler.compile(c); if workspace.warmStart.count != model.matrix.size { workspace.warmStart=Array(repeating:0,count:model.matrix.size) }
        var robust=RobustSparseDCSolver(); robust.tolerance=tolerance
        let snap=try robust.solve(c,warmStart:workspace.warmStart)
        workspace.warmStart=Array(snap.nodeVoltages.dropFirst()) + snap.voltageSourceCurrents; workspace.lastReport=snap.report; return snap
    }
}

public struct AdaptiveTimeStepper: Sendable, Equatable {
    public var dt:Double; public var minimum:Double; public var maximum:Double
    public init(dt:Double=1.0/120,minimum:Double=1e-5,maximum:Double=1.0/30){self.dt=dt;self.minimum=minimum;self.maximum=maximum}
    public mutating func update(error:Double,eventImminent:Bool=false){ if eventImminent || error > 1e-3 { dt=max(minimum,dt*0.5) } else if error < 1e-6 { dt=min(maximum,dt*1.25) } }
}

public struct TransientCapacitor: Sendable, Codable { public var c:Double; public var voltage=0.0; public mutating func commit(voltage newValue:Double){voltage=newValue}; public func stamp(dt:Double,a:NodeID,b:NodeID)->(Resistor,CurrentSource){ var x=CapacitorCompanion(capacitanceF:c);x.previousVoltage=voltage;return x.backwardEuler(dt:dt,a:a,b:b)} }
public struct TransientInductor: Sendable, Codable { public var l:Double; public var current=0.0; public mutating func commit(current newValue:Double){current=newValue}; public func stamp(dt:Double,a:NodeID,b:NodeID)->(Resistor,CurrentSource){ var x=InductorCompanion(inductanceH:l);x.previousCurrent=current;return x.backwardEuler(dt:dt,a:a,b:b)} }
public func makeTransientCapacitor53(_ capacitance:Double)->TransientCapacitor { TransientCapacitor(c:capacitance, voltage:0) }
