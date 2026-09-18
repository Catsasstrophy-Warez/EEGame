import Foundation
import ElectricalCore

public enum FidelityLevel: Int, Sendable, Codable, Comparable {
    case dormant = 0, quasiSteady, dynamic, transient
    public static func < (lhs: FidelityLevel, rhs: FidelityLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum ActivityTrigger: Sendable, Codable, Equatable { case healthySteady, playerNearby, controlChange, motorStart, protectionEvent, nonlinearEvent }
public struct FidelityPolicy: Sendable {
    public init() {}
    public func level(for trigger: ActivityTrigger) -> FidelityLevel {
        switch trigger {
        case .healthySteady: return .quasiSteady
        case .playerNearby, .controlChange: return .dynamic
        case .motorStart, .protectionEvent, .nonlinearEvent: return .transient
        }
    }
}

/// Structure-of-arrays storage for the hot electrical state. Game/render objects are deliberately excluded.
public struct ElectricalStateBuffer: Sendable {
    public var nodeVoltage: ContiguousArray<Double>
    public var previousNodeVoltage: ContiguousArray<Double>
    public var branchCurrent: ContiguousArray<Double>
    public var conductance: ContiguousArray<Double>
    public init(nodeCount: Int, branchCount: Int) {
        nodeVoltage = .init(repeating: 0, count: nodeCount)
        previousNodeVoltage = .init(repeating: 0, count: nodeCount)
        branchCurrent = .init(repeating: 0, count: branchCount)
        conductance = .init(repeating: 0, count: branchCount)
    }
    public mutating func beginStep() { previousNodeVoltage = nodeVoltage }
}

public struct IslandSolvePlan: Sendable, Equatable {
    public var islandIndex: Int
    public var nodes: [NodeID]
    public var fidelity: FidelityLevel
}
public enum IslandSolvePlanner {
    public static func plans(circuit: Circuit, activeNodes: Set<NodeID> = [], transientNodes: Set<NodeID> = []) -> [IslandSolvePlan] {
        IslandDetector.detect(circuit).enumerated().map { index, island in
            let n = Set(island.nodes)
            let fidelity: FidelityLevel = !n.isDisjoint(with: transientNodes) ? .transient : (!n.isDisjoint(with: activeNodes) ? .dynamic : .quasiSteady)
            return .init(islandIndex: index, nodes: island.nodes.sorted(), fidelity: fidelity)
        }
    }
}

public enum ElectricalEventKind: String, Sendable, Codable { case faultApplied, protectionPickup, protectionTrip, busDeenergized, contactorDropout, motorCoast, processResponse, alarmRaised }
public struct CausalElectricalEvent: Sendable, Codable, Equatable {
    public var time: Double; public var kind: ElectricalEventKind; public var source: String; public var causedBy: Int?
    public init(time: Double, kind: ElectricalEventKind, source: String, causedBy: Int? = nil) { self.time=time;self.kind=kind;self.source=source;self.causedBy=causedBy }
}
public struct CausalEventLedger: Sendable {
    public private(set) var events: [CausalElectricalEvent] = []
    public init() {}
    @discardableResult public mutating func append(time: Double, kind: ElectricalEventKind, source: String, causedBy: Int? = nil) -> Int {
        events.append(.init(time: time, kind: kind, source: source, causedBy: causedBy)); return events.count - 1
    }
    public func ancestry(of index: Int) -> [CausalElectricalEvent] {
        guard events.indices.contains(index) else { return [] }
        var result:[CausalElectricalEvent]=[]; var cursor:Int?=index; var guardCount=0
        while let i=cursor, events.indices.contains(i), guardCount < events.count { result.append(events[i]); cursor=events[i].causedBy; guardCount += 1 }
        return result.reversed()
    }
}

public struct KernelProfile: Sendable, Codable, Equatable {
    public var electricalSteps=0, controlsSteps=0, mechanicalSteps=0, processSteps=0, thermalSteps=0
    public var promotedIslands=0, demotedIslands=0
    public var peakUnknowns=0
    public var solverHealth=SolverHealth()
    public init() {}
    public mutating func record(domain: SimulationDomain) {
        switch domain { case .electricalTransient: electricalSteps += 1; case .controls: controlsSteps += 1; case .mechanical: mechanicalSteps += 1; case .process: processSteps += 1; case .thermal: thermalSteps += 1; case .historian: break }
    }
}

public struct FidelityIslandState: Sendable, Equatable {
    public var level:FidelityLevel; public var quietTime:Double = 0
    public init(level:FidelityLevel = .quasiSteady){self.level=level}
    public mutating func update(trigger:ActivityTrigger, dt:Double, demoteAfter:Double=2) -> (promoted:Bool,demoted:Bool) {
        let requested=FidelityPolicy().level(for:trigger); let old=level
        if requested > level { level=requested; quietTime=0 }
        else if trigger == .healthySteady { quietTime += dt; if quietTime >= demoteAfter && level > .quasiSteady { level=FidelityLevel(rawValue:level.rawValue-1)!;quietTime=0 } }
        else { quietTime=0 }
        return (level > old, level < old)
    }
}
