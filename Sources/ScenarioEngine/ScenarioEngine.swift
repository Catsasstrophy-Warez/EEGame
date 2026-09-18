import ElectricalCore
import CircuitMNA

public struct TrainingScenario: Sendable { public var title:String; public var briefing:String; public var circuit:Circuit; public init(title:String,briefing:String,circuit:Circuit){self.title=title;self.briefing=briefing;self.circuit=circuit} }

public enum BenchNode { public static let ground=0, supply=1, afterFuse=2, afterStop=3, coil=4 }
public enum StarterFault: Sendable { case none, blownFuse, openStop, highResistanceCoil }

/// First playable truth model: 24 VDC source -> fuse -> NC STOP -> START/seal-in -> contactor coil.
public struct MotorStarterBench: Sendable {
    public var fuseClosed=true; public var stopClosed=true; public var startPressed=false; public var contactorLatched=false; public var fault:StarterFault = .none
    public init(){}
    public mutating func pressStart(){startPressed=true;if fuseClosed && stopClosed && fault != .blownFuse && fault != .openStop {contactorLatched=true}}
    public mutating func releaseStart(){startPressed=false}
    public mutating func pressStop(){stopClosed=false;contactorLatched=false}
    public mutating func resetStop(){stopClosed=true}
    public func circuit()->Circuit {
        var r:[Resistor]=[]
        let fuseOK=fuseClosed && fault != .blownFuse; if fuseOK {r.append(.init(a:BenchNode.supply,b:BenchNode.afterFuse,resistance:0.02))}
        let stopOK=stopClosed && fault != .openStop; if stopOK {r.append(.init(a:BenchNode.afterFuse,b:BenchNode.afterStop,resistance:0.02))}
        if startPressed || contactorLatched {r.append(.init(a:BenchNode.afterStop,b:BenchNode.coil,resistance:0.02))}
        let coilR:Double = fault == .highResistanceCoil ? 480 : 120
        r.append(.init(a:BenchNode.coil,b:BenchNode.ground,resistance:coilR))
        // tiny leakage references preserve measurable de-energized/floating branches without pretending copper is ideal.
        r.append(.init(a:BenchNode.afterFuse,b:0,resistance:1e9));r.append(.init(a:BenchNode.afterStop,b:0,resistance:1e9));r.append(.init(a:BenchNode.coil,b:0,resistance:1e9))
        return .init(nodeCount:5,resistors:r,voltageSources:[.init(positive:BenchNode.supply,negative:0,volts:24)])
    }
    public func snapshot() throws -> ElectricalSnapshot { try ReferenceDCSolver().solve(circuit()) }
    public static let training = TrainingScenario(title:"Bench 01: The Starter",briefing:"Commission and troubleshoot a 24 VDC three-wire START/STOP contactor circuit using measurements, not quest markers.",circuit:MotorStarterBench().circuit())
}
