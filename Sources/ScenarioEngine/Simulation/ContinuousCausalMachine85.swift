import Foundation
import ElectricalCore
import CircuitMNA

// Rev85: one continuous causal loop. Scenario inputs mutate physical parameters;
// measurements/evidence observe the resulting state and never author symptoms.

public struct EEPhysicalParameters85: Codable, Equatable, Sendable {
    public var sourceVoltageV = 24.0
    public var sourceResistanceOhm = 0.35
    public var disconnectResistanceOhm = 0.02
    public var fuseResistanceOhm = 0.06
    public var plcOutputResistanceOhm = 0.05
    public var terminalResistanceOhm = 0.08
    public var cableResistanceOhm = 0.35
    public var junctionResistanceOhm = 0.12
    public var coilResistanceOhm = 1_200.0
    public var coilInductanceH = 0.35
    public var terminalThermalMassJPerC = 22.0
    public var terminalCoolingWPerC = 0.18
    public var ambientC = 25.0
    public var fuseI2tLimitA2s = 3.0
    public var overloadTripMemory = 1.0
    public var overloadHeatGain = 0.20
    public var overloadCoolingPerSecond = 0.025
    public var coilPullInForceN = 8.0
    public var coilDropoutForceN = 4.0
    public var valveTravelSeconds = 0.35
    public var processSourcePressurePSI = 900.0
    public var processSinkPressurePSI = 500.0
    public var processTimeConstantS = 1.8
    public var transmitterLRVPSI = 0.0
    public var transmitterURVPSI = 1_000.0
    public var transmitterDampingS = 0.20
    public var loopSupplyV = 24.0
    public var loopSeriesResistanceOhm = 500.0
    public var transmitterMinimumComplianceV = 8.0
    public var aiRawMin = 3_277.0
    public var aiRawMax = 16_383.0

    public init() {}
}

public struct EEThermalState85: Codable, Equatable, Sendable {
    public var terminalTemperatureC = 25.0
    public var overloadMemory01 = 0.0
    public var fuseI2tA2s = 0.0
    public init() {}
}

public struct EEProtectionState85: Codable, Equatable, Sendable {
    public var fuseOpen = false
    public var overloadTripped = false
    public init() {}
}

public struct EEPLCState85: Codable, Equatable, Sendable {
    public var outputCommand = true
    public var analogRaw = 0.0
    public var processValuePSI = 0.0
    public var responsePermissive = false
    public var scanCount = 0
    public init() {}
}

public struct EEActuatorState85: Codable, Equatable, Sendable {
    public var coilCurrentA = 0.0
    public var magneticForceN = 0.0
    public var armaturePosition01 = 0.0
    public var valvePosition01 = 0.0
    public init() {}
}

public struct EEProcessState85: Codable, Equatable, Sendable {
    public var pressurePSI = 500.0
    public var flow01 = 0.0
    public init() {}
}

public struct EEInstrumentationState85: Codable, Equatable, Sendable {
    public var sensedPressurePSI = 500.0
    public var commandedCurrentMA = 12.0
    public var actualLoopCurrentMA = 12.0
    public init() {}
}

public struct EEElectricalState85: Codable, Equatable, Sendable {
    public var nodeVoltages = Array(repeating: 0.0, count: 9)
    public var sourceCurrentA = 0.0
    public var controlCurrentA = 0.0
    public var converged = false
    public var residual = 1e300
    public init() {}
}

public struct EEEvidenceFrame85: Codable, Equatable, Sendable {
    public var time: Double
    public var terminalVoltageV: Double
    public var terminalTemperatureC: Double
    public var coilCurrentA: Double
    public var valvePosition01: Double
    public var pressurePSI: Double
    public var loopCurrentMA: Double
    public var plcProcessValuePSI: Double
}

public struct EEMachineState85: Codable, Equatable, Sendable {
    public var time = 0.0
    public var parameters = EEPhysicalParameters85()
    public var commissioning = EECommissioningState83()
    public var electrical = EEElectricalState85()
    public var thermal = EEThermalState85()
    public var protection = EEProtectionState85()
    public var plc = EEPLCState85()
    public var actuator = EEActuatorState85()
    public var process = EEProcessState85()
    public var instrumentation = EEInstrumentationState85()
    public var evidence: [EEEvidenceFrame85] = []
    public var _rev85 = EERev85LatentState()
    public init() {}
}

