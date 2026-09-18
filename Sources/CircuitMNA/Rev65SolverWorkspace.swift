import Foundation
import ElectricalCore

/// Reusable allocation workspace for iterative sparse solves. Keeps hot vectors alive across solves.
public struct BiCGSTABWorkspace65: Sendable {
    public private(set) var capacity: Int = 0
    public var r:[Double]=[], r0:[Double]=[], p:[Double]=[], v:[Double]=[], s:[Double]=[], t:[Double]=[], phat:[Double]=[], shat:[Double]=[], ax:[Double]=[], invDiag:[Double]=[]
    public init(size:Int=0){ ensure(size) }
    public mutating func ensure(_ n:Int){ guard n != capacity else{return}; capacity=n; let z=Array(repeating:0.0,count:n); r=z;r0=z;p=z;v=z;s=z;t=z;phat=z;shat=z;ax=z;invDiag=Array(repeating:1,count:n) }
}

public enum SparseKernel65 {
    @inline(__always) public static func multiply(_ a:SparseMatrixCSR,_ x:[Double],into y:inout [Double]) {
        precondition(x.count==a.size); if y.count != a.size { y=Array(repeating:0,count:a.size) }
        for row in 0..<a.size { var sum=0.0; for k in a.rowPointers[row]..<a.rowPointers[row+1] { sum += a.values[k]*x[a.columnIndices[k]] }; y[row]=sum }
    }
    @inline(__always) static func dot(_ x:[Double],_ y:[Double])->Double { var s=0.0; for i in x.indices{s += x[i]*y[i]}; return s }
    @inline(__always) static func norm(_ x:[Double])->Double { sqrt(dot(x,x)) }
}

public struct ReusableBiCGSTABSolver65: Sendable {
    public var tolerance:Double=1e-10; public var maxIterations:Int=500; public var workspace=BiCGSTABWorkspace65()
    public init(tolerance:Double=1e-10,maxIterations:Int=500){self.tolerance=tolerance;self.maxIterations=maxIterations}
    public mutating func solve(_ a:SparseMatrixCSR,b:[Double],initial:[Double]?=nil)throws->([Double],SolverReport){
        let n=b.count; guard n==a.size else{throw SolverError.nonFinite}; workspace.ensure(n); var x=initial ?? Array(repeating:0,count:n)
        for row in 0..<n { workspace.invDiag[row]=1; for k in a.rowPointers[row]..<a.rowPointers[row+1] where a.columnIndices[k]==row { let d=a.values[k]; workspace.invDiag[row]=abs(d)>1e-18 ? 1/d : 1; break } }
        SparseKernel65.multiply(a,x,into:&workspace.ax); for i in 0..<n {workspace.r[i]=b[i]-workspace.ax[i];workspace.r0[i]=workspace.r[i];workspace.p[i]=0;workspace.v[i]=0}
        var rhoOld=1.0,alpha=1.0,omega=1.0; let nb=max(SparseKernel65.norm(b),1); var rel=SparseKernel65.norm(workspace.r)/nb
        if rel<tolerance{return(x,.init(termination:.converged,iterations:0,residual:rel,unknownCount:n))}
        for iter in 0..<maxIterations {
            let rho=SparseKernel65.dot(workspace.r0,workspace.r); guard rho.isFinite && abs(rho)>1e-30 else{break}
            if iter==0 { for i in 0..<n {workspace.p[i]=workspace.r[i]} } else { let beta=(rho/rhoOld)*(alpha/omega); for i in 0..<n {workspace.p[i]=workspace.r[i]+beta*(workspace.p[i]-omega*workspace.v[i])} }
            for i in 0..<n {workspace.phat[i]=workspace.invDiag[i]*workspace.p[i]}; SparseKernel65.multiply(a,workspace.phat,into:&workspace.v)
            let denom=SparseKernel65.dot(workspace.r0,workspace.v); guard abs(denom)>1e-30 else{break}; alpha=rho/denom
            for i in 0..<n {workspace.s[i]=workspace.r[i]-alpha*workspace.v[i]}; let srel=SparseKernel65.norm(workspace.s)/nb
            if srel<tolerance {for i in 0..<n{x[i]+=alpha*workspace.phat[i]};return(x,.init(termination:.converged,iterations:iter+1,residual:srel,unknownCount:n))}
            for i in 0..<n {workspace.shat[i]=workspace.invDiag[i]*workspace.s[i]}; SparseKernel65.multiply(a,workspace.shat,into:&workspace.t); let tt=SparseKernel65.dot(workspace.t,workspace.t); guard abs(tt)>1e-30 else{break}; omega=SparseKernel65.dot(workspace.t,workspace.s)/tt; guard omega.isFinite && abs(omega)>1e-30 else{break}
            for i in 0..<n{x[i]+=alpha*workspace.phat[i]+omega*workspace.shat[i];workspace.r[i]=workspace.s[i]-omega*workspace.t[i]}; rel=SparseKernel65.norm(workspace.r)/nb
            if rel<tolerance{return(x,.init(termination:.converged,iterations:iter+1,residual:rel,unknownCount:n))};rhoOld=rho
        }
        return(x,.init(termination:.iterationLimit,iterations:maxIterations,residual:rel,unknownCount:n))
    }
}

public struct SparseBenchmarkResult65:Sendable,Codable,Equatable{public var unknowns:Int;public var nonzeros:Int;public var iterations:Int;public var residual:Double;public var converged:Bool}
public enum SparseBenchmark65 { public static func run(_ circuit:Circuit)throws->SparseBenchmarkResult65{let m=SparseMNACompiler.compile(circuit);var s=ReusableBiCGSTABSolver65();let (_,r)=try s.solve(m.matrix,b:m.rhs);return .init(unknowns:m.matrix.size,nonzeros:m.matrix.values.count,iterations:r.iterations,residual:r.residual,converged:r.termination == .converged)} }
