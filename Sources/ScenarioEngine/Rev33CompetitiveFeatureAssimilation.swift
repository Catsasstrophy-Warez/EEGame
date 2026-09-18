import Foundation

// Rev33 — Competitive Feature Assimilation
// Adapts high-value interaction/learning/simulation patterns found across electrician games,
// circuit simulators, PLC trainers, and professional engineering simulators while preserving
// Electric Engineer's one-physical-truth rule. No proprietary UI/assets/content are copied.

public enum EEExperienceMode: String, Codable, Sendable, CaseIterable { case learn, build, work, troubleshoot, sandbox }
public enum EERepresentation: String, Codable, Sendable, CaseIterable { case physical, schematic, functional, signal, logic, process }
public enum EEGuidanceLevel: String, Codable, Sendable, CaseIterable { case observe, guided, assisted, independent, faulted, master }
public enum EEVisionLayer: String, Codable, Sendable, CaseIterable { case energized, voltage, current, voltageDrop, heat, signalQuality, groundReference, logicState }

public struct EESynchronizedIdentity: Codable, Sendable, Hashable {
    public var identity: String
    public var projections: [EERepresentation:String]
    public init(identity:String, projections:[EERepresentation:String]) { self.identity=identity; self.projections=projections }
}

public struct EEElectricalVision: Codable, Sendable {
    public var enabled = false
    public var layers:Set<EEVisionLayer> = []
    public var revealLevel:Int = 0
    public mutating func configure(for guidance:EEGuidanceLevel) {
        switch guidance {
        case .observe: enabled=true; revealLevel=4; layers=Set(EEVisionLayer.allCases)
        case .guided: enabled=true; revealLevel=3; layers=[.energized,.voltage,.current,.heat,.logicState]
        case .assisted: enabled=true; revealLevel=2; layers=[.energized,.voltageDrop,.heat]
        case .independent,.faulted,.master: enabled=false; revealLevel=0; layers=[]
        }
    }
}

public enum EEInstrumentKind: String, Codable, Sendable, CaseIterable {
    case dmm, clampMeter, milliampClamp, insulationTester, loopCalibrator, processCalibrator,
         hartCommunicator, pressureCalibrator, temperatureSimulator, oscilloscope, thermalCamera,
         vibrationAnalyzer, tachometer, phaseRotationMeter, networkAnalyzer, canAnalyzer
}
public struct EEInstrumentSpec: Codable, Sendable, Hashable {
    public var kind:EEInstrumentKind; public var inputImpedanceOhm:Double?; public var burdenVoltage:Double?; public var fusedCurrentJack:Bool; public var physicsNote:String
    public init(_ kind:EEInstrumentKind,inputImpedanceOhm:Double?=nil,burdenVoltage:Double?=nil,fusedCurrentJack:Bool=false,physicsNote:String){self.kind=kind;self.inputImpedanceOhm=inputImpedanceOhm;self.burdenVoltage=burdenVoltage;self.fusedCurrentJack=fusedCurrentJack;self.physicsNote=physicsNote}
}
public struct EEInstrumentLocker: Codable, Sendable {
    public init() {}
    public var instruments:[EEInstrumentSpec] = [
        .init(.dmm,inputImpedanceOhm:10_000_000,fusedCurrentJack:true,physicsNote:"Meter loading, jack/mode, lead and fuse state participate in measurement"),
        .init(.clampMeter,physicsNote:"Non-contact current measurement with range/accuracy limits"),
        .init(.milliampClamp,physicsNote:"Low-current loop observation without opening conductor"),
        .init(.insulationTester,physicsNote:"Applies modeled test potential; requires safe isolated topology"),
        .init(.loopCalibrator,burdenVoltage:0.25,physicsNote:"Source/measure/simulate are distinct circuit roles"),
        .init(.processCalibrator,physicsNote:"Electrical plus process-reference stimulus"),
        .init(.hartCommunicator,physicsNote:"Digital communication rides on compatible analog loop"),
        .init(.pressureCalibrator,physicsNote:"Applies traceable process pressure reference"),
        .init(.temperatureSimulator,physicsNote:"Simulates sensor/electrical temperature reference"),
        .init(.oscilloscope,inputImpedanceOhm:1_000_000,physicsNote:"Waveform, trigger, timebase and probe loading"),
        .init(.thermalCamera,physicsNote:"Observes temperature field rather than electrical state directly"),
        .init(.vibrationAnalyzer,physicsNote:"Observes vibration spectrum/order features"),
        .init(.tachometer,physicsNote:"Observes rotational speed"),
        .init(.phaseRotationMeter,physicsNote:"Observes three-phase sequence"),
        .init(.networkAnalyzer,physicsNote:"Observes industrial-network link/protocol evidence"),
        .init(.canAnalyzer,physicsNote:"Observes timestamped CAN frames and decoded signals")
    ]
}

