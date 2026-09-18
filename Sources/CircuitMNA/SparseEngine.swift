import Foundation
import ElectricalCore

public struct SparseMatrixCSR: Sendable, Equatable {
    public let size: Int
    public let rowPointers: [Int]
    public let columnIndices: [Int]
    public var values: [Double]
    public init(size: Int, rowPointers: [Int], columnIndices: [Int], values: [Double]) {
        self.size=size; self.rowPointers=rowPointers; self.columnIndices=columnIndices; self.values=values
    }
    public func multiplied(by x:[Double]) -> [Double] {
        precondition(x.count == size); var y=Array(repeating:0.0,count:size)
        for r in 0..<size { var s=0.0; for k in rowPointers[r]..<rowPointers[r+1] { s += values[k]*x[columnIndices[k]] }; y[r]=s }
        return y
    }
}

public struct SparseMNAModel: Sendable {
    public var matrix: SparseMatrixCSR
    public var rhs: [Double]
    public var nodeVoltageUnknowns: Int
    public var voltageSourceCount: Int
}

public enum SparseMNACompiler {
    /// Compiles only physically present MNA positions. The sparsity pattern is stable while topology is stable.
    public static func compile(_ c:Circuit) -> SparseMNAModel {
        let nv=c.nodeCount-1, m=c.voltageSources.count, n=nv+m
        var rows=Array(repeating:Set<Int>(),count:n)
        func idx(_ node:Int)->Int? { node == 0 ? nil : node-1 }
        func add(_ r:Int?,_ col:Int?) { if let r,let col { rows[r].insert(col) } }
        for r in c.resistors { let i=idx(r.a),j=idx(r.b); add(i,i);add(j,j);add(i,j);add(j,i) }
        for (k,s) in c.voltageSources.enumerated(){let q=nv+k;let i=idx(s.positive),j=idx(s.negative);add(i,q);add(q,i);add(j,q);add(q,j)}
        for i in 0..<n { rows[i].insert(i) }
        var rp=[0],ci:[Int]=[]; for row in rows { ci.append(contentsOf:row.sorted());rp.append(ci.count) }
        var model=SparseMNAModel(matrix:.init(size:n,rowPointers:rp,columnIndices:ci,values:Array(repeating:0,count:ci.count)),rhs:Array(repeating:0,count:n),nodeVoltageUnknowns:nv,voltageSourceCount:m)
        stamp(c,into:&model); return model
    }
    public static func stamp(_ c:Circuit, into model:inout SparseMNAModel) {
        model.matrix.values=Array(repeating:0,count:model.matrix.values.count); model.rhs=Array(repeating:0,count:model.rhs.count)
        let nv=c.nodeCount-1
        func idx(_ node:Int)->Int? { node == 0 ? nil : node-1 }
        func add(_ r:Int?,_ col:Int?,_ v:Double){guard let r,let col else{return};for k in model.matrix.rowPointers[r]..<model.matrix.rowPointers[r+1] where model.matrix.columnIndices[k] == col {model.matrix.values[k]+=v;return}}
        for r in c.resistors {let g=1/r.resistance;let i=idx(r.a),j=idx(r.b);add(i,i,g);add(j,j,g);add(i,j,-g);add(j,i,-g)}
        for s in c.currentSources {if let i=idx(s.from){model.rhs[i]-=s.amperes};if let j=idx(s.to){model.rhs[j]+=s.amperes}}
        for (k,s) in c.voltageSources.enumerated(){let q=nv+k;let i=idx(s.positive),j=idx(s.negative);add(i,q,1);add(q,i,1);add(j,q,-1);add(q,j,-1);model.rhs[q]=s.volts}
    }
}

public struct JacobiPreconditioner: Sendable {
    public var inverseDiagonal:[Double]
    public init(_ a:SparseMatrixCSR){var d=Array(repeating:1.0,count:a.size);for r in 0..<a.size {for k in a.rowPointers[r]..<a.rowPointers[r+1] where a.columnIndices[k] == r {let v=a.values[k];d[r]=abs(v)>1e-18 ? 1/v : 1;break}};inverseDiagonal=d}
    public func apply(_ x:[Double])->[Double]{zip(x,inverseDiagonal).map(*)}
}

public struct BiCGSTABSolver: Sendable {
    public var tolerance:Double; public var maxIterations:Int
    public init(tolerance:Double=1e-10,maxIterations:Int=500){self.tolerance=tolerance;self.maxIterations=maxIterations}
    public func solve(_ a:SparseMatrixCSR,b:[Double],initial:[Double]?=nil) throws -> ([Double],SolverReport) {
        let n=b.count; guard n == a.size else{throw SolverError.nonFinite};var x=initial ?? Array(repeating:0,count:n)
        let pre=JacobiPreconditioner(a); func dot(_ x:[Double],_ y:[Double])->Double{zip(x,y).reduce(0){$0+$1.0*$1.1}}
        func norm(_ x:[Double])->Double{sqrt(dot(x,x))};func sub(_ x:[Double],_ y:[Double])->[Double]{zip(x,y).map(-)}
        var r=sub(b,a.multiplied(by:x)), r0=r, p=Array(repeating:0.0,count:n),v=p
        var rhoOld=1.0,alpha=1.0,omega=1.0;let nb=max(norm(b),1.0);var rel=norm(r)/nb;if rel<tolerance{return(x,.init(termination:.converged,iterations:0,residual:rel,unknownCount:n))}
        for iter in 0..<maxIterations {
            let rho=dot(r0,r);guard rho.isFinite && abs(rho)>1e-30 else{break}
            if iter == 0 {p=r} else {let beta=(rho/rhoOld)*(alpha/omega);p=(0..<n).map{r[$0]+beta*(p[$0]-omega*v[$0])}}
            let phat=pre.apply(p);v=a.multiplied(by:phat);let denom=dot(r0,v);guard abs(denom)>1e-30 else{break};alpha=rho/denom
            let s=(0..<n).map{r[$0]-alpha*v[$0]};if norm(s)/nb<tolerance{x=(0..<n).map{x[$0]+alpha*phat[$0]};return(x,.init(termination:.converged,iterations:iter+1,residual:norm(s)/nb,unknownCount:n))}
            let shat=pre.apply(s),t=a.multiplied(by:shat),tt=dot(t,t);guard abs(tt)>1e-30 else{break};omega=dot(t,s)/tt;guard omega.isFinite && abs(omega)>1e-30 else{break}
            x=(0..<n).map{x[$0]+alpha*phat[$0]+omega*shat[$0]};r=(0..<n).map{s[$0]-omega*t[$0]};rel=norm(r)/nb;if rel<tolerance{return(x,.init(termination:.converged,iterations:iter+1,residual:rel,unknownCount:n))};rhoOld=rho
        }
        return(x,.init(termination:.iterationLimit,iterations:maxIterations,residual:rel,unknownCount:n))
    }
}

public struct SparseDCSolver: Sendable {
    public init(){}
    public func solve(_ c:Circuit)throws->ElectricalSnapshot{let m=SparseMNACompiler.compile(c);let (x,r)=try BiCGSTABSolver().solve(m.matrix,b:m.rhs);guard r.termination == .converged else{throw SolverError.singularMatrix};return .init(nodeVoltages:[0]+Array(x.prefix(m.nodeVoltageUnknowns)),voltageSourceCurrents:Array(x.suffix(m.voltageSourceCount)),report:r)}
}
