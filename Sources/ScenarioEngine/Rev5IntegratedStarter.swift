import ElectricalCore
import CircuitMNA

public struct IntegratedStarterRuntime: Sendable {
    public var supplyVolts=24.0
    public var bench=MotorStarterBench(); public var contactor=ContactorPhysics(); public var motor=PhysicalDCMotor(); public var fuse=FuseModel(ratedCurrent:2,tripI2t:18)
    public var lineTermination=TerminationState(); public var powerContact=ContactState(); public var conductor=ConductorTruth(); public var solver=ProductionDCSolver(); public var stepper=AdaptiveTimeStepper(); public var time=0.0
    public init() {}
    public mutating func step(requestedDT:Double?=nil) throws -> ElectricalSnapshot {
        let dt=requestedDT ?? stepper.dt
        if fuse.isOpen { bench.fuseClosed=false }
        // Truth circuit solves control voltage. Contact mechanics then control the power path.
        var c=bench.circuit(); c.voltageSources[0].volts=supplyVolts
        let snap=try solver.solve(c); let coilV=snap.nodeVoltages[BenchNode.coil]
        contactor.step(coilVoltage:coilV,dt:dt); powerContact.command(contactor.energized)
        let pathR=max(1e-6,lineTermination.resistanceOhms + powerContact.resistanceOhms + conductor.resistanceOhms)
        let terminalV = contactor.energized ? max(0,supplyVolts - motor.current*pathR) : 0
        motor.step(voltage:terminalV,loadTorque:0.12,dt:dt)
        let coilCurrent=abs(coilV/max(contactor.coilResistanceOhms,1e-9)); let totalCurrent=abs(motor.current) + coilCurrent
        // FU1 protects the control circuit in this first bench; motor branch protection is modeled separately in later power tiers.
        fuse.step(current:coilCurrent,dt:dt); lineTermination.step(current:totalCurrent,dt:dt); powerContact.step(current:motor.current,dt:dt); conductor.step(current:totalCurrent,dt:dt)
        stepper.update(error:abs(motor.current)*1e-7,eventImminent:powerContact.bounceRemaining>0); time += dt
        return snap
    }
}

public struct BenchProbeSession: Sendable, Equatable {
    public var red:BenchTerminal?; public var black:BenchTerminal?; public init(){}
    public func readVoltage(snapshot:ElectricalSnapshot)->Double? { guard let red,let black else{return nil}; return DigitalMultimeter().dcVoltage(red:BenchLayout.node(for:red),black:BenchLayout.node(for:black),in:snapshot) }
}