public struct EEDemonstrationStep: Codable, Sendable, Hashable { public var sequence:Int; public var action:String; public var identity:String; public var rationale:String; public init(sequence:Int,action:String,identity:String,rationale:String){self.sequence=sequence;self.action=action;self.identity=identity;self.rationale=rationale} }
public struct EEDemonstration: Codable, Sendable {
    public var id:String; public var title:String; public var steps:[EEDemonstrationStep]; public var cursor=0
    public init(id:String,title:String,steps:[EEDemonstrationStep]){self.id=id;self.title=title;self.steps=steps}
    public mutating func advance()->EEDemonstrationStep? { guard cursor < steps.count else{return nil}; defer{cursor += 1}; return steps[cursor] }
    public mutating func rewind(){cursor=0}
}

public enum EEMotorLesson: String, Codable, Sendable, CaseIterable {
    case directLamp, relayControl, threeWireControl, sealIn, overload, jog, hoa, forwardReverse,
         electricalInterlock, mechanicalInterlock, multipleStations, limitSwitches, timers,
         sequenceControl, starDelta, twoSpeed, contactorDiagnostics, singlePhasing,
         overloadDiagnostics, controlTransformer, mccBucket, softStarter, vfd,
         plcControlledStarter, networkedDrive, processIntegratedMotor
}
public struct EEMotorAcademy: Codable, Sendable { public var completed:Set<EEMotorLesson>=[]; public var unlocked:EEMotorLesson { EEMotorLesson.allCases[min(completed.count,EEMotorLesson.allCases.count-1)] } }

public enum EEDocumentKind: String, Codable, Sendable, CaseIterable { case pid, singleLine, elementary, loopSheet, wiringDiagram, terminalPlan, ioList, datasheet, installationGuide, commissioningSheet, deviceManual, plcProgram, alarmList, causeEffect, historian, soe, maintenanceHistory, workOrders }
public struct EETechnicalDocument: Codable, Sendable, Hashable { public var id:String; public var kind:EEDocumentKind; public var title:String; public var identities:Set<String>; public var revision:String }
public struct EETechnicalLibrary: Codable, Sendable {
    public var documents:[EETechnicalDocument]=[]
    public func related(to identity:String)->[EETechnicalDocument] { documents.filter{$0.identities.contains(identity)} }
}

public enum EEObservationKind: String, Codable, Sendable { case visual, measurement, alarm, event, historian, plc, hart, network, thermal, operatorStatement, maintenance, construction }
public struct EEDiagnosticObservation: Codable, Sendable, Hashable { public var id:String; public var kind:EEObservationKind; public var identity:String; public var statement:String; public var supports:Set<String>; public var contradicts:Set<String>; public init(id:String,kind:EEObservationKind,identity:String,statement:String,supports:Set<String>,contradicts:Set<String>){self.id=id;self.kind=kind;self.identity=identity;self.statement=statement;self.supports=supports;self.contradicts=contradicts} }
public struct EEHypothesis: Codable, Sendable, Hashable { public var id:String; public var title:String; public var weight:Double; public var evidence:Set<String>=[]; public init(id:String,title:String,weight:Double){self.id=id;self.title=title;self.weight=weight} }
public struct EEEvidenceEngine: Codable, Sendable {
    public var hypotheses:[EEHypothesis]
    public init(hypotheses:[EEHypothesis]){self.hypotheses=hypotheses}
    public var observations:[EEDiagnosticObservation]=[]
    public mutating func ingest(_ observation:EEDiagnosticObservation) {
        observations.append(observation)
        for i in hypotheses.indices {
            if observation.supports.contains(hypotheses[i].id) { hypotheses[i].weight *= 1.8; hypotheses[i].evidence.insert(observation.id) }
            if observation.contradicts.contains(hypotheses[i].id) { hypotheses[i].weight *= 0.25; hypotheses[i].evidence.insert(observation.id) }
        }
        normalize()
    }
    public mutating func normalize(){let s=hypotheses.reduce(0){$0+$1.weight}; guard s>0 else{return}; for i in hypotheses.indices{hypotheses[i].weight/=s}}
    public var ranked:[EEHypothesis]{hypotheses.sorted{$0.weight>$1.weight}}
}

