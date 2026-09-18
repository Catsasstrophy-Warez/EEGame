import Foundation
import ElectricalCore
import CircuitMNA

// Rev86: deep physical causality layered on Rev85 without creating a second source of truth.
// All diagnostic surfaces are observers. Device state changes only through physical/configuration actions.

public struct EETimeCurrentPoint86: Codable, Equatable, Sendable {
    public var currentMultiple: Double
    public var seconds: Double
    public init(_ currentMultiple: Double, _ seconds: Double) {
        self.currentMultiple = currentMultiple; self.seconds = seconds
    }
}

public struct EETimeCurrentCurve86: Codable, Equatable, Sendable {
    public var points: [EETimeCurrentPoint86]
    public init(points: [EETimeCurrentPoint86]) { self.points = points.sorted { $0.currentMultiple < $1.currentMultiple } }
    public func clearingSeconds(at multiple: Double) -> Double {
        guard let first = points.first, let last = points.last else { return .infinity }
        if multiple <= first.currentMultiple { return first.seconds }
        if multiple >= last.currentMultiple { return last.seconds }
        for pair in zip(points, points.dropFirst()) where multiple >= pair.0.currentMultiple && multiple <= pair.1.currentMultiple {
            let x0 = log(max(pair.0.currentMultiple, 1e-9)), x1 = log(max(pair.1.currentMultiple, 1e-9))
            let y0 = log(max(pair.0.seconds, 1e-9)), y1 = log(max(pair.1.seconds, 1e-9))
            let t = (log(max(multiple, 1e-9)) - x0) / max(x1 - x0, 1e-12)
            return exp(y0 + (y1 - y0) * t)
        }
        return last.seconds
    }
}

public struct EEBreakerState86: Codable, Equatable, Sendable {
    public var ratingA = 10.0
    public var thermalMemory01 = 0.0
    public var magneticPickupMultiple = 8.0
    public var isOpen = false
    public var curve = EETimeCurrentCurve86(points: [.init(1.0, 10_000), .init(2.0, 20), .init(4.0, 2), .init(8.0, 0.05), .init(12.0, 0.015)])
    public init() {}
    public mutating func integrate(currentA: Double, dt: Double) {
        guard !isOpen else { return }
        let multiple = abs(currentA) / max(ratingA, 1e-9)
        if multiple >= magneticPickupMultiple { isOpen = true; return }
        if multiple <= 1 {
            thermalMemory01 = max(0, thermalMemory01 - dt * 0.02)
            return
        }
        let clear = curve.clearingSeconds(at: multiple)
        thermalMemory01 += dt / max(clear, 1e-6)
        if thermalMemory01 >= 1 { isOpen = true }
    }
}

public struct EEContactState86: Codable, Equatable, Sendable {
    public var baseResistanceOhm = 0.001
    public var degradation01 = 0.0
    public var temperatureC = 25.0
    public var ambientC = 25.0
    public var thermalMassJPerC = 12.0
    public var coolingWPerC = 0.16
    public var temperatureCoefficientPerC = 0.0039
    public var effectiveResistanceOhm: Double {
        let degraded = baseResistanceOhm * (1 + 500 * degradation01)
        return max(1e-7, degraded * (1 + temperatureCoefficientPerC * (temperatureC - 20)))
    }
    public init() {}
    public mutating func integrate(currentA: Double, dt: Double) {
        let heat = currentA * currentA * effectiveResistanceOhm
        let cooling = (temperatureC - ambientC) * coolingWPerC
        temperatureC += (heat - cooling) / max(thermalMassJPerC, 1e-6) * dt
        if temperatureC > 90 { degradation01 = min(1, degradation01 + (temperatureC - 90) * 0.000002 * dt) }
    }
}

public enum EEContactorPhase86: String, Codable, Sendable { case released, pullingIn, touching, closed, droppingOut, bouncing, welded }
public struct EEContactorState86: Codable, Equatable, Sendable {
    public var phase: EEContactorPhase86 = .released
    public var coilCurrentA = 0.0
    public var armaturePosition01 = 0.0
    public var armatureVelocity = 0.0
    public var mainContactClosed = false
    public var bounceRemainingS = 0.0
    public var contact = EEContactState86()
    public init() {}
    public mutating func integrate(coilVoltageV: Double, coilR: Double, coilL: Double, dt: Double) {
        // Analytic (exponential) RL update: unconditionally stable regardless of dt vs.
        // the electrical time constant tau = l / r, unlike explicit Euler, which diverges
        // once dt exceeds ~2*tau (see the identical fix in ContinuousCausalMachine85.swift).
        let r = max(coilR, 1e-6), l = max(coilL, 1e-6)
        let tau = l / r
        let steadyStateI = coilVoltageV / r
        let decay = exp(-dt / tau)
        coilCurrentA = max(0, steadyStateI + (coilCurrentA - steadyStateI) * decay)
        let force = min(40, coilCurrentA * 900)
        let spring = 8.0 + 5.0 * armaturePosition01
        armatureVelocity += (force - spring - 2.0 * armatureVelocity) * dt * 2.0
        armaturePosition01 = min(1, max(0, armaturePosition01 + armatureVelocity * dt))
        if phase == .welded { mainContactClosed = true; armaturePosition01 = max(armaturePosition01, 0.95); return }
        if armaturePosition01 >= 0.92 && force > spring {
            if !mainContactClosed { bounceRemainingS = 0.012; phase = .touching }
            if bounceRemainingS > 0 {
                bounceRemainingS -= dt
                mainContactClosed = Int(max(0, bounceRemainingS) / max(dt, 1e-6)) % 2 == 0
                phase = .bouncing
            } else { mainContactClosed = true; phase = .closed }
        } else if force <= spring {
            mainContactClosed = false
            phase = armaturePosition01 > 0.05 ? .droppingOut : .released
        } else { phase = .pullingIn }
    }
}

