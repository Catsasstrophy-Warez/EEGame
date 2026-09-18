import Foundation
import ElectricalCore
import CircuitMNA

public enum Phase: String, CaseIterable, Sendable, Codable { case a, b, c }
public enum PhaseRotation: String, Sendable, Codable { case abc, acb }

public struct ThreePhaseMeasurement: Sendable, Codable, Equatable {
    public var vab: Double; public var vbc: Double; public var vca: Double
    public init(vab: Double, vbc: Double, vca: Double) { self.vab=vab; self.vbc=vbc; self.vca=vca }
    public var average: Double { (vab+vbc+vca)/3 }
    public var voltageUnbalancePercent: Double {
        let avg=max(average,1e-12); return 100 * max(abs(vab-avg),abs(vbc-avg),abs(vca-avg))/avg
    }
    public var hasPhaseLoss: Bool { min(vab,vbc,vca) < max(average*0.25, 10) }
}

public struct PhaseRotationMeter: Sendable {
    public init() {}
    public func rotation(a: Double, b: Double, c: Double) -> PhaseRotation {
        // Inputs are phase angles in radians normalized to (-pi, pi].
        func wrap(_ x: Double) -> Double { atan2(sin(x),cos(x)) }
        let ab=wrap(b-a); let ac=wrap(c-a)
        return ab < 0 && ac > 0 ? .abc : .acb
    }
}

public struct ControlTransformer: Sendable, Codable, Equatable {
    public var primaryRMS: Double=480; public var secondaryRMS: Double=120; public var ratedVA: Double=250
    public var copperResistanceEquivalent: Double=0.35
    public init() {}
    public var turnsRatio: Double { primaryRMS/max(secondaryRMS,1e-9) }
    public func secondaryVoltage(loadVA: Double) -> Double {
        let loadCurrent=max(0,loadVA)/max(secondaryRMS,1e-9)
        return max(0,secondaryRMS-loadCurrent*copperResistanceEquivalent)
    }
    public func primaryCurrent(loadVA: Double) -> Double { max(0,loadVA)/max(primaryRMS,1e-9) }
}

public struct ThermalOverloadRelay: Sendable, Codable, Equatable {
    public var settingAmps: Double=10; public var thermalMemory: Double=0; public var tripped=false
    public var resetThreshold: Double=0.18
    public init(settingAmps: Double=10) { self.settingAmps=settingAmps }
    public mutating func step(rmsCurrent: Double, dt: Double) {
        guard !tripped else { thermalMemory=max(0,thermalMemory-dt*0.02); return }
        let ratio=abs(rmsCurrent)/max(settingAmps,1e-9)
        let heating=max(0,ratio*ratio-0.85)*dt*0.18
        let cooling=max(0,1-ratio)*dt*0.035
        thermalMemory=max(0,thermalMemory+heating-cooling)
        if thermalMemory >= 1 { tripped=true }
    }
    public mutating func reset() -> Bool { guard tripped && thermalMemory <= resetThreshold else { return false }; tripped=false; return true }
}

public struct InductionMotorState: Sendable, Codable, Equatable {
    public var poles=4; public var frequencyHz=60.0; public var ratedVoltageLL=480.0; public var ratedCurrent=12.0
    public var rotorRPM=0.0; public var temperatureC=25.0; public var phaseAvailable:[Bool]=[true,true,true]
    public init() {}
    public var synchronousRPM: Double { 120*frequencyHz/Double(max(poles,2)) }
    public var slip: Double { max(0,min(1,(synchronousRPM-rotorRPM)/max(synchronousRPM,1e-9))) }
    public mutating func step(lineVoltageRMS: Double, loadFraction: Double, dt: Double) -> Double {
        let phaseFactor=Double(phaseAvailable.filter{$0}.count)/3.0
        guard phaseFactor > 0.34 && lineVoltageRMS > ratedVoltageLL*0.25 else { rotorRPM=max(0,rotorRPM-dt*350); return 0 }
        let voltageFactor=lineVoltageRMS/max(ratedVoltageLL,1e-9)
        let target=synchronousRPM*max(0.0,1-(0.018+0.045*max(0,loadFraction)))
        rotorRPM += (target-rotorRPM)*min(1,dt*(2.2*phaseFactor))
        var amps=ratedCurrent*(0.25+0.75*max(loadFraction,0))*max(0.6,1/voltageFactor)
        if rotorRPM < synchronousRPM*0.25 { amps=max(amps,ratedCurrent*6.0) }
        if phaseFactor < 0.99 { amps *= 1.65 }
        temperatureC += ((amps*amps/(ratedCurrent*ratedCurrent))*3.2-(temperatureC-25)*0.018)*dt
        return amps
    }
}