public struct EEIntermittentConnection: Codable, Sendable, Hashable {
    public var baseResistanceOhm:Double; public var oxidation:Double; public var contactPressure:Double; public var vibrationSensitivity:Double; public var moistureSensitivity:Double; public var temperatureCoefficient:Double
    public init(baseResistanceOhm:Double,oxidation:Double,contactPressure:Double,vibrationSensitivity:Double,moistureSensitivity:Double,temperatureCoefficient:Double){self.baseResistanceOhm=baseResistanceOhm;self.oxidation=oxidation;self.contactPressure=contactPressure;self.vibrationSensitivity=vibrationSensitivity;self.moistureSensitivity=moistureSensitivity;self.temperatureCoefficient=temperatureCoefficient}
    public func resistance(tempC:Double,vibration:Double,moisture:Double)->Double {
        let thermal=max(0,tempC-20)*temperatureCoefficient
        let env=vibration*vibrationSensitivity + moisture*moistureSensitivity
        let pressurePenalty=max(0,1-contactPressure)*0.5
        return max(0,baseResistanceOhm + oxidation*0.25 + thermal + env + pressurePenalty)
    }
}

public struct EECommissioningGate: Codable, Sendable, Hashable { public var id:String; public var title:String; public var passed:Bool; public var evidenceIDs:[String]; public init(id:String,title:String,passed:Bool,evidenceIDs:[String]){self.id=id;self.title=title;self.passed=passed;self.evidenceIDs=evidenceIDs} }
public struct EEProofOfRepair: Codable, Sendable {
    public var symptomCleared=false; public var rootCauseCorrected=false; public var gates:[EECommissioningGate]=[]
    public init(symptomCleared:Bool=false,rootCauseCorrected:Bool=false,gates:[EECommissioningGate]=[]){self.symptomCleared=symptomCleared;self.rootCauseCorrected=rootCauseCorrected;self.gates=gates}
    public var readyToClose:Bool { symptomCleared && rootCauseCorrected && !gates.isEmpty && gates.allSatisfy{$0.passed && !$0.evidenceIDs.isEmpty} }
}

public struct EEHierarchyNode: Codable, Sendable, Hashable { public var id:String; public var title:String; public var children:[EEHierarchyNode]; public init(id:String,title:String,children:[EEHierarchyNode]){self.id=id;self.title=title;self.children=children} }
public struct EEHierarchyExplorer: Codable, Sendable { public var roots:[EEHierarchyNode]; public init(roots:[EEHierarchyNode]){self.roots=roots}; public func find(_ id:String)->EEHierarchyNode? { func walk(_ n:EEHierarchyNode)->EEHierarchyNode?{if n.id==id{return n}; for c in n.children{if let x=walk(c){return x}}; return nil}; for r in roots{if let x=walk(r){return x}}; return nil } }

