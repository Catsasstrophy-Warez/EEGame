import Foundation
import ElectricalCore
import CircuitMNA

public struct TerminationState: Sendable, Codable, Equatable {
    public init() {}
    public var baseResistanceOhms:Double=0.002; public var looseness:Double=0; public var oxidation:Double=0; public var temperatureC:Double=25
    public var resistanceOhms:Double { let damage = 1.0 + 40.0*looseness + 25.0*oxidation; let thermal = 1.0 + 0.0039*(temperatureC-25.0); return baseResistanceOhms * damage * thermal }
    public mutating func step(current:Double,dt:Double){ let watts=current*current*resistanceOhms; let heating=watts*dt/18.0; let cooling=(temperatureC-25.0)*0.025*dt; temperatureC += heating-cooling; let growth=max(0.0,temperatureC-70.0)*1e-7*dt; oxidation=min(1.0,oxidation+growth) }
}

public struct ContactState: Sendable, Codable, Equatable {
    public init() {}
    public var closed=false; public var erosion=0.0; public var welded=false; public var bounceRemaining=0.0
    public var resistanceOhms:Double { closed || welded ? 0.015*(1+20*erosion) : 1e12 }
    public mutating func command(_ close:Bool){ if welded { closed=true; return }; if close != closed { bounceRemaining=0.008 }; closed=close }
    public mutating func step(current:Double,dt:Double){ bounceRemaining=max(0,bounceRemaining-dt); if closed { erosion=min(1,erosion + current*current*dt*1e-8); if erosion > 0.98 && abs(current)>20 { welded=true } } }
}

public struct PhysicalDCMotor: Sendable, Codable, Equatable {
    public init() {}
    public var resistance=0.45, inductance=0.008, torqueConstant=0.08, backEMFConstant=0.08, inertia=0.012, current=0.0, omega=0.0, temperatureC=25.0
    public mutating func step(voltage:Double,loadTorque:Double,dt:Double){ let emf=backEMFConstant*omega; current += ((voltage-emf-resistance*current)/max(inductance,1e-9))*dt; let torque=torqueConstant*current; omega=max(0,omega + ((torque-loadTorque)/max(inertia,1e-9))*dt); temperatureC += ((current*current*resistance)/45 - (temperatureC-25)*0.02)*dt }
}

public enum AssistanceLevel:String,CaseIterable,Sendable,Codable { case guided, apprentice, technician, master, sandbox }
public struct DiagnosticEvidence: Sendable, Equatable { public var measurement:String; public var value:Double; public var unit:String; public var sourceTerminal:String }
public struct RootCauseAssessment: Sendable, Equatable { public var symptomCorrected:Bool; public var rootCauseCorrected:Bool }

public struct FailureLifecycle: Sendable, Codable, Equatable {
    public init() {}
    public var looseness=0.0, insulationHealth=1.0, leakageSiemens=0.0
    public mutating func step(temperatureC:Double,vibration:Double,dt:Double){ looseness=min(1,looseness+max(0,vibration)*1e-6*dt); insulationHealth=max(0,insulationHealth-max(0,temperatureC-80)*2e-7*dt); leakageSiemens=(1-insulationHealth)*1e-4 }
}

public struct ConductorTruth: Sendable, Codable, Equatable {
    public var lengthMeters:Double=1; public var areaMM2:Double=2.08; public var resistivityOhmMeter:Double=1.724e-8; public var insulationHealth:Double=1; public var thermal=ThermalState(thermalMassJPerC:30,coolingWPerC:0.25)
    public init() {}
    public var resistanceOhms:Double { let area=max(areaMM2,1e-6)*1e-6; let base=resistivityOhmMeter*max(lengthMeters,0)/area; return max(1e-9,base*(1+0.00393*(thermal.temperatureC-20))) }
    public mutating func step(current:Double,dt:Double){ thermal.step(powerWatts:current*current*resistanceOhms,dt:dt); if thermal.temperatureC > 90 { insulationHealth=max(0,insulationHealth-(thermal.temperatureC-90)*1e-7*dt) } }
}
public struct RootCauseLedger: Sendable, Equatable {
    public var evidence:[DiagnosticEvidence]=[]; public var partsReplaced:[String]=[]; public var causalFaults:Set<String>=[]; public var correctedFaults:Set<String>=[]
    public init() {}
    public var assessment:RootCauseAssessment { .init(symptomCorrected:!correctedFaults.isEmpty,rootCauseCorrected:causalFaults.isSubset(of:correctedFaults)) }
}

public struct SinglePhaseACSource: Sendable, Codable, Equatable { public var rmsVolts:Double; public var frequencyHz:Double; public var phaseRadians:Double=0; public init(rmsVolts:Double=120,frequencyHz:Double=60){self.rmsVolts=rmsVolts;self.frequencyHz=frequencyHz}; public func instantaneous(at t:Double)->Double { sqrt(2)*rmsVolts*sin(2*Double.pi*frequencyHz*t+phaseRadians) } }
public struct ThreePhaseSource: Sendable, Codable, Equatable { public var lineLineRMS:Double; public var frequencyHz:Double; public init(lineLineRMS:Double=480,frequencyHz:Double=60){self.lineLineRMS=lineLineRMS;self.frequencyHz=frequencyHz}; public var lineNeutralRMS:Double { lineLineRMS/sqrt(3) }; public func phaseVoltages(at t:Double)->(Double,Double,Double){let p=sqrt(2)*lineNeutralRMS;let w=2*Double.pi*frequencyHz*t;return(p*sin(w),p*sin(w-2*Double.pi/3),p*sin(w+2*Double.pi/3))} }
public struct AnalogLoop420mA: Sendable, Codable, Equatable { public var lrv:Double=0, urv:Double=100, processValue:Double=0, loopSupply:Double=24, burdenOhms:Double=250; public init(){}; public var commandedMilliamps:Double { let f=min(1,max(0,(processValue-lrv)/max(urv-lrv,1e-12))); return 4+16*f }; public var burdenVolts:Double { commandedMilliamps/1000*burdenOhms }; public var hasCompliance:Bool { loopSupply > burdenVolts + 10 } }
