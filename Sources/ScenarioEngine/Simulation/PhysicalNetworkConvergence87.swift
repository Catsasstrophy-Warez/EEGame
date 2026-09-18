import Foundation
import ElectricalCore
import CircuitMNA

// Rev87: Physical Network Convergence.
// One deterministic physical state feeds protection, machines, I/O, instruments and evidence.

public struct EEPhaseVector87: Codable, Equatable, Sendable {
    public var a: Double; public var b: Double; public var c: Double
    public init(_ a: Double = 0, _ b: Double = 0, _ c: Double = 0) { self.a = a; self.b = b; self.c = c }
    public var average: Double { (a + b + c) / 3 }
    public var maximumDeviationPU: Double {
        let avg = max(abs(average), 1e-9)
        return max(abs(a-average), abs(b-average), abs(c-average)) / avg
    }
}

public struct EEThreePhaseSource87: Codable, Equatable, Sendable {
    public var nominalLLV = 480.0
    public var phaseScale = EEPhaseVector87(1,1,1)
    public var sourceResistanceOhm = EEPhaseVector87(0.08,0.08,0.08)
    public var feederResistanceOhm = EEPhaseVector87(0.05,0.05,0.05)
    public var transformerRegulationPU = 0.025
    public init() {}
    public func terminalVoltage(for currents: EEPhaseVector87) -> EEPhaseVector87 {
        let nominalPhase = nominalLLV / sqrt(3)
        func v(_ scale: Double, _ current: Double, _ rs: Double, _ rf: Double) -> Double {
            max(0, nominalPhase * scale * (1 - transformerRegulationPU * min(abs(current) / 100, 1.5)) - abs(current) * (rs + rf))
        }
        return .init(v(phaseScale.a,currents.a,sourceResistanceOhm.a,feederResistanceOhm.a),
                     v(phaseScale.b,currents.b,sourceResistanceOhm.b,feederResistanceOhm.b),
                     v(phaseScale.c,currents.c,sourceResistanceOhm.c,feederResistanceOhm.c))
    }
}

public enum EEProtectionTripCause87: String, Codable, Sendable { case none, thermal, instantaneous, fuseMelt, overload }
public struct EEProtectionState87: Codable, Equatable, Sendable {
    public var breaker = EEBreakerState86()
    public var fuseCurve = EETimeCurrentCurve86(points: [.init(1.1, 3600), .init(2, 8), .init(5, 0.25), .init(10, 0.03)])
    public var fuseRatingA = 15.0
    public var fuseDamage01 = 0.0
    public var overloadClassSeconds = 10.0
    public var overloadMemory01 = 0.0
    public var tripCause: EEProtectionTripCause87 = .none
    public var fuseOpen = false
    public var overloadOpen = false
    public init() {}
    public mutating func integrate(currentA: Double, dt: Double) {
        let wasBreakerOpen = breaker.isOpen
        breaker.integrate(currentA: currentA, dt: dt)
        if !wasBreakerOpen && breaker.isOpen { tripCause = abs(currentA) >= breaker.ratingA * breaker.magneticPickupMultiple ? .instantaneous : .thermal }
        if !fuseOpen {
            let multiple = abs(currentA) / max(fuseRatingA, 1e-9)
            if multiple > 1 { fuseDamage01 += dt / max(fuseCurve.clearingSeconds(at: multiple), 1e-6) }
            else { fuseDamage01 = max(0, fuseDamage01 - dt * 0.001) }
            if fuseDamage01 >= 1 { fuseOpen = true; tripCause = .fuseMelt }
        }
        if !overloadOpen {
            let multiple = abs(currentA) / max(breaker.ratingA, 1e-9)
            if multiple > 1 { overloadMemory01 += dt * pow(multiple, 2) / max(overloadClassSeconds, 1e-6) }
            else { overloadMemory01 = max(0, overloadMemory01 - dt / 60) }
            if overloadMemory01 >= 1 { overloadOpen = true; tripCause = .overload }
        }
    }
    public var conducting: Bool { !breaker.isOpen && !fuseOpen && !overloadOpen }
}

public struct EEContactWear87: Codable, Equatable, Sendable {
    public var contact = EEContactState86()
    public var arcEnergyJ = 0.0
    public var operations: UInt64 = 0
    public var welded = false
    public init() {}
    public mutating func integrate(currentA: Double, voltageV: Double, opening: Bool, closing: Bool, dt: Double) {
        contact.integrate(currentA: currentA, dt: dt)
        if opening || closing {
            let arc = abs(voltageV * currentA) * min(dt, 0.008)
            arcEnergyJ += arc
            contact.degradation01 = min(1, contact.degradation01 + arc * 0.000002)
        }
        if closing { operations &+= 1 }
        if contact.temperatureC > 180 && abs(currentA) > 5 { welded = true }
    }
}

