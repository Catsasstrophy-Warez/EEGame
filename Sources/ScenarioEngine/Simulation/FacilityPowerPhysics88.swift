import Foundation
import ElectricalCore
import CircuitMNA

// Rev88: Facility Power Physics.
// Complex three-phase source, sequence/fault analysis, conductor thermal truth,
// motor negative-sequence heating, control-power sag and shared measurement frame.

public struct EEComplex88: Codable, Equatable, Sendable {
    public var re: Double
    public var im: Double
    public init(_ re: Double = 0, _ im: Double = 0) { self.re = re; self.im = im }
    public static func + (l: Self, r: Self) -> Self { .init(l.re+r.re,l.im+r.im) }
    public static func - (l: Self, r: Self) -> Self { .init(l.re-r.re,l.im-r.im) }
    public static func * (l: Self, r: Self) -> Self { .init(l.re*r.re-l.im*r.im,l.re*r.im+l.im*r.re) }
    public static func * (l: Self, r: Double) -> Self { .init(l.re*r,l.im*r) }
    public static func / (l: Self, r: Self) -> Self {
        let d=max(r.re*r.re+r.im*r.im,1e-18)
        return .init((l.re*r.re+l.im*r.im)/d,(l.im*r.re-l.re*r.im)/d)
    }
    public var magnitude: Double { hypot(re,im) }
    public var angleRadians: Double { atan2(im,re) }
    public static func polar(_ magnitude: Double,_ angle: Double)->Self { .init(magnitude*cos(angle),magnitude*sin(angle)) }
}

public struct EEPhasor3_88: Codable, Equatable, Sendable {
    public var a: EEComplex88; public var b: EEComplex88; public var c: EEComplex88
    public init(_ a: EEComplex88 = .init(), _ b: EEComplex88 = .init(), _ c: EEComplex88 = .init()){self.a=a;self.b=b;self.c=c}
    public var magnitudes: EEPhaseVector87 { .init(a.magnitude,b.magnitude,c.magnitude) }
}

public struct EESequence88: Codable, Equatable, Sendable {
    public var zero:EEComplex88; public var positive:EEComplex88; public var negative:EEComplex88
    public static func from(_ p:EEPhasor3_88)->Self {
        let alpha=EEComplex88.polar(1,2*Double.pi/3), alpha2=alpha*alpha
        return .init(zero:(p.a+p.b+p.c)*EEComplex88(1.0/3,0),
                     positive:(p.a + alpha*p.b + alpha2*p.c)*EEComplex88(1.0/3,0),
                     negative:(p.a + alpha2*p.b + alpha*p.c)*EEComplex88(1.0/3,0))
    }
}

public enum EEFaultKind88:String,Codable,CaseIterable,Sendable { case none, singleLineGround, lineLine, doubleLineGround, threePhase, openPhase, reversedSequence }

public struct EETransformer88:Codable,Equatable,Sendable {
    public var primaryLLV=12470.0; public var secondaryLLV=480.0; public var kva=150.0
    public var resistancePU=0.012; public var reactancePU=0.048; public var groundingOhm=0.08
    public init(){}
    public var ratio:Double { primaryLLV/max(secondaryLLV,1e-9) }
    public var baseZ:Double { secondaryLLV*secondaryLLV/max(kva*1000,1) }
    public var z1:EEComplex88 { .init(resistancePU*baseZ,reactancePU*baseZ) }
    public var z2:EEComplex88 { z1 }
    public var z0:EEComplex88 { .init(z1.re+3*groundingOhm,z1.im) }
}

public struct EEConductorThermal88:Codable,Equatable,Sendable {
    public var resistance20Ohm=0.035; public var alpha=0.00393; public var temperatureC=25.0
    public var ambientC=25.0; public var thermalMassJPerC=650.0; public var coolingWPerC=2.8
    public var insulationLimitC=90.0; public var damage01=0.0
    public init(){}
    public var resistanceOhm:Double { resistance20Ohm*(1+alpha*(temperatureC-20)) }
    public mutating func integrate(currentA:Double,dt:Double) {
        let heat=currentA*currentA*resistanceOhm
        temperatureC += (heat-(temperatureC-ambientC)*coolingWPerC)/max(thermalMassJPerC,1)*dt
        if temperatureC>insulationLimitC { damage01=min(1,damage01+dt*(temperatureC-insulationLimitC)/7200) }
    }
}

