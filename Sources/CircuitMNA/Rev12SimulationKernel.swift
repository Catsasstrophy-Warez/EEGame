import Foundation
import ElectricalCore

public enum SimulationDomain: String, Sendable, Codable { case electricalTransient, controls, mechanical, process, thermal, historian }
public struct DomainSchedule: Sendable, Codable, Equatable { public var domain: SimulationDomain; public var period: Double; public var accumulator: Double = 0; public init(_ domain:SimulationDomain, period:Double){self.domain=domain;self.period=period} }
public struct MultiRateScheduler: Sendable {
    public var schedules:[DomainSchedule]
    public init(schedules:[DomainSchedule] = [.init(.controls,period:0.01),.init(.mechanical,period:0.005),.init(.process,period:0.05),.init(.thermal,period:0.5),.init(.historian,period:1)]) { self.schedules=schedules }
    public mutating func advance(dt:Double)->[SimulationDomain] { var due:[SimulationDomain]=[]; for i in schedules.indices { schedules[i].accumulator += dt; while schedules[i].accumulator + 1e-12 >= schedules[i].period { schedules[i].accumulator -= schedules[i].period; due.append(schedules[i].domain) } }; return due }
}

public struct SolverHealth: Sendable, Codable, Equatable { public var solves=0; public var fallbacks=0; public var failures=0; public var worstResidual=0.0; public mutating func record(_ r:SolverReport, fallback:Bool=false){solves += 1;if fallback{fallbacks += 1};if !r.termination.isConverged{failures += 1};worstResidual=max(worstResidual,r.residual)} }
extension SolverTermination { fileprivate var isConverged:Bool { if case .converged = self { return true }; return false } }

public struct SparseSlotIndex: Sendable { public var slots:[UInt64:Int]=[:]; public init(_ m:SparseMatrixCSR){ for r in 0..<m.size { for k in m.rowPointers[r]..<m.rowPointers[r+1] { slots[(UInt64(r)<<32)|UInt64(m.columnIndices[k])] = k } } }; public func slot(row:Int,col:Int)->Int?{slots[(UInt64(row)<<32)|UInt64(col)]} }

public enum PowerStudyFault: Sendable, Codable, Equatable { case threePhase, lineToGround, lineToLine }
public struct SourceEquivalent: Sendable, Codable, Equatable { public var lineVoltage:Double; public var sourceImpedanceOhms:Double; public init(lineVoltage:Double=480,sourceImpedanceOhms:Double=0.02){self.lineVoltage=lineVoltage;self.sourceImpedanceOhms=sourceImpedanceOhms} }
public enum PowerStudy {
    public static func boltedFaultCurrent(_ s:SourceEquivalent, fault:PowerStudyFault)->Double { switch fault { case .threePhase: return (s.lineVoltage/sqrt(3))/max(1e-9,s.sourceImpedanceOhms); case .lineToGround: return (s.lineVoltage/sqrt(3))/max(1e-9,s.sourceImpedanceOhms*3); case .lineToLine: return s.lineVoltage/max(1e-9,2*s.sourceImpedanceOhms) } }
}

public struct TimeCurrentPoint: Sendable, Codable, Equatable { public var currentMultiple:Double; public var seconds:Double; public init(currentMultiple:Double,seconds:Double){self.currentMultiple=currentMultiple;self.seconds=seconds} }
public struct TimeCurrentCurve: Sendable, Codable, Equatable { public var points:[TimeCurrentPoint]; public init(points:[TimeCurrentPoint]){self.points=points.sorted{$0.currentMultiple<$1.currentMultiple}}; public func tripTime(multiple:Double)->Double? { guard let first=points.first, let last=points.last else{return nil}; if multiple<=first.currentMultiple{return first.seconds}; if multiple>=last.currentMultiple{return last.seconds}; for i in 1..<points.count where multiple <= points[i].currentMultiple { let a=points[i-1],b=points[i];let f=(multiple-a.currentMultiple)/(b.currentMultiple-a.currentMultiple);return exp(log(a.seconds)+(log(b.seconds)-log(a.seconds))*f) }; return nil } }
public struct CoordinationStudy: Sendable, Equatable { public var downstreamTripsFirst:Bool; public var marginSeconds:Double; public static func evaluate(upstream:TimeCurrentCurve,downstream:TimeCurrentCurve,multiple:Double)->CoordinationStudy { let u=upstream.tripTime(multiple:multiple) ?? .infinity,d=downstream.tripTime(multiple:multiple) ?? .infinity;return .init(downstreamTripsFirst:d<u,marginSeconds:u-d) } }
