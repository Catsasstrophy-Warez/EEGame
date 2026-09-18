import Foundation
import ElectricalCore
import CircuitMNA

public struct ComplexValue: Sendable, Codable, Equatable {
    public var re: Double; public var im: Double
    public init(_ re: Double, _ im: Double = 0) { self.re = re; self.im = im }
    public var magnitude: Double { hypot(re, im) }
    public var angleRadians: Double { atan2(im, re) }
    public static func + (l: Self, r: Self) -> Self { .init(l.re+r.re,l.im+r.im) }
    public static func - (l: Self, r: Self) -> Self { .init(l.re-r.re,l.im-r.im) }
    public static func * (l: Self, r: Self) -> Self { .init(l.re*r.re-l.im*r.im,l.re*r.im+l.im*r.re) }
    public static func / (l: Self, r: Self) -> Self { let d=max(r.re*r.re+r.im*r.im,1e-18); return .init((l.re*r.re+l.im*r.im)/d,(l.im*r.re-l.re*r.im)/d) }
    public static func polar(magnitude: Double, degrees: Double) -> Self { let a=degrees*Double.pi/180; return .init(magnitude*cos(a),magnitude*sin(a)) }
}

public struct ThreePhasePhasorSet: Sendable, Codable, Equatable {
    public var a: ComplexValue; public var b: ComplexValue; public var c: ComplexValue
    public init(lineNeutralRMS: Double = 480/sqrt(3), rotation: PhaseRotation = .abc) {
        a = .polar(magnitude: lineNeutralRMS, degrees: 0)
        if rotation == .abc { b = .polar(magnitude: lineNeutralRMS, degrees: -120); c = .polar(magnitude: lineNeutralRMS, degrees: 120) }
        else { b = .polar(magnitude: lineNeutralRMS, degrees: 120); c = .polar(magnitude: lineNeutralRMS, degrees: -120) }
    }
    public var positiveSequenceMagnitude: Double { let alpha=ComplexValue.polar(magnitude:1,degrees:120); return ((a + alpha*b + alpha*alpha*c) * ComplexValue(1.0/3.0)).magnitude }
    public var negativeSequenceMagnitude: Double { let alpha=ComplexValue.polar(magnitude:1,degrees:120); return ((a + alpha*alpha*b + alpha*c) * ComplexValue(1.0/3.0)).magnitude }
    public var negativeSequencePercent: Double { 100*negativeSequenceMagnitude/max(positiveSequenceMagnitude,1e-12) }
}

public enum TripClass: Double, Sendable, Codable { case class10 = 10, class20 = 20, class30 = 30 }
public struct MotorOverloadCurve: Sendable, Codable, Equatable {
    public var settingAmps: Double; public var tripClass: TripClass; public var thermalMemory = 0.0; public var tripped = false
    public init(settingAmps: Double, tripClass: TripClass = .class10) { self.settingAmps=settingAmps; self.tripClass=tripClass }
    public mutating func step(current: Double, dt: Double) { guard !tripped else { thermalMemory=max(0,thermalMemory-dt/180); return }; let m=abs(current)/max(settingAmps,1e-9); if m > 1 { thermalMemory += pow(m,2.1)*dt/(tripClass.rawValue*6) } else { thermalMemory=max(0,thermalMemory-dt/120) }; if thermalMemory >= 1 { tripped=true } }
}

public struct BreakerThermalMagnetic: Sendable, Codable, Equatable {
    public var ratingAmps: Double; public var magneticMultiple: Double=8; public var thermalMemory=0.0; public var tripped=false
    public init(ratingAmps:Double){self.ratingAmps=ratingAmps}
    public mutating func step(current:Double,dt:Double){guard !tripped else{return};let m=abs(current)/max(ratingAmps,1e-9);if m>=magneticMultiple {tripped=true;return};if m>1 {thermalMemory += pow(m,2)*dt/60}else{thermalMemory=max(0,thermalMemory-dt/180)};if thermalMemory>=1{tripped=true}}
}

public struct InductionMotorEquivalentCircuit: Sendable, Codable, Equatable {
    public var r1=0.35, x1=0.55, r2=0.28, x2=0.42, xm=12.0, poles=4, frequencyHz=60.0
    public init() {}
    public var synchronousRPM:Double {120*frequencyHz/Double(poles)}
    public func approximateCurrent(lineLineRMS:Double, slip:Double)->Double { let s=max(0.005,min(1,slip)); let z=ComplexValue(r1+r2/s,x1+x2); return (lineLineRMS/sqrt(3))/max(z.magnitude,1e-9) }
    public func torqueProxy(lineLineRMS:Double, slip:Double)->Double { let i=approximateCurrent(lineLineRMS:lineLineRMS,slip:slip); return 3*i*i*(r2/max(slip,0.005))/(2*Double.pi*(synchronousRPM/60)) }
}

