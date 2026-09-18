import Foundation
import ElectricalCore
import CircuitMNA

/// Production-facing orchestration boundary. UI issues commands here instead of
/// mutating independent domain state directly.
public struct EESimulationSnapshot75: Codable, Equatable, Sendable {
    public var time: Double
    public var physicsSteps: Int
    public var plcScans: Int
    public var networkEvents: Int
    public var sourceVoltage: Double
    public var terminalVoltage: Double
    public var currentA: Double
    public var conductorResistanceOhm: Double
    public var temperatureC: Double

    public init(
        time: Double = 0,
        physicsSteps: Int = 0,
        plcScans: Int = 0,
        networkEvents: Int = 0,
        sourceVoltage: Double = 24,
        terminalVoltage: Double = 0,
        currentA: Double = 0,
        conductorResistanceOhm: Double = 122.2,
        temperatureC: Double = 25
    ) {
        self.time = time
        self.physicsSteps = physicsSteps
        self.plcScans = plcScans
        self.networkEvents = networkEvents
        self.sourceVoltage = sourceVoltage
        self.terminalVoltage = terminalVoltage
        self.currentA = currentA
        self.conductorResistanceOhm = conductorResistanceOhm
        self.temperatureC = temperatureC
    }
}

public struct EESimulationCoordinator75: Codable, Sendable {
    public private(set) var snapshot = EESimulationSnapshot75()
    public private(set) var isRunning = false
    public private(set) var isSlow = false
    public private(set) var isReplaying = false

    private var conductor = ConductorPhysics(
        baseResistance: 122.2,
        thermal: .init(
            temperatureC: 25,
            ambientC: 25,
            thermalMassJPerC: 120,
            coolingWPerC: 0.35
        )
    )

    public init() {
        solveElectricalTruth(dt: 0)
    }

    public mutating func apply(_ control: EESimulationControl71) {
        switch control {
        case .run:
            isRunning = true
            isSlow = false
            isReplaying = false
            stepPhysics(dt: 0.02)
        case .pause:
            isRunning = false
        case .slow:
            isRunning = true
            isSlow = true
            isReplaying = false
            stepPhysics(dt: 0.005)
        case .stepPhysics:
            isRunning = false
            stepPhysics(dt: 0.02)
        case .stepPLCScan:
            isRunning = false
            snapshot.plcScans += 1
        case .stepNetworkEvent:
            isRunning = false
            snapshot.networkEvents += 1
        case .replay:
            isRunning = false
            isReplaying = true
        }
    }

    public mutating func stepPhysics(dt: Double) {
        let clampedDT = max(0, dt)
        solveElectricalTruth(dt: clampedDT)
        snapshot.time += clampedDT
        snapshot.physicsSteps += 1
    }

    public func electricalVision(identity: String) -> EEElectricalVision72 {
        EEElectricalVision72(
            identity: identity,
            voltageIn: snapshot.sourceVoltage,
            voltageOut: snapshot.terminalVoltage,
            currentA: snapshot.currentA,
            resistanceOhm: snapshot.conductorResistanceOhm,
            temperatureC: snapshot.temperatureC
        )
    }

    private mutating func solveElectricalTruth(dt: Double) {
        let loadOhm = 1_200.0
        let circuit = Circuit(
            nodeCount: 3,
            resistors: [
                .init(a: 1, b: 2, resistance: conductor.resistance),
                .init(a: 2, b: 0, resistance: loadOhm)
            ],
            voltageSources: [
                .init(positive: 1, negative: 0, volts: snapshot.sourceVoltage)
            ]
        )

        guard let solved = try? ReferenceDCSolver().solve(circuit),
              solved.nodeVoltages.count > 2 else {
            snapshot.terminalVoltage = 0
            snapshot.currentA = 0
            return
        }

        let source = solved.nodeVoltages[1]
        let terminal = solved.nodeVoltages[2]
        let current = (source - terminal) / max(conductor.resistance, 1e-12)

        conductor.step(current: current, dt: dt)
        snapshot.terminalVoltage = terminal
        snapshot.currentA = current
        snapshot.conductorResistanceOhm = conductor.resistance
        snapshot.temperatureC = conductor.thermal.temperatureC
    }
}
