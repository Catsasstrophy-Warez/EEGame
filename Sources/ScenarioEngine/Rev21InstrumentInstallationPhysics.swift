import Foundation
import ElectricalCore

// Rev21: installation-level instrumentation and burner-train physics.
// Educational abstractions. They intentionally model diagnostic boundaries and do not
// encode site safety procedures or replace OEM installation/service documentation.

public enum ValvePosition: String, Sendable, Codable { case open, closed, intermediate }
public enum ImpulseLegFault: String, Sendable, Codable, Hashable { case plugged, leaking, frozen, gasPocket, liquidHead, reversed }

public struct ProcessTap: Sendable, Codable {
    public var pressurePSI: Double
    public var temperatureF: Double
    public init(pressurePSI: Double = 0, temperatureF: Double = 70) { self.pressurePSI = pressurePSI; self.temperatureF = temperatureF }
}

public struct ImpulseLeg: Sendable, Codable {
    public var rootValve: ValvePosition = .open
    public var manifoldValve: ValvePosition = .open
    public var faults: Set<ImpulseLegFault> = []
    public var trappedPressurePSI: Double = 0
    public var leakFraction: Double = 0
    public var hydrostaticHeadPSI: Double = 0
    public init() {}
    public mutating func sense(processPSI: Double) -> Double {
        if rootValve == .closed || manifoldValve == .closed || faults.contains(.plugged) || faults.contains(.frozen) { return trappedPressurePSI }
        var p = processPSI + hydrostaticHeadPSI
        if faults.contains(.leaking) { p *= max(0, 1 - max(leakFraction, 0.15)) }
        trappedPressurePSI = p
        return p
    }
}

public struct ThreeValveManifold: Sendable, Codable {
    public var highBlock: ValvePosition = .open
    public var lowBlock: ValvePosition = .open
    public var equalizer: ValvePosition = .closed
    public init() {}
    public func differential(high: Double, low: Double) -> Double {
        if equalizer == .open { return 0 }
        let h = highBlock == .closed ? 0 : high
        let l = lowBlock == .closed ? 0 : low
        return h - l
    }
}

public struct PressureInstallation: Sendable, Codable {
    public var tap = ProcessTap()
    public var impulse = ImpulseLeg()
    public var transmitter = IndicatingTransmitter(tag: "PIT-301", kind: .PIT, lrv: 0, urv: 300)
    public init() {}
    public mutating func step(dt: Double) { let sensed = impulse.sense(processPSI: tap.pressurePSI); transmitter.step(actual: sensed, dt: dt) }
}

public enum TemperatureSensorKind: String, Sendable, Codable { case typeK, rtd }
public enum TemperatureFault: String, Sendable, Codable, Hashable { case openSensor, shortedSensor, wrongExtensionWire, poorThermowellContact }
public struct TemperatureInstallation: Sendable, Codable {
    public var sensor: TemperatureSensorKind = .typeK
    public var processF: Double = 70
    public var thermowellLagSeconds: Double = 2
    public var thermowellF: Double = 70
    public var junctionOffsetF: Double = 0
    public var faults: Set<TemperatureFault> = []
    public var transmitter = IndicatingTransmitter(tag: "TIT-301", kind: .TIT, lrv: 0, urv: 1200)
    public init() {}
    public mutating func step(dt: Double) {
        let lag = faults.contains(.poorThermowellContact) ? thermowellLagSeconds * 6 : thermowellLagSeconds
        thermowellF += (processF - thermowellF) * min(1, dt / max(0.001, lag))
        var sensed = thermowellF + junctionOffsetF
        if faults.contains(.wrongExtensionWire) { sensed += 25 }
        if faults.contains(.openSensor) { transmitter.faults.insert(.upscaleAlarm); return }
        if faults.contains(.shortedSensor) { sensed = 70 }
        transmitter.step(actual: sensed, dt: dt)
    }
}

public struct DPFlowInstallation: Sendable, Codable {
    public var highLeg = ImpulseLeg()
    public var lowLeg = ImpulseLeg()
    public var manifold = ThreeValveManifold()
    public var maxDPInH2O: Double = 100
    public var maxFlow: Double = 1000
    public var actualDPInH2O: Double = 0
    public var squareRootEnabled = true
    public var lowFlowCutoffPercent = 1.0
    public init() {}
    public mutating func measuredFlow() -> Double {
        let h = highLeg.sense(processPSI: actualDPInH2O)
        let l = lowLeg.sense(processPSI: 0)
        let dp = max(0, manifold.differential(high: h, low: l))
        let fraction = min(1, dp / max(1e-9, maxDPInH2O))
        let f = squareRootEnabled ? sqrt(fraction) : fraction
        let flow = maxFlow * f
        return flow < maxFlow * lowFlowCutoffPercent / 100 ? 0 : flow
    }
}