public enum VFDFault: String, Sendable, Codable { case none, inputPhaseLoss, dcBusUndervoltage, dcBusOvervoltage, overcurrent, motorOvertemperature }
public struct VFDState: Sendable, Codable, Equatable {
    public var inputLineRMS=480.0, dcBusVolts=0.0, commandedHz=0.0, outputHz=0.0, accelHzPerSecond=20.0, maxHz=60.0, enabled=false, fault:VFDFault = .none
    public init() {}
    public mutating func step(dt:Double, phaseCount:Int=3, motorCurrent:Double=0, motorTemperatureC:Double=25) {
        if phaseCount < 3 { fault = .inputPhaseLoss }
        let targetBus = inputLineRMS*sqrt(2)*0.97
        dcBusVolts += (targetBus-dcBusVolts)*min(1,dt*12)
        if dcBusVolts < 400 && enabled && dcBusVolts > 0 && dt > 0.05 { fault = .dcBusUndervoltage }
        if motorCurrent > 120 { fault = .overcurrent }
        if motorTemperatureC > 145 { fault = .motorOvertemperature }
        let target = enabled && fault == .none ? min(maxHz,max(0,commandedHz)) : 0
        let delta=max(-accelHzPerSecond*dt,min(accelHzPerSecond*dt,target-outputHz)); outputHz += delta
    }
    public var outputLineRMS:Double { maxHz > 0 ? inputLineRMS*min(1,outputHz/maxHz) : 0 }
}

public enum PLCValue: Sendable, Codable, Equatable { case bool(Bool), real(Double) }
public struct PLCTag: Sendable, Codable, Equatable { public var name:String; public var value:PLCValue; public init(_ name:String,_ value:PLCValue){self.name=name;self.value=value} }
public struct PLCScanRuntime: Sendable, Codable, Equatable {
    public var inputs:[String:PLCValue]=[:]; public var memory:[String:PLCValue]=[:]; public var outputs:[String:PLCValue]=[:]; public var scanCount=0
    public init() {}
    public mutating func scan(start:String, stop:String, overload:String, seal:String, output:String) {
        func b(_ d:[String:PLCValue],_ k:String)->Bool { if case .bool(let x)?=d[k]{return x};return false }
        let run = b(inputs,start) || b(memory,seal); let permissive = !b(inputs,stop) && !b(inputs,overload); let coil=run && permissive
        outputs[output] = .bool(coil); memory[seal] = .bool(coil); scanCount += 1
    }
}

public enum HARTVariable: String, Sendable, Codable { case primaryVariable, loopCurrent, percentRange }
public struct HARTDevice: Sendable, Codable, Equatable {
    public var tag="PT-101", lrv=0.0, urv=1000.0, primaryValue=0.0
    public init() {}
    public var loopMilliamps:Double {4+16*min(1,max(0,(primaryValue-lrv)/max(urv-lrv,1e-12)))}
    public mutating func rerange(lrv:Double,urv:Double)->Bool {guard urv>lrv else{return false};self.lrv=lrv;self.urv=urv;return true}
    public func read(_ variable:HARTVariable)->Double {switch variable{case .primaryVariable:return primaryValue;case .loopCurrent:return loopMilliamps;case .percentRange:return 100*(primaryValue-lrv)/max(urv-lrv,1e-12)}}
}

public struct ShieldedSignalCable: Sendable, Codable, Equatable {
    public var shieldGroundedAtSource=true, shieldGroundedAtDestination=false, commonModeNoiseVolts=0.0, groundPotentialDifferenceVolts=0.0
    public init() {}
    public var inducedErrorMilliamps:Double { let doubleEnded = shieldGroundedAtSource && shieldGroundedAtDestination; let loop = doubleEnded ? abs(groundPotentialDifferenceVolts)*0.06 : 0; let pickup = (!shieldGroundedAtSource && !shieldGroundedAtDestination) ? abs(commonModeNoiseVolts)*0.08 : abs(commonModeNoiseVolts)*0.01; return loop+pickup }
}

public struct IndustrialDriveCell: Sendable {
    public var vfd=VFDState(); public var motor=InductionMotorState(); public var overload=MotorOverloadCurve(settingAmps:12); public var plc=PLCScanRuntime(); public var transmitter=HARTDevice(); public var cable=ShieldedSignalCable()
    public init() {}
    public mutating func step(start:Bool, stop:Bool, overloadTrip:Bool, speedCommandHz:Double, loadFraction:Double, dt:Double)->(hz:Double,rpm:Double,current:Double) {
        plc.inputs["START"] = .bool(start); plc.inputs["STOP"] = .bool(stop); plc.inputs["OL"] = .bool(overloadTrip || overload.tripped); plc.scan(start:"START",stop:"STOP",overload:"OL",seal:"RUN_SEAL",output:"VFD_RUN")
        if case .bool(let run)?=plc.outputs["VFD_RUN"] { vfd.enabled=run }
        vfd.commandedHz=speedCommandHz; motor.frequencyHz=max(0.1,vfd.outputHz)
        let amps = vfd.outputHz > 0 ? motor.step(lineVoltageRMS:vfd.outputLineRMS,loadFraction:loadFraction,dt:dt) : 0
        overload.step(current:amps,dt:dt); vfd.step(dt:dt,motorCurrent:amps,motorTemperatureC:motor.temperatureC)
        return(vfd.outputHz,motor.rotorRPM,amps)
    }
}