public enum EECompetitorPattern: String, Codable, Sendable, CaseIterable {
    case jobCareerLoop, embodiedManipulation, expertPlayback, simplifiedRelaySchematic,
         visibleElectricity, immediateCausality, virtualInstruments, threeDWorkbench,
         professionalCircuitAnalysis, multidisciplinarySimulation, plantScenes,
         realisticPLCProgramming, hierarchicalDigitalLogic, progressiveConstruction,
         documentationAsGameplay, canNetworkSimulation
}
public struct EEAdaptation: Codable, Sendable, Hashable { public var pattern:EECompetitorPattern; public var sourceClass:String; public var adaptation:String; public var nativeAdvantage:String }
public struct EECompetitiveFeatureMatrix: Codable, Sendable {
    public init() {}
    public var adaptations:[EEAdaptation] = [
        .init(pattern:.jobCareerLoop,sourceClass:"Electrician job games",adaptation:"Work orders, travel, tools/parts, repair, proof and career progression",nativeAdvantage:"Industrial process and persistent equipment biography"),
        .init(pattern:.embodiedManipulation,sourceClass:"VR electrician games",adaptation:"Probe, rotate, pull, torque, strip, crimp, land and connect at the object",nativeAdvantage:"Touch-first iPhone/iPad plus shared simulation truth"),
        .init(pattern:.expertPlayback,sourceClass:"Wiring trainers",adaptation:"Observe → guided → assisted → independent → faulted → master",nativeAdvantage:"Same authored assembly can become lesson, commissioning and fault case"),
        .init(pattern:.simplifiedRelaySchematic,sourceClass:"Relay/control trainers",adaptation:"Synchronized physical/schematic/functional/signal/logic/process projections",nativeAdvantage:"One identity highlights everywhere"),
        .init(pattern:.visibleElectricity,sourceClass:"Interactive circuit simulators",adaptation:"Optional Electrical Vision layers",nativeAdvantage:"Industrial 3D cabinet and field context"),
        .init(pattern:.immediateCausality,sourceClass:"Real-time circuit simulators",adaptation:"Every manipulation propagates through electrical, mechanical, process and automation state",nativeAdvantage:"No scripted alarm shortcuts"),
        .init(pattern:.virtualInstruments,sourceClass:"3D circuit labs",adaptation:"Instrument Locker with tool-specific measurement physics",nativeAdvantage:"Evidence ledger and physical test points"),
        .init(pattern:.threeDWorkbench,sourceClass:"3D electronics workbenches",adaptation:"Electronics, PLC, VFD, motor, loop, network and CAN benches",nativeAdvantage:"Bench learning transfers into same career world"),
        .init(pattern:.professionalCircuitAnalysis,sourceClass:"SPICE/EDA education",adaptation:"Reference solver plus transient/AC/sweep/tolerance analysis roadmap",nativeAdvantage:"Engineering analysis separated from real-time gameplay"),
        .init(pattern:.multidisciplinarySimulation,sourceClass:"Automation engineering suites",adaptation:"Electrical + logic + pneumatic + hydraulic + mechanical + thermal + process coupling",nativeAdvantage:"Game progression and forensic maintenance history"),
        .init(pattern:.plantScenes,sourceClass:"PLC factory simulators",adaptation:"Reusable industrial scenes and instructor fault authoring",nativeAdvantage:"Faults arise from component physics, not only tag overrides"),
        .init(pattern:.realisticPLCProgramming,sourceClass:"PLC trainers",adaptation:"Ladder/tag addressing, online values, cross-reference and trace-to-field",nativeAdvantage:"PLC identity resolves to actual conductor/process source"),
        .init(pattern:.hierarchicalDigitalLogic,sourceClass:"Digital logic simulators",adaptation:"Nested components, reusable functional blocks, timing/testbench concepts",nativeAdvantage:"Hierarchy continues from plant to semiconductor"),
        .init(pattern:.progressiveConstruction,sourceClass:"Computer-building puzzle games",adaptation:"Foundations progressively compose into full industrial facilities",nativeAdvantage:"Physical electrical consequences remain active at every level"),
        .init(pattern:.documentationAsGameplay,sourceClass:"Engineering puzzle games",adaptation:"Manuals, drawings, SOE, historian and prior work orders are evidence sources",nativeAdvantage:"Documents are projections of live plant identities"),
        .init(pattern:.canNetworkSimulation,sourceClass:"Embedded/CAN simulators",adaptation:"CAN-H/L, DBC, frames, diagnostics and physical bus faults",nativeAdvantage:"Vehicle/facility network faults join the same evidence engine")
    ]
}

public struct Rev33ExperienceRuntime: Codable, Sendable {
    public var mode:EEExperienceMode = .troubleshoot
    public var guidance:EEGuidanceLevel = .guided
    public var representation:EERepresentation = .physical
    public var selectedIdentity="PIT401_SIGNAL"
    public var vision=EEElectricalVision()
    public var locker=EEInstrumentLocker()
    public var motorAcademy=EEMotorAcademy()
    public var library=EETechnicalLibrary(documents:[
        .init(id:"LS-PIT401",kind:.loopSheet,title:"PIT-401 Loop Sheet",identities:["PIT401_SIGNAL","PIT-401","DISC-401","MX5-AI3"],revision:"A"),
        .init(id:"TP-UCP02",kind:.terminalPlan,title:"UCP-02 Terminal Plan",identities:["PIT401_SIGNAL","TB1:12","DISC-401"],revision:"B"),
        .init(id:"IO-UCP02",kind:.ioList,title:"UCP-02 I/O List",identities:["PIT401_SIGNAL","MX5-AI3","PIT401_PV"],revision:"C")
    ])
    public var featureMatrix=EECompetitiveFeatureMatrix()
    public var sync=EESynchronizedIdentity(identity:"PIT401_SIGNAL",projections:[.physical:"TB1:12 / DISC-401",.schematic:"401+",.functional:"Pressure indication",.signal:"4–20 mA",.logic:"PIT401_PV",.process:"Separator discharge pressure"])
    public init(){vision.configure(for:guidance)}
    public mutating func setGuidance(_ value:EEGuidanceLevel){guidance=value;vision.configure(for:value)}
    public mutating func select(_ identity:String){selectedIdentity=identity}
}
