import Foundation
import ElectricalCore
import CircuitMNA

// Rev16: safety-aware diagnostics, isolation-dependent measurements, welded-contact truth,
// electro-pneumatic coupling, and evidence-based training assessment.

public enum SafetyViolationKind: String, Sendable, Codable, Equatable {
    case workWithoutIsolation, absenceOfVoltageNotVerified, resistanceOnEnergizedCircuit, unsafeReenergization
}
public struct SafetyViolation: Sendable, Codable, Equatable {
    public var time: Double; public var kind: SafetyViolationKind; public var detail: String
    public init(time:Double,kind:SafetyViolationKind,detail:String){self.time=time;self.kind=kind;self.detail=detail}
}
public struct SafetyAuditLog: Sendable, Codable, Equatable {
    public var violations:[SafetyViolation]=[]; public init(){}
    public mutating func record(_ kind:SafetyViolationKind,time:Double,detail:String){violations.append(.init(time:time,kind:kind,detail:detail))}
    public var clean:Bool { violations.isEmpty }
}

public enum IsolationPoint: String, Sendable, Codable, Equatable { case contactorLine, contactorLoad, motorLeads }
public struct ThreePoleContactorTruth: Sendable, Codable, Equatable {
    public var coilEnergized=false
    public var poleResistanceOhms:[Double] = [0.012,0.012,0.012]
    public var welded:[Bool] = [false,false,false]
    public var loadLeadsConnected:[Bool] = [true,true,true]
    public init(){}
    public mutating func command(_ energized:Bool){coilEnergized=energized}
    public func poleClosed(_ index:Int)->Bool { welded[index] || coilEnergized }
    public func resistanceAcrossPole(_ index:Int, isolatedLoad:Bool) -> Double? {
        guard isolatedLoad || !loadLeadsConnected[index] else { return nil } // parallel paths make the diagnostic ambiguous
        return poleClosed(index) ? poleResistanceOhms[index] : nil
    }
}

public struct VoltagePresenceTester: Sendable, Equatable {
    public var thresholdVolts=30.0; public init(){}
    public func absent(_ volts:Double)->Bool { abs(volts) < thresholdVolts }
}
public struct SafeResistanceMeasurement: Sendable, Equatable {
    public var ohms:Double?; public var valid:Bool; public var reason:String?
    public init(ohms:Double?,valid:Bool,reason:String?=nil){self.ohms=ohms;self.valid=valid;self.reason=reason}
}

public enum DiagnosticAction: Sendable, Equatable {
    case observeStopFailure
    case openDisconnect
    case applyLockTag
    case verifyAbsenceOfVoltage(volts:Double)
    case liftLoadLead(Int)
    case measurePoleResistance(Int)
    case replaceContactor
    case reconnectLoadLeads
    case removeLockTag
    case reenergize
    case functionalStopTest
}
public enum DiagnosticStage: String, Sendable, Codable, Equatable { case observe, isolate, verifyDead, isolateComponent, test, repair, restore, proveRepair, complete }
public struct DiagnosticResult: Sendable, Equatable { public var accepted:Bool; public var message:String; public var readingOhms:Double?; public init(_ accepted:Bool,_ message:String,_ readingOhms:Double?=nil){self.accepted=accepted;self.message=message;self.readingOhms=readingOhms} }

