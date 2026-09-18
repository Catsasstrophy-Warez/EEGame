import ElectricalCore
import CircuitMNA

public struct ContactorPhysics: Sendable, Codable, Equatable {
    public var coilResistanceOhms=120.0; public var pickupVolts=18.0; public var dropoutVolts=7.0
    public var armature=0.0; public var energized=false; public var coilThermal=ThermalState(thermalMassJPerC:35,coolingWPerC:0.35)
    public init(){}
    public mutating func step(coilVoltage:Double,dt:Double){
        let target = abs(coilVoltage) >= (energized ? dropoutVolts:pickupVolts) ? 1.0:0.0
        armature += (target-armature)*min(1,dt/0.035); energized = armature > 0.8
        coilThermal.step(powerWatts:coilVoltage*coilVoltage/max(coilResistanceOhms,1e-9),dt:dt)
    }
}

public struct StarterRuntime: Sendable {
    public var bench=MotorStarterBench(); public var contactor=ContactorPhysics(); public var motor=DCMotorState(); public var fuse=FuseModel(ratedCurrent:0.5,tripI2t:2.0)
    public var time=0.0; public init(){}
    public mutating func step(dt:Double) throws -> ElectricalSnapshot {
        if fuse.isOpen { bench.fuseClosed=false }
        let snap=try RobustSparseDCSolver().solve(bench.circuit())
        let cv=snap.nodeVoltages[BenchNode.coil]
        contactor.step(coilVoltage:cv,dt:dt)
        let coilCurrent=abs(cv/max(contactor.coilResistanceOhms,1e-9));fuse.step(current:coilCurrent,dt:dt)
        motor.step(voltage:contactor.energized ? 24:0,load:0.25,dt:dt);time += dt
        return snap
    }
}

public enum BenchTerminal: String, CaseIterable, Sendable { case ground="0V", supply="+24V", afterFuse="FU1:2", afterStop="STOP:2", coil="K1:A1" }
public struct BenchLayout: Sendable {
    public static func node(for t:BenchTerminal)->NodeID { switch t {case .ground:0;case .supply:1;case .afterFuse:2;case .afterStop:3;case .coil:4} }
    public static let schematicToPhysical:[String:BenchTerminal] = ["PS1-":.ground,"PS1+":.supply,"FU1-2":.afterFuse,"PB-STOP-2":.afterStop,"K1-A1":.coil]
}