public enum EEFaultKind85: String, Codable, CaseIterable, Sendable {
    case degradedTerminal
    case openTerminal
    case shortToGround
    case weakSupply
    case coilWindingDamage
    case valveBinding
    case transmitterZeroDrift
    case plcScalingError
}

public struct EEFaultInjection85: Codable, Equatable, Sendable {
    public var targetIdentity: String
    public var kind: EEFaultKind85
    public var severity01: Double
    public init(targetIdentity: String, kind: EEFaultKind85, severity01: Double) {
        self.targetIdentity = targetIdentity
        self.kind = kind
        self.severity01 = min(1, max(0, severity01))
    }
}

public enum EEContinuousCausalMachine85 {
    private static let openResistance = 1e12

    /// Mutates physical/configuration parameters only. It never authors symptoms.
    public static func inject(_ fault: EEFaultInjection85, into state: inout EEMachineState85) {
        let s = fault.severity01
        switch fault.kind {
        case .degradedTerminal:
            state.parameters.terminalResistanceOhm = 0.08 + 220.0 * s
        case .openTerminal:
            state.parameters.terminalResistanceOhm = openResistance
        case .shortToGround:
            // Represented during stamping; severity controls shunt resistance.
            state.parameters.terminalResistanceOhm = max(0.08, state.parameters.terminalResistanceOhm)
            state.shortToGroundSeverity85 = s
        case .weakSupply:
            state.parameters.sourceResistanceOhm = 0.35 + 30.0 * s
        case .coilWindingDamage:
            state.parameters.coilResistanceOhm = max(40.0, 1_200.0 * (1.0 - 0.75 * s))
        case .valveBinding:
            state.valveBindingSeverity85 = s
        case .transmitterZeroDrift:
            state.transmitterZeroDriftPSI85 = 80.0 * s
        case .plcScalingError:
            state.plcScalingError01_85 = s
        }
    }

    public static func step(_ state: inout EEMachineState85, dt requestedDT: Double) {
        let dt = min(0.05, max(0.0005, requestedDT))

        // A few deterministic coupling iterations let topology/electromechanics settle
        // without giving any downstream domain permission to invent electrical truth.
        for _ in 0..<3 {
            solveElectrical(&state)
            integrateThermalAndProtection(&state, dt: dt / 3.0)
            integrateActuator(&state, dt: dt / 3.0)
        }

        integrateProcess(&state, dt: dt)
        integrateInstrumentation(&state, dt: dt)
        scanPLC(&state)
        state.time += dt
        captureEvidence(&state)
    }

    public static func run(_ state: inout EEMachineState85, duration: Double, dt: Double = 0.01) {
        var remaining = max(0, duration)
        while remaining > 1e-12 {
            let h = min(dt, remaining)
            step(&state, dt: h)
            remaining -= h
        }
    }

    public static func measure(redNode: Int, blackNode: Int, state: EEMachineState85) -> Double {
        let v = state.electrical.nodeVoltages
        guard v.indices.contains(redNode), v.indices.contains(blackNode) else { return 0 }
        return v[redNode] - v[blackNode]
    }

    private static func solveElectrical(_ state: inout EEMachineState85) {
        let p = state.parameters
        let c = state.commissioning
        let protectionOpen = state.protection.fuseOpen || state.protection.overloadTripped || c.overloadTripped
        let fuseHealthy = c.fuseAHealthy && c.fuseBHealthy && c.fuseCHealthy && !protectionOpen
        let rDisconnect = c.disconnectClosed ? p.disconnectResistanceOhm : openResistance
        let rFuse = fuseHealthy ? p.fuseResistanceOhm : openResistance
        let rPLC = (state.plc.outputCommand && c.plcDO4) ? p.plcOutputResistanceOhm : openResistance
        let rCoil = c.solenoidCoilHealthy ? max(1e-6, p.coilResistanceOhm) : openResistance

        var resistors: [Resistor] = [
            .init(a: 1, b: 2, resistance: max(1e-6, p.sourceResistanceOhm)),
            .init(a: 2, b: 3, resistance: rDisconnect),
            .init(a: 3, b: 4, resistance: rFuse),
            .init(a: 4, b: 5, resistance: rPLC),
            .init(a: 5, b: 6, resistance: max(1e-6, p.terminalResistanceOhm)),
            .init(a: 6, b: 7, resistance: max(1e-6, p.cableResistanceOhm)),
            .init(a: 7, b: 8, resistance: max(1e-6, p.junctionResistanceOhm)),
            .init(a: 8, b: 0, resistance: rCoil)
        ]
        if state.shortToGroundSeverity85 > 0 {
            let shunt = max(0.08, 8.0 * (1.0 - state.shortToGroundSeverity85))
            resistors.append(.init(a: 6, b: 0, resistance: shunt))
        }

        let circuit = Circuit(
            nodeCount: 9,
            resistors: resistors,
            voltageSources: [.init(positive: 1, negative: 0, volts: p.sourceVoltageV)]
        )
        guard let solved = try? ReferenceDCSolver().solve(circuit) else {
            state.electrical = EEElectricalState85()
            return
        }
        let v = solved.nodeVoltages
        let sourceI = (v[1] - v[2]) / max(p.sourceResistanceOhm, 1e-9)
        let controlI = (v[5] - v[6]) / max(p.terminalResistanceOhm, 1e-9)
        state.electrical.nodeVoltages = v
        state.electrical.sourceCurrentA = sourceI
        state.electrical.controlCurrentA = controlI
        state.electrical.converged = solved.converged
        state.electrical.residual = solved.residual
    }