public struct EEInductionMotor87: Codable, Equatable, Sendable {
    public var ratedLLV = 480.0; public var ratedCurrentA = 12.0; public var synchronousRPM = 1800.0
    public var rotorRPM = 0.0; public var inertiaKgM2 = 0.8; public var loadTorqueNm = 25.0
    public var statorR = 0.55; public var rotorR = 0.38; public var leakageX = 1.8
    public var current = EEPhaseVector87(); public var torqueNm = 0.0; public var windingTemperatureC = 25.0
    public init() {}
    public var slip: Double { max(0.005, min(1, 1 - rotorRPM/max(synchronousRPM,1))) }
    public mutating func integrate(phaseVoltage: EEPhaseVector87, energized: Bool, dt: Double) {
        guard energized else { current = .init(); torqueNm = 0; rotorRPM = max(0, rotorRPM - 100*dt); return }
        let z = sqrt(pow(statorR + rotorR/slip,2) + leakageX*leakageX)
        current = .init(abs(phaseVoltage.a)/z, abs(phaseVoltage.b)/z, abs(phaseVoltage.c)/z)
        let vpu = max(0, phaseVoltage.average / (ratedLLV/sqrt(3)))
        torqueNm = 78 * vpu*vpu * (slip / (0.18 + slip*slip)) * 0.22
        let accel = (torqueNm-loadTorqueNm)/max(inertiaKgM2,1e-6)
        rotorRPM = min(synchronousRPM*0.995, max(0, rotorRPM + accel*9.5493*dt))
        let copper = (current.a*current.a + current.b*current.b + current.c*current.c) * statorR
        windingTemperatureC += (copper - (windingTemperatureC-25)*1.1)/220*dt
    }
}

public struct EEPLCInputElectronics87: Codable, Equatable, Sendable {
    public var inputResistanceOhm = 3200.0; public var clampVoltageV = 30.0; public var ledForwardV = 1.8
    public var adcBits = 12; public var filterSeconds = 0.006
    public var terminalV = 0.0; public var inputCurrentMA = 0.0; public var filteredV = 0.0; public var adcCounts = 0; public var logical = false
    public init() {}
    public mutating func sample(fieldV: Double, dt: Double) {
        terminalV = min(max(fieldV,0),clampVoltageV)
        inputCurrentMA = max(0, terminalV-ledForwardV)/max(inputResistanceOhm,1)*1000
        let alpha = min(1,dt/max(filterSeconds,1e-6)); filteredV += (terminalV-filteredV)*alpha
        let maxCount = (1 << adcBits)-1; adcCounts = Int((min(filteredV,30)/30*Double(maxCount)).rounded())
        if logical { if filteredV < 5 { logical = false } } else if filteredV > 15 { logical = true }
    }
}

public struct EEAnalogLoopTopology87: Codable, Equatable, Sendable {
    public var supplyV = 24.0; public var commandMA = 12.0; public var positiveWireOhm = 8.0; public var negativeWireOhm = 8.0
    public var barrierOhm = 120.0; public var burdenOhm = 250.0; public var complianceV = 8.0
    public var currentMA = 0.0; public var aiVoltageV = 0.0; public var transmitterVoltageV = 0.0; public var complianceLimited = false; public var converged = false
    public init() {}
    public mutating func solve() {
        let series = positiveWireOhm + negativeWireOhm + barrierOhm + burdenOhm
        let requestedA = max(0,commandMA/1000); let maxA = max(0,(supplyV-complianceV)/max(series,1e-9)); let actual = min(requestedA,maxA)
        let circuit = Circuit(nodeCount: 2, resistors: [.init(a:1,b:0,resistance:max(burdenOhm,1e-6))], currentSources: [.init(from:0,to:1,amperes:actual)])
        if let s = try? ReferenceDCSolver().solve(circuit) { currentMA=actual*1000; aiVoltageV=s.nodeVoltages[1]; transmitterVoltageV=supplyV-actual*series; complianceLimited=actual+1e-12<requestedA; converged=s.converged }
    }
}

