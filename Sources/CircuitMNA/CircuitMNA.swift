import Foundation
import ElectricalCore

public enum SolverError: Error, Equatable { case singularMatrix, nonFinite }

public struct CSRPattern: Sendable, Equatable { public var rowPointers:[Int]; public var columnIndices:[Int]; public init(rowPointers:[Int],columnIndices:[Int]){self.rowPointers=rowPointers;self.columnIndices=columnIndices} }
public enum CSRCompiler { public static func fullPattern(size:Int)->CSRPattern { var rp=[0]; var ci:[Int]=[]; for _ in 0..<size { ci.append(contentsOf: 0..<size); rp.append(ci.count) }; return .init(rowPointers:rp,columnIndices:ci) } }

/// Golden/reference MNA solver. Node 0 is ground. Voltage sources add branch-current unknowns.
public struct ReferenceDCSolver: Sendable {
    public init() {}
    public func solve(_ circuit:Circuit) throws -> ElectricalSnapshot {
        let nv=circuit.nodeCount-1, m=circuit.voltageSources.count, n=nv+m
        guard n>0 else{return .init(nodeVoltages:[0],report:.init(termination:.converged,iterations:0,residual:0,unknownCount:0))}
        var a=Array(repeating:Array(repeating:0.0,count:n),count:n), z=Array(repeating:0.0,count:n)
        func idx(_ node:Int)->Int? { node == 0 ? nil : node-1 }
        for r in circuit.resistors { let g=1/r.resistance; if let i=idx(r.a){a[i][i]+=g}; if let j=idx(r.b){a[j][j]+=g}; if let i=idx(r.a),let j=idx(r.b){a[i][j]-=g;a[j][i]-=g} }
        for s in circuit.currentSources { if let i=idx(s.from){z[i]-=s.amperes}; if let j=idx(s.to){z[j]+=s.amperes} }
        for (k,s) in circuit.voltageSources.enumerated(){let q=nv+k;if let i=idx(s.positive){a[i][q]+=1;a[q][i]+=1};if let j=idx(s.negative){a[j][q]-=1;a[q][j]-=1};z[q]=s.volts}
        let oa=a, oz=z
        for p in 0..<n { var pivot=p; for r in p..<n where abs(a[r][p])>abs(a[pivot][p]){pivot=r}; guard abs(a[pivot][p])>1e-14 else{throw SolverError.singularMatrix}; if pivot != p {a.swapAt(p,pivot);z.swapAt(p,pivot)}; let d=a[p][p]; for c in p..<n{a[p][c]/=d};z[p]/=d; for r in 0..<n where r != p {let f=a[r][p];if f==0{continue};for c in p..<n{a[r][c]-=f*a[p][c]};z[r]-=f*z[p]} }
        guard z.allSatisfy({$0.isFinite}) else{throw SolverError.nonFinite}
        var residual=0.0; for r in 0..<n {var pred=0.0;for c in 0..<n{pred += oa[r][c]*z[c]};residual=max(residual,abs(pred-oz[r]))}
        return .init(nodeVoltages:[0]+Array(z.prefix(nv)),voltageSourceCurrents:Array(z.suffix(m)),report:.init(termination:.converged,iterations:1,residual:residual,unknownCount:n))
    }
}

public struct ElectricalIsland: Sendable, Equatable { public var nodes:[NodeID] }
public enum IslandDetector {
    public static func detect(_ c:Circuit)->[ElectricalIsland]{ var adj=Array(repeating:Set<Int>(),count:c.nodeCount); func link(_ a:Int,_ b:Int){adj[a].insert(b);adj[b].insert(a)}; for r in c.resistors{link(r.a,r.b)};for s in c.currentSources{link(s.from,s.to)};for s in c.voltageSources{link(s.positive,s.negative)}; var seen=Set<Int>(),out:[ElectricalIsland]=[]; for start in 0..<c.nodeCount where !seen.contains(start){var q=[start],nodes:[Int]=[];seen.insert(start);while let x=q.popLast(){nodes.append(x);for y in adj[x] where !seen.contains(y){seen.insert(y);q.append(y)}};out.append(.init(nodes:nodes.sorted()))};return out }
}