    private static func integrateThermalAndProtection(_ state: inout EEMachineState85, dt: Double) {
        let p = state.parameters
        let i = abs(state.electrical.controlCurrentA)
        let terminalLossW = i * i * p.terminalResistanceOhm
        let coolingW = (state.thermal.terminalTemperatureC - p.ambientC) * p.terminalCoolingWPerC
        state.thermal.terminalTemperatureC += (terminalLossW - coolingW) / max(p.terminalThermalMassJPerC, 1e-6) * dt

        state.thermal.fuseI2tA2s += i * i * dt
        if state.thermal.fuseI2tA2s >= p.fuseI2tLimitA2s { state.protection.fuseOpen = true }

        let normalizedCurrent = i / 0.020
        let heating = max(0, normalizedCurrent * normalizedCurrent - 1) * p.overloadHeatGain
        let cooling = state.thermal.overloadMemory01 * p.overloadCoolingPerSecond
        state.thermal.overloadMemory01 = min(2, max(0, state.thermal.overloadMemory01 + (heating - cooling) * dt))
        if state.thermal.overloadMemory01 >= p.overloadTripMemory { state.protection.overloadTripped = true }
    }

    private static func integrateActuator(_ state: inout EEMachineState85, dt: Double) {
        let p = state.parameters
        let coilV = state.electrical.nodeVoltages.indices.contains(8) ? state.electrical.nodeVoltages[8] : 0
        let r = max(p.coilResistanceOhm, 1e-6)
        let l = max(p.coilInductanceH, 1e-6)
        // Analytic (exponential) update of the RL coil current: unconditionally stable
        // regardless of dt relative to the electrical time constant tau = l / r, unlike
        // explicit Euler (di = (v - r*i)/l * dt), which oscillates and can be clamped to a
        // false zero steady state when dt exceeds a few multiples of tau.
        let tau = l / r
        let steadyStateI = coilV / r
        let decay = exp(-dt / tau)
        state.actuator.coilCurrentA = max(0, steadyStateI + (state.actuator.coilCurrentA - steadyStateI) * decay)
        state.actuator.magneticForceN = min(24, state.actuator.coilCurrentA / 0.020 * 18)

        let targetArmature: Double
        if state.actuator.magneticForceN >= p.coilPullInForceN { targetArmature = 1 }
        else if state.actuator.magneticForceN <= p.coilDropoutForceN { targetArmature = 0 }
        else { targetArmature = state.actuator.armaturePosition01 }
        let armatureRate = 8.0
        state.actuator.armaturePosition01 += (targetArmature - state.actuator.armaturePosition01) * min(1, armatureRate * dt)

        let free = state.commissioning.valveMechanicallyFree ? 1.0 : 0.0
        let availableTravel = free * (1.0 - state.valveBindingSeverity85)
        let targetValve = state.actuator.armaturePosition01 * availableTravel
        let travelRate = 1.0 / max(p.valveTravelSeconds, 0.01)
        state.actuator.valvePosition01 += (targetValve - state.actuator.valvePosition01) * min(1, travelRate * dt)
        state.actuator.valvePosition01 = min(1, max(0, state.actuator.valvePosition01))
    }

