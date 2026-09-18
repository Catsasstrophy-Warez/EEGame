import Foundation

// Rev34 — Deep Competitive Visualization & Training Systems
// Original implementation inspired by broad product patterns, not copied proprietary UI/content.

public enum EEVisualSurface: String, Codable, Sendable, CaseIterable {
    case electricalVision, representationSwitcher, instrumentLocker, motorAcademy,
         technicalLibrary, evidenceBoard, hierarchyExplorer, instructorStudio,
         electronicsBench, canBench, workOrderJourney, trendLab, cutaway, waveformLab
}

public enum EEVisualizationPrimitive: String, Codable, Sendable, CaseIterable {
    case animatedFlow, numericOverlay, heatMap, waveform, trend, timingDiagram,
         stateColor, crossHighlight, cutawayAnimation, sequenceTimeline, evidenceGraph,
         hierarchyTree, vectorField, packetTimeline, spectrum, processFlow
}

public struct EEVisualBinding: Codable, Sendable, Hashable {
    public var identity:String
    public var surface:EEVisualSurface
    public var primitive:EEVisualizationPrimitive
    public var sourcePath:String
    public var unit:String?
    public var isInteractive:Bool
    public init(identity:String,surface:EEVisualSurface,primitive:EEVisualizationPrimitive,sourcePath:String,unit:String?=nil,isInteractive:Bool=true){self.identity=identity;self.surface=surface;self.primitive=primitive;self.sourcePath=sourcePath;self.unit=unit;self.isInteractive=isInteractive}
}

public struct EEVisualizationRegistry: Codable, Sendable {
    public var bindings:[EEVisualBinding]
    public init(bindings:[EEVisualBinding] = EEVisualizationRegistry.defaults){self.bindings=bindings}
    public func forIdentity(_ id:String)->[EEVisualBinding]{bindings.filter{$0.identity==id}}
    public static let defaults:[EEVisualBinding] = [
        .init(identity:"PIT401_SIGNAL",surface:.electricalVision,primitive:.animatedFlow,sourcePath:"plant.downstreamMA",unit:"mA"),
        .init(identity:"PIT401_SIGNAL",surface:.trendLab,primitive:.trend,sourcePath:"evidence.timeline",unit:"mA"),
        .init(identity:"PIT401_SIGNAL",surface:.waveformLab,primitive:.waveform,sourcePath:"loop.sampleBuffer",unit:"mA"),
        .init(identity:"DISC-401",surface:.evidenceBoard,primitive:.evidenceGraph,sourcePath:"evidence.hypotheses"),
        .init(identity:"TB1:12",surface:.electricalVision,primitive:.heatMap,sourcePath:"termination.temperature",unit:"°C"),
        .init(identity:"DVC-201",surface:.cutaway,primitive:.cutawayAnimation,sourcePath:"dvc.travel",unit:"%"),
        .init(identity:"CAN-BUS-A",surface:.canBench,primitive:.packetTimeline,sourcePath:"can.frames")
    ]
}

public enum EEAnalysisMode: String, Codable, Sendable, CaseIterable {
    case realtime, dcOperatingPoint, transient, acSmallSignal, parameterSweep,
         toleranceStudy, thermalSweep, harmonics, powerQuality, timing, networkTrace
}

public struct EEEngineeringAnalysisProfile: Codable, Sendable, Hashable {
    public var mode:EEAnalysisMode; public var title:String; public var gameplayUse:String; public var advancedUse:String
}

public struct EEAnalysisLab: Codable, Sendable {
    public init() {}
    public var profiles:[EEEngineeringAnalysisProfile] = EEAnalysisMode.allCases.map { mode in
        .init(mode:mode,title:mode.rawValue,gameplayUse:"Visualize cause and effect without leaving the shared machine truth",advancedUse:"Expose engineering-grade evidence appropriate to the selected analysis")
    }
}