public struct WeldedContactorDiagnosticScenario: Sendable, Equatable {
    public var stage:DiagnosticStage = .observe
    public var disconnectOpen=false; public var lockApplied=false; public var absenceVerified=false; public var energized=true
    public var contactor=ThreePoleContactorTruth(); public var audit=SafetyAuditLog(); public var time=0.0
    public var diagnosedWeldedPole:Int?; public var componentReplaced=false; public var repairProven=false
    public init(weldedPole:Int=1){ if (0..<3).contains(weldedPole){contactor.welded[weldedPole]=true} }
    public var safeForResistanceTest:Bool { disconnectOpen && lockApplied && absenceVerified && !energized }
    public mutating func perform(_ action:DiagnosticAction)->DiagnosticResult {
        time += 0.1
        switch action {
        case .observeStopFailure: stage = .isolate; return .init(true,"Motor fails to de-energize when commanded off.")
        case .openDisconnect: disconnectOpen=true; energized=false; stage = .isolate; return .init(true,"Disconnect opened.")
        case .applyLockTag: guard disconnectOpen else{return .init(false,"Open the disconnect before applying lock/tag.")};lockApplied=true;return .init(true,"Lock/tag applied.")
        case .verifyAbsenceOfVoltage(let volts):
            guard disconnectOpen && lockApplied else { audit.record(.absenceOfVoltageNotVerified,time:time,detail:"Attempted verification before isolation"); return .init(false,"Isolation and lock/tag required first.") }
            absenceVerified=VoltagePresenceTester().absent(volts); if absenceVerified{stage = .isolateComponent}; return .init(absenceVerified,absenceVerified ? "Absence of voltage verified." : "Voltage is still present.")
        case .liftLoadLead(let pole):
            guard safeForResistanceTest,(0..<3).contains(pole) else { audit.record(.workWithoutIsolation,time:time,detail:"Attempted conductor removal without verified zero energy"); return .init(false,"Verified zero-energy state required.") }
            contactor.loadLeadsConnected[pole]=false; stage = .test; return .init(true,"Load conductor isolated from pole \(pole+1).")
        case .measurePoleResistance(let pole):
            guard safeForResistanceTest else { audit.record(.resistanceOnEnergizedCircuit,time:time,detail:"Resistance mode used without safe isolation"); return .init(false,"Resistance measurement invalid until circuit is isolated and verified dead.") }
            guard (0..<3).contains(pole) else{return .init(false,"Invalid pole.")}
            guard !contactor.loadLeadsConnected[pole] else{return .init(false,"Lift the load lead to remove parallel motor paths.")}
            let r=contactor.resistanceAcrossPole(pole,isolatedLoad:true); if let r, r < 1 { diagnosedWeldedPole=pole; stage = .repair; return .init(true,"Low resistance with coil de-energized indicates a welded pole.",r) }
            return .init(true,"Pole is open with coil de-energized.",r)
        case .replaceContactor:
            guard safeForResistanceTest, diagnosedWeldedPole != nil else{return .init(false,"Establish evidence before replacement.")}
            contactor=ThreePoleContactorTruth(); componentReplaced=true; stage = .restore; return .init(true,"Contactor replaced.")
        case .reconnectLoadLeads: guard componentReplaced else{return .init(false,"Repair not complete.")};contactor.loadLeadsConnected=[true,true,true];return .init(true,"Load conductors reconnected.")
        case .removeLockTag: guard componentReplaced,contactor.loadLeadsConnected.allSatisfy({$0}) else{return .init(false,"Complete repair and reconnect conductors first.")};lockApplied=false;return .init(true,"Lock/tag removed for controlled functional test.")
        case .reenergize: guard disconnectOpen,!lockApplied else { audit.record(.unsafeReenergization,time:time,detail:"Attempted energization while locked or disconnect state invalid");return .init(false,"Cannot energize yet.") };disconnectOpen=false;energized=true;stage = .proveRepair;return .init(true,"Power restored for functional test.")
        case .functionalStopTest:
            guard energized,componentReplaced else{return .init(false,"Restore power after repair before functional test.")};contactor.command(false);repairProven = !(0..<3).contains{contactor.poleClosed($0)};stage = repairProven ? .complete:.proveRepair;return .init(repairProven,repairProven ? "START/STOP behavior verified after repair." : "Fault remains.")
        }
    }
}

public struct DiagnosticCompetencyScore: Sendable, Equatable {
    public var safety:Double; public var evidence:Double; public var efficiency:Double; public var repairQuality:Double
    public var overall:Double {(safety*0.4)+(evidence*0.25)+(efficiency*0.1)+(repairQuality*0.25)}
}
public struct DiagnosticAssessor: Sendable, Equatable {
    public init(){}
    public func score(_ s:WeldedContactorDiagnosticScenario,actionCount:Int)->DiagnosticCompetencyScore {
        let safety=s.audit.clean ? 100.0:max(0,100-25*Double(s.audit.violations.count));let evidence=s.diagnosedWeldedPole == nil ? 30.0:100.0;let efficiency=max(20,100-Double(max(0,actionCount-12))*5);let repair=s.repairProven ? 100.0:(s.componentReplaced ? 60:0);return .init(safety:safety,evidence:evidence,efficiency:efficiency,repairQuality:repair)
    }
}