public struct EEThreePhaseMotorState86: Codable, Equatable, Sendable {
    public var ratedVoltageLL = 480.0
    public var ratedCurrentA = 12.0
    public var lockedRotorMultiple = 6.0
    public var synchronousRPM = 1800.0
    public var rotorRPM = 0.0
    public var inertia = 0.8
    public var loadTorqueNm = 25.0
    public var currentA = 0.0
    public var torqueNm = 0.0
    public var windingTemperatureC = 25.0
    public var slip: Double { max(0, min(1, 1 - rotorRPM / max(synchronousRPM, 1))) }
    public init() {}
    public mutating func integrate(voltageLL: Double, energized: Bool, dt: Double) {
        guard energized else {
            currentA = 0; torqueNm = 0; rotorRPM = max(0, rotorRPM - 120 * dt); return
        }
        let voltagePU = max(0, voltageLL / max(ratedVoltageLL, 1))
        currentA = ratedCurrentA * (1 + (lockedRotorMultiple - 1) * slip) * voltagePU
        torqueNm = 65.0 * voltagePU * voltagePU * max(0.05, slip)
        let acceleration = (torqueNm - loadTorqueNm) / max(inertia, 1e-6)
        rotorRPM = min(synchronousRPM * 0.995, max(0, rotorRPM + acceleration * 9.5493 * dt))
        windingTemperatureC += (currentA * currentA * 0.15 - (windingTemperatureC - 25) * 0.8) / 180 * dt
    }
}

public struct EEDiscreteInputState86: Codable, Equatable, Sendable {
    public var terminalVoltageV = 0.0
    public var filteredVoltageV = 0.0
    public var logicalState = false
    public var onThresholdV = 15.0
    public var offThresholdV = 5.0
    public var filterSeconds = 0.008
    public init() {}
    public mutating func sample(voltageV: Double, dt: Double) {
        terminalVoltageV = voltageV
        let a = min(1, dt / max(filterSeconds, 1e-6))
        filteredVoltageV += (voltageV - filteredVoltageV) * a
        if logicalState { if filteredVoltageV < offThresholdV { logicalState = false } }
        else if filteredVoltageV > onThresholdV { logicalState = true }
    }
}

public struct EEAnalogLoopResult86: Codable, Equatable, Sendable {
    public var currentMA = 0.0
    public var aiVoltageV = 0.0
    public var complianceLimited = false
    public var converged = false
    public init() {}
}

public enum EEAnalogLoopSolver86 {
    // Norton equivalent makes the 4-20 mA transmitter part of CircuitMNA rather than a detached arithmetic path.
    public static func solve(commandMA: Double, supplyV: Double, wireOhm: Double, burdenOhm: Double, complianceV: Double) -> EEAnalogLoopResult86 {
        let requestedA = max(0, commandMA / 1000)
        let maxA = max(0, (supplyV - complianceV) / max(wireOhm + burdenOhm, 1e-9))
        let actualA = min(requestedA, maxA)
        let circuit = Circuit(nodeCount: 2, resistors: [.init(a: 1, b: 0, resistance: max(burdenOhm, 1e-6))], currentSources: [.init(from: 0, to: 1, amperes: actualA)])
        guard let solved = try? ReferenceDCSolver().solve(circuit) else { return EEAnalogLoopResult86() }
        var result = EEAnalogLoopResult86()
        result.currentMA = actualA * 1000
        result.aiVoltageV = solved.nodeVoltages[1]
        result.complianceLimited = actualA + 1e-12 < requestedA
        result.converged = solved.converged
        return result
    }
}

public struct EEDMMReading86: Codable, Equatable, Sendable { public var volts = 0.0; public var loaded = false; public init(volts: Double = 0, loaded: Bool = false) { self.volts = volts; self.loaded = loaded } }
public enum EEDMMSolver86 {
    public static func measure(sourceV: Double, sourceResistanceOhm: Double, inputResistanceOhm: Double) -> EEDMMReading86 {
        let rin = max(inputResistanceOhm, 1e-6)
        let circuit = Circuit(nodeCount: 2, resistors: [.init(a: 1, b: 0, resistance: rin)], voltageSources: [.init(positive: 1, negative: 0, volts: sourceV)])
        // For a Thevenin source, use the closed-form loaded value while still validating the meter branch through MNA.
        let loaded = sourceV * rin / max(sourceResistanceOhm + rin, 1e-9)
        let ok = (try? ReferenceDCSolver().solve(circuit)) != nil
        return EEDMMReading86(volts: loaded, loaded: ok && sourceResistanceOhm > rin * 0.001)
    }
}