public struct EEInstrumentState: Codable, Sendable, Hashable {
    public var kind:EEInstrumentKind
    public var mode:String
    public var range:String
    public var jack:String
    public var leadA:String?
    public var leadB:String?
    public var fuseHealthy:Bool
    public var reading:Double?
    public var unit:String
    public init(kind:EEInstrumentKind,mode:String="AUTO",range:String="AUTO",jack:String="VΩ",leadA:String?=nil,leadB:String?=nil,fuseHealthy:Bool=true,reading:Double?=nil,unit:String=""){self.kind=kind;self.mode=mode;self.range=range;self.jack=jack;self.leadA=leadA;self.leadB=leadB;self.fuseHealthy=fuseHealthy;self.reading=reading;self.unit=unit}
}

public struct EETraceHop: Codable, Sendable, Hashable { public var identity:String; public var representation:EERepresentation; public var label:String }
public struct EETraceToReality: Codable, Sendable {
    public init() {}
    public var routes:[String:[EETraceHop]] = [
        "PIT401_PV":[
            .init(identity:"PIT401_PV",representation:.logic,label:"PLC tag"),
            .init(identity:"MX5-AI3",representation:.signal,label:"Remote analog input"),
            .init(identity:"ISO-17",representation:.physical,label:"Signal isolator"),
            .init(identity:"DISC-401",representation:.physical,label:"Disconnect terminal"),
            .init(identity:"JB-4:12",representation:.physical,label:"Field junction box"),
            .init(identity:"CBL-401",representation:.physical,label:"Field cable"),
            .init(identity:"PIT-401",representation:.physical,label:"Pressure transmitter"),
            .init(identity:"PROCESS-TAP-401",representation:.process,label:"Process tap")
        ]
    ]
    public func trace(_ identity:String)->[EETraceHop]{routes[identity] ?? []}
}

public enum EEWorkOrderPhase: String, Codable, Sendable, CaseIterable {
    case briefing, safetyReview, operatorInterview, documentReview, inspection,
         hypothesis, measurement, isolation, repair, calibration, functionalTest,
         processObservation, proofOfRepair, documentation, closeout
}
public struct EEWorkOrderJourney: Codable, Sendable {
    public init() {}
    public var phase:EEWorkOrderPhase = .briefing
    public var completed:Set<EEWorkOrderPhase> = []
    public mutating func complete(_ p:EEWorkOrderPhase){completed.insert(p); if let i=EEWorkOrderPhase.allCases.firstIndex(of:p), i+1<EEWorkOrderPhase.allCases.count {phase=EEWorkOrderPhase.allCases[i+1]}}
    public var progress:Double{Double(completed.count)/Double(EEWorkOrderPhase.allCases.count)}
}

public struct EEInstructorConstraint: Codable, Sendable, Hashable {
    public var allowedTools:Set<EEInstrumentKind>; public var visibleDocuments:Set<EEDocumentKind>; public var guidance:EEGuidanceLevel; public var faultHidden:Bool
}
public struct EEInstructorStudio: Codable, Sendable {
    public init() {}
    public var constraints=EEInstructorConstraint(allowedTools:Set(EEInstrumentKind.allCases),visibleDocuments:Set(EEDocumentKind.allCases),guidance:.guided,faultHidden:true)
    public var demonstrations:[EEDemonstration]=[]
    public var injectedSimpleOverrides:[String:Bool]=[:]
}

public enum EECANPhysicalFault: String, Codable, Sendable, CaseIterable { case none, openHigh, openLow, shortHighLow, highToPower, lowToGround, missingTermination, excessResistance, intermittentConnector }
public struct EECANFrame: Codable, Sendable, Hashable { public var timestamp:Double; public var id:UInt32; public var dlc:Int; public var bytes:[UInt8]; public var decoded:[String:Double] }
public struct EECANBench: Codable, Sendable {
    public init() {}
    public var fault:EECANPhysicalFault = .none
    public var terminationOhms:Double=60
    public var frames:[EECANFrame]=[]
    public mutating func inject(_ f:EECANPhysicalFault){fault=f; terminationOhms = f == .missingTermination ? 120 : 60}
}