public struct EETransientRing87: Codable, Equatable, Sendable {
    public var capacity = 32768; public private(set) var samples: [EEScopeSample86] = []
    public init() {}
    public mutating func append(_ sample: EEScopeSample86) { samples.append(sample); if samples.count > capacity { samples.removeFirst(samples.count-capacity) } }
}

public struct EEFirstDivergence87: Codable, Equatable, Sendable { public var index: Int; public var time: Double; public var channel: String; public var expected: Double; public var observed: Double }
public enum EECausalReconstruction87 {
    public static func first(reference: [EEScopeSample86], observed: [EEScopeSample86], tolerance: Double = 1e-6) -> EEFirstDivergence87? {
        for i in 0..<min(reference.count,observed.count) {
            let a=reference[i], b=observed[i]
            if a.channel != b.channel || abs(a.value-b.value)>tolerance { return .init(index:i,time:b.time,channel:b.channel,expected:a.value,observed:b.value) }
        }
        return reference.count == observed.count ? nil : .init(index:min(reference.count,observed.count), time: observed.last?.time ?? 0, channel: observed.last?.channel ?? "length", expected: Double(reference.count), observed: Double(observed.count))
    }
}

public struct EEPhysicalNetworkState87: Codable, Equatable, Sendable {
    public var time = 0.0; public var source = EEThreePhaseSource87(); public var protection = EEProtectionState87(); public var contactor = EEContactorState86(); public var contactWear = EEContactWear87(); public var motor = EEInductionMotor87(); public var plcInput = EEPLCInputElectronics87(); public var analog = EEAnalogLoopTopology87(); public var scope = EETransientRing87(); public var soe: [EESOEEvent86] = []
    public init() {}
}

public enum EEPhysicalNetworkMachine87 {
    public static func step(_ s: inout EEPhysicalNetworkState87, coilVoltageV: Double, fieldInputV: Double, dt requested: Double) {
        let dt=min(0.002,max(0.0001,requested)); let oldPhase=s.contactor.phase.rawValue; let oldLogic=s.plcInput.logical; let oldTrip=s.protection.tripCause.rawValue
        let priorClosed=s.contactor.mainContactClosed
        s.contactor.integrate(coilVoltageV: coilVoltageV,coilR:180,coilL:0.25,dt:dt)
        if s.contactWear.welded { s.contactor.phase = .welded; s.contactor.mainContactClosed = true }
        let phaseV=s.source.terminalVoltage(for:s.motor.current)
        let energized=s.contactor.mainContactClosed && s.protection.conducting
        s.motor.integrate(phaseVoltage:phaseV,energized:energized,dt:dt)
        s.protection.integrate(currentA:s.motor.current.average,dt:dt)
        s.contactWear.integrate(currentA:s.motor.current.average,voltageV:phaseV.average,opening:priorClosed && !s.contactor.mainContactClosed,closing:!priorClosed && s.contactor.mainContactClosed,dt:dt)
        s.plcInput.sample(fieldV:fieldInputV,dt:dt); s.analog.solve(); s.time += dt
        for (ch,val) in [("L1.V",phaseV.a),("L2.V",phaseV.b),("L3.V",phaseV.c),("M.A",s.motor.current.average),("M.RPM",s.motor.rotorRPM),("AI.mA",s.analog.currentMA)] { s.scope.append(.init(time:s.time,channel:ch,value:val)) }
        func event(_ id:String,_ p:String,_ o:String,_ n:String) { if o != n { s.soe.append(.init(time:s.time,identity:id,property:p,oldValue:o,newValue:n)) } }
        event("K201","phase",oldPhase,s.contactor.phase.rawValue); event("PLC1:I0.4","state",String(oldLogic),String(s.plcInput.logical)); event("PROT-201","tripCause",oldTrip,s.protection.tripCause.rawValue)
    }
    public static func run(_ s: inout EEPhysicalNetworkState87, duration: Double, coilVoltageV: Double = 24, fieldInputV: Double = 24, dt: Double = 0.001) { var t=max(0,duration); while t>1e-12 { let h=min(dt,t); step(&s,coilVoltageV:coilVoltageV,fieldInputV:fieldInputV,dt:h); t-=h } }
    public static func deterministicFingerprint(_ s: EEPhysicalNetworkState87) -> UInt64 {
        let data=(try? JSONEncoder.sorted.encode(s)) ?? Data(); var h:UInt64=1469598103934665603; for b in data { h ^= UInt64(b); h &*= 1099511628211 }; return h
    }
}
private extension JSONEncoder { static var sorted: JSONEncoder { let e=JSONEncoder(); e.outputFormatting=[.sortedKeys]; return e } }