public enum LevelTechnology: String, Sendable, Codable { case hydrostaticDP, radar, guidedWaveRadar, displacer, ultrasonic }
public enum LevelFault: String, Sendable, Codable, Hashable { case blockedNozzle, foam, falseEcho, badReferenceHeight, wetLegLoss }
public struct LevelInstallation: Sendable, Codable {
    public var technology: LevelTechnology = .radar
    public var actualPercent: Double = 0
    public var faults: Set<LevelFault> = []
    public var transmitter = IndicatingTransmitter(tag: "LIT-301", kind: .LIT, lrv: 0, urv: 100)
    public init() {}
    public mutating func step(dt: Double) {
        var sensed = actualPercent
        if faults.contains(.blockedNozzle) { transmitter.faults.insert(.frozenPV); return }
        if faults.contains(.foam) && (technology == .radar || technology == .ultrasonic) { sensed *= 0.75 }
        if faults.contains(.falseEcho) { sensed = min(100, sensed + 20) }
        if faults.contains(.badReferenceHeight) { sensed = min(100, sensed + 10) }
        transmitter.step(actual: sensed, dt: dt)
    }
}

public struct DVCInstallation: Sendable, Codable {
    public var controller = DVCValveController()
    public var instrumentAirPSI: Double = 30
    public var actuatorPressurePSI: Double = 0
    public var packingFriction: Double = 0.05
    public var boosterGain: Double = 1
    public var stemPositionPercent: Double = 0
    public var positionFeedbackPercent: Double = 0
    public var feedbackDisconnected = false
    public init() {}
    public mutating func step(dt: Double) {
        controller.supplyPSI = instrumentAirPSI
        controller.friction = packingFriction
        controller.step(dt: dt)
        actuatorPressurePSI = min(instrumentAirPSI, 3 + controller.travelPercent / 100 * 12 * boosterGain)
        let target = controller.travelPercent
        let frictionFactor = max(0.05, 1 - packingFriction)
        stemPositionPercent += (target - stemPositionPercent) * min(1, dt * 4 * frictionFactor)
        if !feedbackDisconnected { positionFeedbackPercent = stemPositionPercent }
        else { controller.faults.insert(.travelFeedbackFault) }
    }
}

public enum BurnerFieldFault: String, Sendable, Codable, Hashable { case pilotSolenoidOpen, mainSolenoidOpen, ignitionOpen, flameSensorOpen, proofSwitchStuck, lowDCVoltage, blownOutputFuse }
public struct BurnerElectricalTrain: Sendable, Codable {
    public var supplyV: Double = 24
    public var outputFuseIntact = true
    public var pilotCoilOhms: Double = 36
    public var mainCoilOhms: Double = 36
    public var ignitionPrimaryOhms: Double = 1.2
    public var faults: Set<BurnerFieldFault> = []
    public init() {}
    public func pilotCurrent(command: Bool) -> Double { current(command: command, resistance: faults.contains(.pilotSolenoidOpen) ? .infinity : pilotCoilOhms) }
    public func mainCurrent(command: Bool) -> Double { current(command: command, resistance: faults.contains(.mainSolenoidOpen) ? .infinity : mainCoilOhms) }
    public func ignitionCurrent(command: Bool) -> Double { current(command: command, resistance: faults.contains(.ignitionOpen) ? .infinity : ignitionPrimaryOhms) }
    private func current(command: Bool, resistance: Double) -> Double { guard command, outputFuseIntact, !faults.contains(.blownOutputFuse), supplyV > 10, resistance.isFinite else { return 0 }; return supplyV / max(1e-6, resistance) }
}

public struct MX5Bus: Sendable, Codable {
    public var modules: [MX5Module] = []
    public var canWireOpen = false
    public var canShorted = false
    public var rs485BiasHealthy = true
    public init(modules: [MX5Module] = []) { self.modules = modules }
    public var onlineCount: Int { (canWireOpen || canShorted) ? 0 : modules.filter(\.online).count }
    public var audit: [String] {
        var issues:[String]=[]
        let ids=modules.map(\.nodeID); if Set(ids).count != ids.count { issues.append("duplicate node id") }
        let terms=modules.filter(\.canTermination).count; if modules.count > 1 && terms != 2 { issues.append("CAN termination should be present at both bus ends") }
        if canWireOpen { issues.append("CAN conductor open") }; if canShorted { issues.append("CAN short") }; if !rs485BiasHealthy { issues.append("RS-485 bias/termination fault") }
        return issues
    }
}

public struct Rev21FieldPackage: Sendable, Codable {
    public var pit = PressureInstallation()
    public var tit = TemperatureInstallation()
    public var fit = DPFlowInstallation()
    public var lit = LevelInstallation()
    public var dvc = DVCInstallation()
    public var burner = BurnerManagementSystem()
    public var burnerElectrical = BurnerElectricalTrain()
    public var mx5Bus = MX5Bus()
    public init() {}
    public mutating func step(dt: Double) { pit.step(dt:dt); tit.step(dt:dt); _ = fit.measuredFlow(); lit.step(dt:dt); dvc.step(dt:dt); burner.step(dt:dt) }
}