public struct EEFaultResult88:Codable,Equatable,Sendable {
    public var ia=EEComplex88(); public var ib=EEComplex88(); public var ic=EEComplex88()
    public var groundCurrentA=0.0; public var negativeSequenceA=0.0
}

public enum EEFaultSolver88 {
    public static func solve(kind:EEFaultKind88,phaseV:Double,z1:EEComplex88,z2:EEComplex88,z0:EEComplex88,faultOhm:Double=0.02)->EEFaultResult88 {
        let zf=EEComplex88(faultOhm,0), a=EEComplex88.polar(1,2*Double.pi/3), a2=a*a
        let e=EEComplex88(phaseV,0)
        switch kind {
        case .none: return .init()
        case .singleLineGround:
            let i=e*EEComplex88(3,0)/(z1+z2+z0+zf*3)
            return .init(ia:i,ib:.init(),ic:.init(),groundCurrentA:i.magnitude,negativeSequenceA:i.magnitude/3)
        case .lineLine:
            let i1=e/(z1+z2+zf); let ib=(a2-a)*i1; return .init(ia:.init(),ib:ib,ic:ib*EEComplex88(-1,0),negativeSequenceA:i1.magnitude)
        case .doubleLineGround:
            let parallel=(z2*(z0+zf*3))/(z2+z0+zf*3); let i1=e/(z1+parallel)
            let i2=i1*EEComplex88(-1,0)*(z0+zf*3)/(z2+z0+zf*3)
            let i0=i1*EEComplex88(-1,0)*z2/(z2+z0+zf*3)
            let ia=i0+i1+i2, ib=i0+a2*i1+a*i2, ic=i0+a*i1+a2*i2
            return .init(ia:ia,ib:ib,ic:ic,groundCurrentA:(i0*3).magnitude,negativeSequenceA:i2.magnitude)
        case .threePhase:
            let i=e/(z1+zf); return .init(ia:i,ib:a2*i,ic:a*i,negativeSequenceA:0)
        case .openPhase: return .init()
        case .reversedSequence: return .init()
        }
    }
}

public struct EEFacilityMeasurementFrame88:Codable,Equatable,Sendable {
    public var time=0.0; public var phaseVoltage=EEPhasor3_88(); public var phaseCurrent=EEPhasor3_88()
    public var neutralCurrentA=0.0; public var groundCurrentA=0.0; public var conductorTemperatureC=25.0
    public var motorTemperatureC=25.0; public var controlVoltageV=120.0; public var analogMA=4.0
    public var plcInputV=0.0; public var protectionConducting=true; public var fault:EEFaultKind88 = .none
    public init(){}
    public init(time: Double = 0.0, phaseVoltage: EEPhasor3_88 = .init(), phaseCurrent: EEPhasor3_88 = .init(),
                neutralCurrentA: Double = 0.0, groundCurrentA: Double = 0.0, conductorTemperatureC: Double = 25.0,
                motorTemperatureC: Double = 25.0, controlVoltageV: Double = 120.0, analogMA: Double = 4.0,
                plcInputV: Double = 0.0, protectionConducting: Bool = true, fault: EEFaultKind88 = .none) {
        self.time = time; self.phaseVoltage = phaseVoltage; self.phaseCurrent = phaseCurrent
        self.neutralCurrentA = neutralCurrentA; self.groundCurrentA = groundCurrentA; self.conductorTemperatureC = conductorTemperatureC
        self.motorTemperatureC = motorTemperatureC; self.controlVoltageV = controlVoltageV; self.analogMA = analogMA
        self.plcInputV = plcInputV; self.protectionConducting = protectionConducting; self.fault = fault
    }
    public func voltageMagnitude(_ phase:Int)->Double { [phaseVoltage.a.magnitude,phaseVoltage.b.magnitude,phaseVoltage.c.magnitude][max(0,min(2,phase))] }
    public func clampCurrent(_ phase:Int)->Double { [phaseCurrent.a.magnitude,phaseCurrent.b.magnitude,phaseCurrent.c.magnitude][max(0,min(2,phase))] }
}