public struct EEScopeSample86: Codable, Equatable, Sendable { public var time: Double; public var channel: String; public var value: Double }
public struct EEScopeBuffer86: Codable, Equatable, Sendable {
    public var capacity = 8192
    public var samples: [EEScopeSample86] = []
    public init() {}
    public mutating func append(time: Double, channel: String, value: Double) {
        samples.append(.init(time: time, channel: channel, value: value))
        if samples.count > capacity { samples.removeFirst(samples.count - capacity) }
    }
}

public struct EESOEEvent86: Codable, Equatable, Sendable {
    public var time: Double; public var identity: String; public var property: String; public var oldValue: String; public var newValue: String
}
public struct EECausalEvidence86: Codable, Equatable, Sendable {
    public var soe: [EESOEEvent86] = []
    public var scope = EEScopeBuffer86()
    public init() {}
    public mutating func transition(time: Double, identity: String, property: String, old: String, new: String) {
        guard old != new else { return }
        soe.append(.init(time: time, identity: identity, property: property, oldValue: old, newValue: new))
    }
}

public struct EEDeepMachineState86: Codable, Equatable, Sendable {
    public var time = 0.0
    public var control = EEMachineState85()
    public var breaker = EEBreakerState86()
    public var contactor = EEContactorState86()
    public var motor = EEThreePhaseMotorState86()
    public var plcDI = EEDiscreteInputState86()
    public var analogLoop = EEAnalogLoopResult86()
    public var evidence = EECausalEvidence86()
    public var feederNominalV = 480.0
    public var feederSourceResistanceOhm = 0.35
    public var lastFeederVoltageV = 480.0
    public init() {}
}

public enum EEDeepCausalMachine86 {
    public static func step(_ state: inout EEDeepMachineState86, dt requested: Double) {
        let dt = min(0.01, max(0.0005, requested))
        let oldContactor = state.contactor.phase.rawValue
        let oldDI = state.plcDI.logicalState
        let oldBreaker = state.breaker.isOpen

        EEContinuousCausalMachine85.step(&state.control, dt: dt)
        let coilV = state.control.electrical.nodeVoltages.indices.contains(8) ? state.control.electrical.nodeVoltages[8] : 0
        state.contactor.integrate(coilVoltageV: coilV, coilR: 180, coilL: 0.25, dt: dt)

        let feederV = max(0, state.feederNominalV - state.motor.currentA * state.feederSourceResistanceOhm)
        state.lastFeederVoltageV = feederV
        let energized = state.contactor.mainContactClosed && !state.breaker.isOpen
        state.motor.integrate(voltageLL: feederV, energized: energized, dt: dt)
        state.contactor.contact.integrate(currentA: state.motor.currentA, dt: dt)
        state.breaker.integrate(currentA: state.motor.currentA, dt: dt)

        state.plcDI.sample(voltageV: state.control.electrical.nodeVoltages[6], dt: dt)
        state.analogLoop = EEAnalogLoopSolver86.solve(
            commandMA: state.control.instrumentation.commandedCurrentMA,
            supplyV: state.control.parameters.loopSupplyV,
            wireOhm: 250,
            burdenOhm: 250,
            complianceV: state.control.parameters.transmitterMinimumComplianceV
        )

        state.time += dt
        state.evidence.scope.append(time: state.time, channel: "TB1:12.V", value: state.control.electrical.nodeVoltages[6])
        state.evidence.scope.append(time: state.time, channel: "K201.COIL.A", value: state.contactor.coilCurrentA)
        state.evidence.scope.append(time: state.time, channel: "M201.A", value: state.motor.currentA)
        state.evidence.scope.append(time: state.time, channel: "PIT-101.mA", value: state.analogLoop.currentMA)
        state.evidence.transition(time: state.time, identity: "K201", property: "phase", old: oldContactor, new: state.contactor.phase.rawValue)
        state.evidence.transition(time: state.time, identity: "PLC1:I0.4", property: "state", old: String(oldDI), new: String(state.plcDI.logicalState))
        state.evidence.transition(time: state.time, identity: "CB-201", property: "open", old: String(oldBreaker), new: String(state.breaker.isOpen))
    }

    public static func run(_ state: inout EEDeepMachineState86, duration: Double, dt: Double = 0.002) {
        var remaining = max(0, duration)
        while remaining > 1e-12 { let h = min(dt, remaining); step(&state, dt: h); remaining -= h }
    }

    public static func firstDivergence(reference: EECausalEvidence86, observed: EECausalEvidence86, tolerance: Double = 1e-6) -> EEScopeSample86? {
        let count = min(reference.scope.samples.count, observed.scope.samples.count)
        for i in 0..<count {
            let a = reference.scope.samples[i], b = observed.scope.samples[i]
            if a.channel == b.channel && abs(a.value - b.value) > tolerance { return b }
        }
        return nil
    }
}