public enum TransmitterFault: String, Sendable, Codable { case none, openLoop, shortedLoop, upscale, downscale, drift, noisy }
public struct SmartTransmitter420: Sendable, Codable, Equatable {
    public var lrv=0.0, urv=100.0, processValue=0.0, driftEngineeringUnits=0.0, fault:TransmitterFault = .none
    public init() {}
    public func outputMilliamps(noiseSample: Double=0) -> Double {
        switch fault { case .openLoop: return 0; case .shortedLoop: return 0.2; case .upscale: return 21.5; case .downscale: return 3.6; default: break }
        let pv=processValue+driftEngineeringUnits
        let f=min(1,max(0,(pv-lrv)/max(urv-lrv,1e-12)))
        let nominal=4+16*f
        return fault == .noisy ? min(22,max(0,nominal+noiseSample)) : nominal
    }
}

public struct AnalogInputCard: Sendable, Codable, Equatable {
    public var rawMin=0.0, rawMax=32767.0, engineeringMin=0.0, engineeringMax=100.0
    public init() {}
    public func rawCounts(milliamps: Double) -> Double { min(rawMax,max(rawMin,(milliamps-4)/16*(rawMax-rawMin)+rawMin)) }
    public func engineeringValue(raw: Double) -> Double { engineeringMin + (raw-rawMin)/max(rawMax-rawMin,1e-12)*(engineeringMax-engineeringMin) }
}

public struct InstrumentLoopRuntime: Sendable, Codable, Equatable {
    public var transmitter=SmartTransmitter420(); public var input=AnalogInputCard(); public var loopSupply=24.0; public var barrierDropVolts=1.2; public var cableOhms=12.0; public var burdenOhms=250.0
    public init() {}
    public func snapshot(noiseSample: Double=0) -> InstrumentLoopSnapshot {
        let mA=transmitter.outputMilliamps(noiseSample:noiseSample); let amps=mA/1000
        let required=amps*(cableOhms+burdenOhms)+barrierDropVolts+10
        let compliant=loopSupply>=required && mA>0.5
        let delivered=compliant ? mA : max(0,(loopSupply-barrierDropVolts-10)/max(cableOhms+burdenOhms,1e-9)*1000)
        let raw=input.rawCounts(milliamps:delivered); return .init(milliamps:delivered,rawCounts:raw,engineeringValue:input.engineeringValue(raw:raw),compliant:compliant)
    }
}
public struct InstrumentLoopSnapshot: Sendable, Codable, Equatable { public var milliamps:Double; public var rawCounts:Double; public var engineeringValue:Double; public var compliant:Bool }

public struct ClampMeter: Sendable { public init(){}; public func rmsCurrent(samples:[Double])->Double { guard !samples.isEmpty else{return 0}; return sqrt(samples.reduce(0){$0+$1*$1}/Double(samples.count)) } }
public struct InsulationTester: Sendable { public var testVoltage=500.0; public init(testVoltage:Double=500){self.testVoltage=testVoltage}; public func resistanceOhms(leakageAmps:Double)->Double? { guard leakageAmps>0 else{return nil}; return testVoltage/leakageAmps } }
public struct ScopeSample: Sendable, Codable, Equatable { public var time:Double; public var volts:Double }
public struct VirtualOscilloscope: Sendable { public init(){}; public func capture(source:SinglePhaseACSource,start:Double,dt:Double,count:Int)->[ScopeSample] { (0..<max(0,count)).map{let t=start+Double($0)*dt;return .init(time:t,volts:source.instantaneous(at:t))} } }

public struct MCCBucketRuntime: Sendable {
    public var source=ThreePhaseSource(); public var controlTransformer=ControlTransformer(); public var overload=ThermalOverloadRelay(settingAmps:12); public var motor=InductionMotorState(); public var contactorClosed=false
    public init() {}
    public mutating func step(loadFraction:Double,dt:Double)->(current:Double,rpm:Double,tripped:Bool) {
        if overload.tripped { contactorClosed=false }
        let amps = contactorClosed ? motor.step(lineVoltageRMS:source.lineLineRMS,loadFraction:loadFraction,dt:dt) : 0
        overload.step(rmsCurrent:amps,dt:dt)
        if overload.tripped { contactorClosed=false }
        return (amps,motor.rotorRPM,overload.tripped)
    }
}