public struct EEFacilityPowerState88:Codable,Equatable,Sendable {
    public var time=0.0; public var transformer=EETransformer88()
    public var feederA=EEConductorThermal88(); public var feederB=EEConductorThermal88(); public var feederC=EEConductorThermal88()
    public var motor=EEInductionMotor87(); public var protection=EEProtectionState87(); public var contact=EEContactWear87()
    public var analog=EEAnalogLoopTopology87(); public var plc=EEPLCInputElectronics87()
    public var fault:EEFaultKind88 = .none; public var faultResistanceOhm=0.02
    public var controlTransformerVA=500.0; public var controlLoadVA=120.0; public var controlVoltageV=120.0
    public var frame=EEFacilityMeasurementFrame88(); public var scope=EETransientRing87(); public var soe:[EESOEEvent86]=[]
    public init(){}
}

public enum EEFacilityPowerMachine88 {
    public static func step(_ s:inout EEFacilityPowerState88,dt requested:Double) {
        let dt=min(0.001,max(0.00005,requested)), phaseV=s.transformer.secondaryLLV/sqrt(3)
        let va=EEComplex88.polar(phaseV,0), vb=EEComplex88.polar(phaseV,-2*Double.pi/3), vc=EEComplex88.polar(phaseV,2*Double.pi/3)
        let f=EEFaultSolver88.solve(kind:s.fault,phaseV:phaseV,z1:s.transformer.z1,z2:s.transformer.z2,z0:s.transformer.z0,faultOhm:s.faultResistanceOhm)
        var load=EEPhasor3_88(EEComplex88(s.motor.current.a,0),EEComplex88.polar(s.motor.current.b,-2*Double.pi/3),EEComplex88.polar(s.motor.current.c,2*Double.pi/3))
        if s.fault != .none { load = .init(load.a+f.ia,load.b+f.ib,load.c+f.ic) }
        if s.fault == .openPhase { load.a = .init() }
        if s.fault == .reversedSequence { let t=load.b; load.b=load.c; load.c=t }
        let za=EEComplex88(s.feederA.resistanceOhm,0)+s.transformer.z1
        let zb=EEComplex88(s.feederB.resistanceOhm,0)+s.transformer.z1
        let zc=EEComplex88(s.feederC.resistanceOhm,0)+s.transformer.z1
        let terminal=EEPhasor3_88(va-load.a*za,vb-load.b*zb,vc-load.c*zc)
        let mags=terminal.magnitudes
        s.motor.integrate(phaseVoltage:mags,energized:s.protection.conducting,dt:dt)
        let seq=EESequence88.from(load)
        let negHeat=pow(seq.negative.magnitude,2)*s.motor.statorR*3
        s.motor.windingTemperatureC += negHeat/220*dt
        s.feederA.integrate(currentA:load.a.magnitude,dt:dt); s.feederB.integrate(currentA:load.b.magnitude,dt:dt); s.feederC.integrate(currentA:load.c.magnitude,dt:dt)
        let maxI=max(load.a.magnitude,max(load.b.magnitude,load.c.magnitude)); s.protection.integrate(currentA:maxI,dt:dt)
        let loadFraction=min(2,s.controlLoadVA/max(s.controlTransformerVA,1)); s.controlVoltageV=max(0,120*(1-0.055*loadFraction)-0.018*maxI)
        s.plc.sample(fieldV:min(24,s.controlVoltageV/5),dt:dt); s.analog.supplyV=min(24,s.controlVoltageV/5); s.analog.solve()
        s.time += dt
        s.frame = .init(time:s.time,phaseVoltage:terminal,phaseCurrent:load,neutralCurrentA:(load.a+load.b+load.c).magnitude,
                        groundCurrentA:f.groundCurrentA,conductorTemperatureC:max(s.feederA.temperatureC,max(s.feederB.temperatureC,s.feederC.temperatureC)),
                        motorTemperatureC:s.motor.windingTemperatureC,controlVoltageV:s.controlVoltageV,analogMA:s.analog.currentMA,
                        plcInputV:s.plc.terminalV,protectionConducting:s.protection.conducting,fault:s.fault)
        for (ch,v) in [("L1.V",terminal.a.magnitude),("L2.V",terminal.b.magnitude),("L3.V",terminal.c.magnitude),("L1.A",load.a.magnitude),("L2.A",load.b.magnitude),("L3.A",load.c.magnitude),("GND.A",f.groundCurrentA),("CTRL.V",s.controlVoltageV)] { s.scope.append(.init(time:s.time,channel:ch,value:v)) }
    }
}