public struct EEDeepCompetitiveFeature: Codable, Sendable, Hashable {
    public var family:String; public var feature:String; public var adaptation:String; public var visualization:String; public var sharedTruthHook:String
}
public struct EEDeepCompetitiveCatalog: Codable, Sendable {
    public init() {}
    public var features:[EEDeepCompetitiveFeature] = [
        .init(family:"Electrician job games",feature:"Jobs, workshop, parts, progression",adaptation:"Industrial shift/work-order/career loop",visualization:"facility map + work-order timeline",sharedTruthHook:"persistent equipment biography"),
        .init(family:"VR electrician interaction",feature:"Direct object manipulation",adaptation:"tap/hold/drag/rotate/probe/torque/crimp",visualization:"3D object affordances + tool contact points",sharedTruthHook:"actions mutate physical component state"),
        .init(family:"Wiring trainers",feature:"Guided playback and point-to-point wiring",adaptation:"observe→guided→assisted→independent→faulted→master",visualization:"ghost conductor + step timeline",sharedTruthHook:"same authored assembly used for teaching and faults"),
        .init(family:"Relay/control trainers",feature:"Clear electromechanical schematics",adaptation:"six synchronized representations",visualization:"cross-highlighted schematic/physical/logic/process",sharedTruthHook:"single canonical identity graph"),
        .init(family:"EveryCircuit-style",feature:"Live voltage/current visualization",adaptation:"Electrical Vision",visualization:"flow dots, numeric overlays, waveforms",sharedTruthHook:"solver node/branch values"),
        .init(family:"Falstad-style",feature:"Immediate interactive causality",adaptation:"cross-domain propagation",visualization:"cause/effect pulse through plant",sharedTruthHook:"electrical→mechanical→process→PLC"),
        .init(family:"3D circuit labs",feature:"Virtual instruments and benches",adaptation:"Instrument Locker + Electronics Bench",visualization:"meter faces, scopes, thermal/spectrum views",sharedTruthHook:"measurement physics and evidence ledger"),
        .init(family:"Multisim-class EDA",feature:"Analyses, probes, faults, sweeps",adaptation:"Engineering Analysis Lab",visualization:"trend/waveform/sweep plots",sharedTruthHook:"reference solver and captured plant state"),
        .init(family:"FluidSIM-class",feature:"Cross-domain libraries and fault models",adaptation:"electrical+pneumatic+hydraulic+process faults",visualization:"animated cutaways and state-colored media",sharedTruthHook:"component internal primitives"),
        .init(family:"Automation Studio-class",feature:"Mechatronic simulation, cutaways, plots, step modes",adaptation:"multi-rate digital twin + cutaway mode",visualization:"cutaway + sequence + plotter",sharedTruthHook:"shared component state across domains"),
        .init(family:"Factory I/O-class",feature:"3D plant scenes, PLC drivers, instructor failures",adaptation:"facility scenes + instructor studio",visualization:"live I/O overlay + hidden fault authoring",sharedTruthHook:"simple overrides or deep physical faults"),
        .init(family:"PLC trainers",feature:"Ladder, online values, debugging",adaptation:"PLC bench + Trace to Reality",visualization:"energized rung + reverse field trace",sharedTruthHook:"tag→channel→terminal→sensor→process"),
        .init(family:"Digital logic simulators",feature:"Hierarchy, timing, reusable blocks",adaptation:"plant-to-semiconductor hierarchy",visualization:"tree + timing diagram",sharedTruthHook:"nested canonical identities"),
        .init(family:"Engineering puzzle games",feature:"Documentation as puzzle material",adaptation:"Technical Library as evidence",visualization:"identity-aware document graph",sharedTruthHook:"documents project live plant identities"),
        .init(family:"CAN/embedded simulators",feature:"Frames, decoding, diagnostics, injected bus faults",adaptation:"CAN Bench",visualization:"packet timeline + bus voltage/scope",sharedTruthHook:"physical bus + protocol state"),
        .init(family:"Progressive construction games",feature:"Build complexity from primitives",adaptation:"40-academy progression",visualization:"skill constellation + unlock path",sharedTruthHook:"same primitives persist into full plant")
    ]
}

public struct Rev34DeepRuntime: Codable, Sendable {
    public var visualizations=EEVisualizationRegistry()
    public var analyses=EEAnalysisLab()
    public var trace=EETraceToReality()
    public var journey=EEWorkOrderJourney()
    public var instructor=EEInstructorStudio()
    public var canBench=EECANBench()
    public var catalog=EEDeepCompetitiveCatalog()
    public var activeSurface:EEVisualSurface = .electricalVision
    public var selectedIdentity="PIT401_SIGNAL"
    public init(){}
}