public struct PneumaticReceiver: Sendable, Codable, Equatable { public var pressurePSI=0.0; public var volumeLiters=100.0; public var leakSCFM=0.0; public init(){}; public mutating func step(compressorSCFM:Double,dt:Double){let net=max(-20,compressorSCFM-leakSCFM);pressurePSI=max(0,pressurePSI + net/max(volumeLiters,1)*dt*5)} }
public struct SolenoidValveTruth: Sendable, Codable, Equatable { public var coilCommand=false;public var coilHealthy=true;public var spoolStuck=false;public var actualOpen=false;public init(){};public mutating func step(){actualOpen = coilCommand && coilHealthy && !spoolStuck} }
public struct PneumaticCylinder: Sendable, Codable, Equatable { public var position=0.0;public var sealLeak=0.0;public var mechanicallyBound=false;public init(){};public mutating func step(pressurePSI:Double,valveOpen:Bool,dt:Double){let target=(valveOpen && pressurePSI>25 && !mechanicallyBound) ? 1.0:0.0;let rate=max(0.05,1-sealLeak)*1.5;position += (target-position)*min(1,dt*rate)};public var extendedLimit:Bool{position>0.95} }
public struct ElectroPneumaticMachine: Sendable {
    public var input=DigitalInputElectricalModel();public var outputCommand=false;public var valve=SolenoidValveTruth();public var receiver=PneumaticReceiver();public var cylinder=PneumaticCylinder();public var compressorRunning=true;public init(){}
    public mutating func step(dt:Double){receiver.step(compressorSCFM:compressorRunning ? 80:0,dt:dt);valve.coilCommand=outputCommand;valve.step();cylinder.step(pressurePSI:receiver.pressurePSI,valveOpen:valve.actualOpen,dt:dt);input.fieldClosed=cylinder.extendedLimit}
}

public enum DiagnosticViolation: String, Sendable, Codable, Equatable { case resistanceOnEnergizedCircuit, conductorLiftedEnergized, reenergizedBeforeRestoration }
public struct DiagnosticContactor: Sendable, Codable, Equatable { public var weldedPoles:Set<Int>=[]; public init(){} }
public struct WeldedContactorDiagnostic: Sendable, Equatable {
    public var contactor=DiagnosticContactor(); public var isolation=EnergyIsolationPlan([.init(id:"MAIN",kind:.utility),.init(id:"CTRL",kind:.controlTransformer),.init(id:"MECH",kind:.storedMechanical)])
    public var locked=false; public var zeroVerified=false; public var loadConductorsLifted=false; public var observed=false; public var replaced=false; public var violations:Set<DiagnosticViolation>=[]
    public init(){}
    public mutating func observeSymptom(){observed=true}
    public mutating func isolateAll(){for i in isolation.sources.indices{isolation.sources[i].isolated=true}}
    public mutating func applyLockAndTag(){locked=true}
    public mutating func verifyZeroEnergy(withTestEquipment:Bool){guard locked,withTestEquipment else{return};for i in isolation.sources.indices{isolation.sources[i].verifiedZeroEnergy=true};zeroVerified=true}
    public mutating func liftLoadConductors(){guard isolation.safeToWork else{violations.insert(.conductorLiftedEnergized);return};loadConductorsLifted=true}
    public mutating func resistanceAcrossPole(_ pole:Int)->Double?{guard isolation.safeToWork else{violations.insert(.resistanceOnEnergizedCircuit);return nil};guard loadConductorsLifted else{return nil};return contactor.weldedPoles.contains(pole) ? 0.005:nil}
    public mutating func replaceContactor(){guard isolation.safeToWork,loadConductorsLifted else{return};contactor.weldedPoles=[];replaced=true}
    public mutating func reenergize(){guard replaced && !loadConductorsLifted else{violations.insert(.reenergizedBeforeRestoration);return};for i in isolation.sources.indices{isolation.sources[i].isolated=false;isolation.sources[i].verifiedZeroEnergy=false};locked=false;zeroVerified=false}
}

public extension ElectroPneumaticMachine {
    var receiverPressureBar:Double { receiver.pressurePSI/14.5037738 }
    var extendedLimit:Bool { cylinder.extendedLimit }
    var solenoidEnergized:Bool { valve.coilCommand && valve.coilHealthy }
    var spoolStuck:Bool { get{valve.spoolStuck} set{valve.spoolStuck=newValue} }
    var airLeakFraction:Double { get{min(1,max(0,receiver.leakSCFM/80))} set{receiver.leakSCFM=min(1,max(0,newValue))*80} }
    mutating func step(motorRunning:Bool,plcSolenoidCommand:Bool,dt:Double){compressorRunning=motorRunning;outputCommand=plcSolenoidCommand;step(dt:dt)}
}