    private static func integrateProcess(_ state: inout EEMachineState85, dt: Double) {
        let p = state.parameters
        state.process.flow01 = state.actuator.valvePosition01
        let target = p.processSinkPressurePSI + (p.processSourcePressurePSI - p.processSinkPressurePSI) * state.process.flow01
        let alpha = min(1, dt / max(p.processTimeConstantS, 1e-6))
        state.process.pressurePSI += (target - state.process.pressurePSI) * alpha
    }

    private static func integrateInstrumentation(_ state: inout EEMachineState85, dt: Double) {
        let p = state.parameters
        let sensedTarget = state.process.pressurePSI + state.transmitterZeroDriftPSI85
        let alpha = min(1, dt / max(p.transmitterDampingS, 1e-6))
        state.instrumentation.sensedPressurePSI += (sensedTarget - state.instrumentation.sensedPressurePSI) * alpha
        let span = max(1e-6, p.transmitterURVPSI - p.transmitterLRVPSI)
        let fraction = min(1, max(0, (state.instrumentation.sensedPressurePSI - p.transmitterLRVPSI) / span))
        let commandedMA = 4.0 + 16.0 * fraction
        state.instrumentation.commandedCurrentMA = commandedMA

        // Compliance-limited two-wire loop approximation. This remains an observed
        // electrical consequence, not a scenario-authored analog value.
        let requestedA = commandedMA / 1000.0
        let maxA = max(0, (p.loopSupplyV - p.transmitterMinimumComplianceV) / max(p.loopSeriesResistanceOhm, 1e-6))
        state.instrumentation.actualLoopCurrentMA = min(requestedA, maxA) * 1000.0
    }

    private static func scanPLC(_ state: inout EEMachineState85) {
        let p = state.parameters
        let mA = state.instrumentation.actualLoopCurrentMA
        let fraction = min(1, max(0, (mA - 4.0) / 16.0))
        state.plc.analogRaw = p.aiRawMin + (p.aiRawMax - p.aiRawMin) * fraction
        let normalPV = p.transmitterLRVPSI + (p.transmitterURVPSI - p.transmitterLRVPSI) * fraction
        state.plc.processValuePSI = normalPV * (1.0 + 0.25 * state.plcScalingError01_85)
        state.plc.responsePermissive = state.plc.processValuePSI >= 600
        state.plc.scanCount += 1
    }

    private static func captureEvidence(_ state: inout EEMachineState85) {
        let terminalV = state.electrical.nodeVoltages.indices.contains(6) ? state.electrical.nodeVoltages[6] : 0
        state.evidence.append(.init(
            time: state.time,
            terminalVoltageV: terminalV,
            terminalTemperatureC: state.thermal.terminalTemperatureC,
            coilCurrentA: state.actuator.coilCurrentA,
            valvePosition01: state.actuator.valvePosition01,
            pressurePSI: state.process.pressurePSI,
            loopCurrentMA: state.instrumentation.actualLoopCurrentMA,
            plcProcessValuePSI: state.plc.processValuePSI
        ))
        if state.evidence.count > 4_096 { state.evidence.removeFirst(state.evidence.count - 4_096) }
    }
}

// Private persisted degradation/configuration details are intentionally part of
// machine state so save/reload and deterministic replay preserve physical history.
extension EEMachineState85 {
    fileprivate var shortToGroundSeverity85: Double {
        get { _rev85.shortToGroundSeverity }
        set { _rev85.shortToGroundSeverity = newValue }
    }
    fileprivate var valveBindingSeverity85: Double {
        get { _rev85.valveBindingSeverity }
        set { _rev85.valveBindingSeverity = newValue }
    }
    fileprivate var transmitterZeroDriftPSI85: Double {
        get { _rev85.transmitterZeroDriftPSI }
        set { _rev85.transmitterZeroDriftPSI = newValue }
    }
    fileprivate var plcScalingError01_85: Double {
        get { _rev85.plcScalingError01 }
        set { _rev85.plcScalingError01 = newValue }
    }
}

public struct EERev85LatentState: Codable, Equatable, Sendable {
    public var shortToGroundSeverity = 0.0
    public var valveBindingSeverity = 0.0
    public var transmitterZeroDriftPSI = 0.0
    public var plcScalingError01 = 0.0
    public init() {}
}

// Stored explicitly rather than via associated-object tricks so Codable remains deterministic.
extension EEMachineState85 {
    // Kept public for Codable/source stability but treated as engine-internal state.
    public var rev85LatentState: EERev85LatentState {
        get { _rev85 }
        set { _rev85 = newValue }
    }
}
