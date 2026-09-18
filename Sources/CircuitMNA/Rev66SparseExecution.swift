import Foundation
import ElectricalCore

/// Precomputed CSR lookup table for topology-stable stamping. Values can be restamped without scanning rows.
public struct CSRStampPlan66: Sendable {
    public let positions: [UInt64:Int]
    public init(matrix: SparseMatrixCSR) {
        var p:[UInt64:Int]=[:]; p.reserveCapacity(matrix.values.count)
        for r in 0..<matrix.size { for k in matrix.rowPointers[r]..<matrix.rowPointers[r+1] { p[Self.key(r,matrix.columnIndices[k])] = k } }
        positions=p
    }
    @inline(__always) static func key(_ r:Int,_ c:Int)->UInt64 { (UInt64(UInt32(r)) << 32) | UInt64(UInt32(c)) }
    @inline(__always) public func index(row:Int,column:Int)->Int? { positions[Self.key(row,column)] }
}

public enum FastSparseStamper66 {
    public static func stamp(_ c:Circuit, into model:inout SparseMNAModel, plan:CSRStampPlan66) {
        for i in model.matrix.values.indices { model.matrix.values[i]=0 }
        for i in model.rhs.indices { model.rhs[i]=0 }
        let nv=c.nodeCount-1
        @inline(__always) func idx(_ node:Int)->Int? { node == 0 ? nil : node-1 }
        @inline(__always) func add(_ r:Int?,_ col:Int?,_ v:Double){ guard let r,let col,let k=plan.index(row:r,column:col) else{return}; model.matrix.values[k] += v }
        for r in c.resistors { let g=1/r.resistance;let i=idx(r.a),j=idx(r.b);add(i,i,g);add(j,j,g);add(i,j,-g);add(j,i,-g) }
        for s in c.currentSources { if let i=idx(s.from){model.rhs[i]-=s.amperes};if let j=idx(s.to){model.rhs[j]+=s.amperes} }
        for (k,s) in c.voltageSources.enumerated(){let q=nv+k;let i=idx(s.positive),j=idx(s.negative);add(i,q,1);add(q,i,1);add(j,q,-1);add(q,j,-1);model.rhs[q]=s.volts}
    }
}

public struct ElectricalIsland66: Sendable, Codable, Equatable { public var nodes:[Int]; public var resistorIndices:[Int]; public var currentSourceIndices:[Int]; public var voltageSourceIndices:[Int] }
public enum ElectricalIslandDecomposer66 {
    /// Finds topology-independent connected node sets. Ground may appear in multiple islands and is treated as a common reference, not a coupling edge between unrelated circuits.
    public static func decompose(_ c:Circuit)->[ElectricalIsland66] {
        let nonGround=Array(1..<c.nodeCount); var adj:[Int:Set<Int>]=[:]; for n in nonGround {adj[n]=[]}
        func connect(_ a:Int,_ b:Int){ if a != 0 && b != 0 {adj[a,default:[]].insert(b);adj[b,default:[]].insert(a)} }
        for x in c.resistors{connect(x.a,x.b)};for x in c.currentSources{connect(x.from,x.to)};for x in c.voltageSources{connect(x.positive,x.negative)}
        var seen:Set<Int>=[];var out:[ElectricalIsland66]=[]
        for start in nonGround where !seen.contains(start){var stack=[start],nodes:Set<Int>=[];while let n=stack.popLast(){guard seen.insert(n).inserted else{continue};nodes.insert(n);stack.append(contentsOf:adj[n] ?? [])};let ns=nodes.sorted();let set=nodes
            let ri=c.resistors.indices.filter{let x=c.resistors[$0];return (x.a==0 && set.contains(x.b)) || (x.b==0 && set.contains(x.a)) || (set.contains(x.a)&&set.contains(x.b))}
            let ci=c.currentSources.indices.filter{let x=c.currentSources[$0];return (x.from==0 && set.contains(x.to)) || (x.to==0 && set.contains(x.from)) || (set.contains(x.from)&&set.contains(x.to))}
            let vi=c.voltageSources.indices.filter{let x=c.voltageSources[$0];return (x.positive==0 && set.contains(x.negative)) || (x.negative==0 && set.contains(x.positive)) || (set.contains(x.positive)&&set.contains(x.negative))}
            out.append(.init(nodes:ns,resistorIndices:Array(ri),currentSourceIndices:Array(ci),voltageSourceIndices:Array(vi)))
        }
        return out
    }
}

public struct SolverPerformanceReport66:Sendable,Codable,Equatable{public var unknowns:Int;public var nonzeros:Int;public var islands:Int;public var iterations:Int;public var residual:Double;public var converged:Bool}
public enum SolverPerformanceCorpus66 {
    public static func report(_ c:Circuit)throws->SolverPerformanceReport66{let m=SparseMNACompiler.compile(c);var s=ReusableBiCGSTABSolver65();let (_,r)=try s.solve(m.matrix,b:m.rhs);return .init(unknowns:m.matrix.size,nonzeros:m.matrix.values.count,islands:ElectricalIslandDecomposer66.decompose(c).count,iterations:r.iterations,residual:r.residual,converged:r.termination == .converged)}
}
