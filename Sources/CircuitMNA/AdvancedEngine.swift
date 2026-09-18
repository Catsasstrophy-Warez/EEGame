import Foundation
import ElectricalCore

public enum CircuitDiagnostic: Sendable, Equatable {
    case floatingNodes([NodeID])
    case extremeConductanceRatio(Double)
    case noGroundReference
}

public enum CircuitDiagnostics {
    public static func analyze(_ c: Circuit) -> [CircuitDiagnostic] {
        var out:[CircuitDiagnostic] = []
        let islands = IslandDetector.detect(c)
        let floating = islands.filter { !$0.nodes.contains(0) }.flatMap(\.nodes).sorted()
        if !floating.isEmpty { out.append(.floatingNodes(floating)) }
        let gs = c.resistors.filter{$0.resistance > 0}.map{1.0/$0.resistance}
        if let lo=gs.min(), let hi=gs.max(), lo > 0, hi/lo >= 1e8 { out.append(.extremeConductanceRatio(hi/lo)) }
        if c.nodeCount > 0 && !islands.contains(where:{$0.nodes.contains(0)}) { out.append(.noGroundReference) }
        return out
    }
}

public struct MatrixScaling: Sendable {
    public var rowScale:[Double]
    public init(_ a:SparseMatrixCSR) {
        rowScale = (0..<a.size).map { r in
            var m=0.0
            for k in a.rowPointers[r]..<a.rowPointers[r+1] { m=max(m,abs(a.values[k])) }
            return m > 0 ? 1.0/m : 1.0
        }
    }
    public func apply(matrix a:SparseMatrixCSR, rhs b:[Double]) -> (SparseMatrixCSR,[Double]) {
        var s=a; var sb=b
        for r in 0..<a.size { for k in a.rowPointers[r]..<a.rowPointers[r+1] { s.values[k] *= rowScale[r] }; sb[r] *= rowScale[r] }
        return (s,sb)
    }
}

public struct RobustSparseDCSolver: Sendable {
    public var tolerance:Double = 1e-9
    public init() {}
    public func solve(_ c:Circuit, warmStart:[Double]?=nil) throws -> ElectricalSnapshot {
        let model=SparseMNACompiler.compile(c)
        let scaling=MatrixScaling(model.matrix)
        let (a,b)=scaling.apply(matrix:model.matrix,rhs:model.rhs)
        let iterative=try BiCGSTABSolver(tolerance:tolerance,maxIterations:800).solve(a,b:b,initial:warmStart)
        if iterative.1.termination == .converged && iterative.0.allSatisfy(\.isFinite) {
            let x=iterative.0
            return .init(nodeVoltages:[0]+Array(x.prefix(model.nodeVoltageUnknowns)),voltageSourceCurrents:Array(x.suffix(model.voltageSourceCount)),report:iterative.1)
        }
        // Correctness-first fallback. Production revisions can add a sparse direct fallback.
        return try ReferenceDCSolver().solve(c)
    }
}

public enum SwitchState: Sendable, Codable { case open, closed }
public struct ResistiveSwitch: Sendable, Codable {
    public var a:NodeID; public var b:NodeID; public var state:SwitchState
    public var closedOhms:Double; public var openOhms:Double
    public init(a:NodeID,b:NodeID,state:SwitchState,closedOhms:Double=0.02,openOhms:Double=1e12){self.a=a;self.b=b;self.state=state;self.closedOhms=closedOhms;self.openOhms=openOhms}
    public var resistor:Resistor {.init(a:a,b:b,resistance:state == .closed ? closedOhms:openOhms)}
}

public struct CapacitorCompanion: Sendable, Codable {
    public var capacitanceF:Double; public var previousVoltage:Double=0
    public init(capacitanceF:Double){self.capacitanceF=capacitanceF}
    public func backwardEuler(dt:Double,a:NodeID,b:NodeID)->(Resistor,CurrentSource){let g=capacitanceF/max(dt,1e-12);return(.init(a:a,b:b,resistance:1/max(g,1e-18)),.init(from:b,to:a,amperes:g*previousVoltage))}
}

public struct InductorCompanion: Sendable, Codable {
    public var inductanceH:Double; public var previousCurrent:Double=0
    public init(inductanceH:Double){self.inductanceH=inductanceH}
    public func backwardEuler(dt:Double,a:NodeID,b:NodeID)->(Resistor,CurrentSource){let r=inductanceH/max(dt,1e-12);return(.init(a:a,b:b,resistance:max(r,1e-12)),.init(from:a,to:b,amperes:previousCurrent))}
}

public struct ScheduledEvent: Sendable, Equatable { public var time:Double; public var sequence:Int; public var name:String }
public struct DeterministicEventQueue: Sendable {
    private var nextSequence=0; private var events:[ScheduledEvent]=[]
    public init(){}
    public mutating func schedule(at time:Double,name:String){events.append(.init(time:time,sequence:nextSequence,name:name));nextSequence+=1;events.sort{$0.time == $1.time ? $0.sequence<$1.sequence:$0.time<$1.time}}
    public mutating func pop(through time:Double)->[ScheduledEvent]{let i=events.firstIndex(where:{$0.time>time}) ?? events.endIndex;let r=Array(events[..<i]);events.removeFirst(i);return r}
}
