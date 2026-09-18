import Foundation

// MARK: - Rev57 Deep Training System
// Educational architecture only. Code/safety references are metadata pointers, not reproduced standards.

public enum EEAuthorityClass57: String, CaseIterable, Sendable, Codable { case lawOrRegulation, consensusStandard, trainingPublisher, manufacturer, engineeringReference, siteProcedure }
public struct EETrainingReference57: Identifiable, Sendable, Codable, Equatable {
    public var id: String; public var title: String; public var authority: EEAuthorityClass57
    public var edition: String?; public var topicTags: [String]; public var note: String
}
public enum EETrainingDomain57: String, CaseIterable, Sendable, Codable {
    case electricalTheory, dcCircuits, acCircuits, calculations, codeNavigation, wiringMethods, groundingBonding,
         overcurrentProtection, servicesFeedersBranchCircuits, transformers, generators, motors, motorControls,
         industrialPower, hazardousLocations, electricalSafety, lotoEnergyControl, testInstruments, electronics,
         instrumentation, calibration, plc, hmiScada, drives, industrialNetworks, embedded, canBus,
         processControl, commissioning, maintenanceReliability, troubleshooting, forensicDiagnostics,
         naturalGasIE, coalMiningIE, engineeringAnalysis, documentation, leadershipInstruction
}
public enum EEKnowledgeType57: String, CaseIterable, Sendable, Codable { case concept, calculation, codeLookup, identification, procedure, construction, measurement, diagnosis, verification, explanation, transfer }
public enum EEDifficulty57: Int, CaseIterable, Sendable, Codable { case foundation = 1, apprentice, journeyman, advanced, master, forensic }
public enum EESafetyGate57: String, CaseIterable, Sendable, Codable { case none, hazardRecognition, energySourceIdentification, isolationPlan, verifyDeenergized, ppeBoundaryAwareness, storedEnergy, restoration }
public struct EESkill57: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var title:String; public var domain:EETrainingDomain57; public var type:EEKnowledgeType57
    public var difficulty:EEDifficulty57; public var prerequisites:[String]; public var competency:EECompetency56
    public var safetyGate:EESafetyGate57; public var referenceIDs:[String]; public var transferTargets:[EETrainingDomain57]
}
public struct EETrainingModule57: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var title:String; public var domain:EETrainingDomain57; public var difficulty:EEDifficulty57
    public var skillIDs:[String]; public var stages:[EETrainingStage56]; public var modes:[EELessonMode56]
    public var minimumEvidence:Int; public var randomizedFaultFamilies:[String]; public var estimatedMinutes:Int
}
public struct EESpacingState57: Sendable, Codable, Equatable {
    public var skillID:String; public var repetitions:Int=0; public var ease:Double=2.3; public var intervalDays:Int=0; public var dueDay:Int=0
    public mutating func record(score:Double,currentDay:Int){repetitions += 1;if score < 0.6 {intervalDays=1;ease=max(1.3,ease-0.2)} else {if repetitions==1{intervalDays=1}else if repetitions==2{intervalDays=3}else{intervalDays=max(1,Int((Double(intervalDays)*ease).rounded()))};ease=min(3.0,max(1.3,ease + (score-0.8)*0.25))};dueDay=currentDay+intervalDays}
}
public struct EETransferChallenge57: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var sourceSkillID:String; public var destination:EETrainingDomain57; public var title:String
    public var hiddenFaultFamily:String; public var requiredEvidenceKinds:[String]; public var instrumentLimit:Int
}
public struct EEInstructorScenario57: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var title:String; public var domain:EETrainingDomain57; public var assetIDs:[String]
    public var hiddenFaults:[String]; public var availableDocuments:[String]; public var allowedInstruments:[String]
    public var objectives:[String]; public var requiredEvidence:[String]; public var forbiddenReveals:[String]
    public var safetyGates:[EESafetyGate57]; public var seed:UInt64
}
public struct EEAttemptTelemetry57: Sendable, Codable, Equatable {
    public var skillID:String; public var elapsedSeconds:Double; public var measurements:Int; public var redundantMeasurements:Int
    public var unsafeActions:Int; public var hints:Int; public var evidenceQuality:Double; public var rootCauseCorrect:Bool
    public var repairVerified:Bool; public var explanationScore:Double; public var transferSuccess:Bool
    public init(skillID:String,elapsedSeconds:Double,measurements:Int,redundantMeasurements:Int,unsafeActions:Int,hints:Int,evidenceQuality:Double,rootCauseCorrect:Bool,repairVerified:Bool,explanationScore:Double,transferSuccess:Bool){self.skillID=skillID;self.elapsedSeconds=elapsedSeconds;self.measurements=measurements;self.redundantMeasurements=redundantMeasurements;self.unsafeActions=unsafeActions;self.hints=hints;self.evidenceQuality=evidenceQuality;self.rootCauseCorrect=rootCauseCorrect;self.repairVerified=repairVerified;self.explanationScore=explanationScore;self.transferSuccess=transferSuccess}
    public var efficiency:Double { guard measurements > 0 else { return 1 }; return max(0,min(1,1-Double(redundantMeasurements)/Double(measurements))) }
    public var score:Double { if unsafeActions > 0 { return min(0.49,rawScore) }; return rawScore }
    private var rawScore:Double { 0.18*evidenceQuality + 0.16*efficiency + 0.18*(rootCauseCorrect ? 1:0) + 0.18*(repairVerified ? 1:0) + 0.15*explanationScore + 0.15*(transferSuccess ? 1:0) }
}

public struct EEDeepTrainingCatalog57: Sendable, Codable, Equatable {
    public var references:[EETrainingReference57]=[]; public var skills:[EESkill57]=[]; public var modules:[EETrainingModule57]=[]; public var transfers:[EETransferChallenge57]=[]
    public init(){buildReferences();buildSkills();buildModules();buildTransfers()}
    mutating func buildReferences(){references=[
        .init(id:"MH-APPRENTICESHIP",title:"Mike Holt - Electrical Apprenticeship / Certified Electrician curriculum overview",authority:.trainingPublisher,edition:"current public overview",topicTags:["apprenticeship","safety","theory","NEC","motors","controls","calculations","leadership"],note:"Curriculum-structure reference only; do not reproduce proprietary questions, answer keys, text, graphics, or exams."),
        .init(id:"OSHA-1910.333",title:"OSHA 29 CFR 1910.333 Selection and Use of Work Practices",authority:.lawOrRegulation,edition:nil,topicTags:["deenergizing","qualified persons","energized work","work practices"],note:"Use current OSHA text for regulatory concepts; real work follows employer procedures and applicable law."),
        .init(id:"MH-THEORY",title:"Mike Holt - Understanding Electrical Theory",authority:.trainingPublisher,edition:nil,topicTags:["theory","circuits","ac","motors","transformers"],note:"Training inspiration/reference; do not reproduce copyrighted text or graphics."),
        .init(id:"MH-NEC",title:"Mike Holt - Understanding the NEC",authority:.trainingPublisher,edition:"2026",topicTags:["NEC","code navigation","wiring","equipment"],note:"Curriculum-structure reference only; verify requirements against adopted code and AHJ."),
        .init(id:"MH-BG",title:"Mike Holt - Bonding and Grounding",authority:.trainingPublisher,edition:"2026",topicTags:["bonding","grounding","fault path"],note:"Concept/reference source; actual requirements must be verified against applicable adopted NEC."),
        .init(id:"MH-CALC",title:"Mike Holt - Fundamental NEC Calculations",authority:.trainingPublisher,edition:"2026",topicTags:["calculations","load","conductor","protection"],note:"Curriculum reference; do not copy proprietary questions or solutions."),
        .init(id:"OSHA-1910.332",title:"OSHA 29 CFR 1910.332 Electrical Training",authority:.lawOrRegulation,edition:nil,topicTags:["qualified person","training","electrical hazards"],note:"Use current OSHA text for regulatory training concepts."),
        .init(id:"OSHA-1910.147",title:"OSHA 29 CFR 1910.147 Hazardous Energy Control",authority:.lawOrRegulation,edition:nil,topicTags:["LOTO","hazardous energy","verification"],note:"Simulation supports learning; employer/site procedures govern real work."),
        .init(id:"NFPA70",title:"NFPA 70 National Electrical Code",authority:.consensusStandard,edition:"jurisdiction dependent",topicTags:["installation","wiring","protection"],note:"Edition/adoption varies by jurisdiction."),
        .init(id:"NFPA70E",title:"NFPA 70E Standard for Electrical Safety in the Workplace",authority:.consensusStandard,edition:"current applicable edition",topicTags:["electrical safety","work practices","risk"],note:"Do not substitute game guidance for employer program or qualified-person training.")
    ]}
    mutating func buildSkills(){skills=[];let specs:[(EETrainingDomain57,[String],EECompetency56,[String])]=[
        (.electricalTheory,["charge-current-voltage","resistance-conductance","power-energy","kirchhoff-laws","source-impedance","electric-magnetic-fields"],.theory,["MH-THEORY"]),
        (.dcCircuits,["series","parallel","voltage-divider","current-divider","thevenin-norton","bridge-circuits"],.numericalReasoning,["MH-THEORY"]),
        (.acCircuits,["sine-rms","phase","reactance","impedance","power-factor","resonance"],.numericalReasoning,["MH-THEORY"]),
        (.calculations,["conductor-load","voltage-drop","transformer","motor","feeder-service","fault-current"],.numericalReasoning,["MH-CALC"]),
        (.codeNavigation,["scope-purpose","definitions","chapter-structure","article-navigation","exceptions-notes","edition-jurisdiction"],.documentation,["MH-NEC","NFPA70"]),
        (.groundingBonding,["grounded-vs-grounding","equipment-bonding","fault-current-path","bonding-jumpers","electrode-system","objectionable-current"],.theory,["MH-BG","NFPA70"]),
        (.wiringMethods,["conductors","raceways","cables","boxes","terminations","environmental-suitability"],.physicalConstruction,["MH-NEC","NFPA70"]),
        (.overcurrentProtection,["fuse-basics","breaker-basics","overload-vs-fault","interrupting-rating","selectivity","coordination"],.theory,["MH-NEC","NFPA70"]),
        (.transformers,["ratio-polarity","single-phase","three-phase","connections","inrush","diagnostics"],.diagnosis,["MH-THEORY","MH-NEC"]),
        (.motors,["rotating-field","induction-slip","nameplate","starting","single-phasing","motor-faults"],.diagnosis,["MH-THEORY","MH-NEC"]),
        (.motorControls,["three-wire","seal-in","jog-hoa","reversing","timing-sequence","starter-forensics"],.physicalConstruction,["MH-THEORY"]),
        (.electricalSafety,["hazard-recognition","qualified-person-concepts","nominal-voltage","approach-awareness","safe-work-planning","incident-response"],.safetyIsolation,["OSHA-1910.332","NFPA70E"]),
        (.lotoEnergyControl,["energy-inventory","shutdown","isolate","lock-tag","stored-energy","verify-isolation"],.safetyIsolation,["OSHA-1910.147"]),
        (.testInstruments,["meter-category-awareness","lead-jack-selection","live-dead-live-concept","voltage-measurement","current-measurement","insulation-loop-scope"],.instrumentUse,["OSHA-1910.332"]),
        (.instrumentation,["4-20ma","pressure","dp-flow","temperature","level","control-valve"],.instrumentUse,[]),
        (.calibration,["as-found","zero-span","five-point","hysteresis","loop-check","as-left"],.commissioning,[]),
        (.plc,["scan-cycle","discrete-io","timers-counters","analog-scaling","interlocks","sequence-forensics"],.automation,[]),
        (.drives,["rectifier","dc-bus","inverter-pwm","parameterization","motor-coupling","drive-forensics"],.automation,[]),
        (.industrialNetworks,["ethernet-physical","addressing","remote-io","serial","noise-shielding","packet-forensics"],.automation,[]),
        (.embedded,["gpio","pwm","adc","timers-interrupts","uart-spi-i2c","hardware-debug"],.automation,[]),
        (.canBus,["differential-signaling","termination","transceiver","frames","bus-faults","scope-forensics"],.diagnosis,[]),
        (.processControl,["process-dynamics","feedback","pid","valve-loop","interlocks","upset-forensics"],.processReasoning,[]),
        (.commissioning,["inspection","point-to-point","energization-plan","functional-test","baseline-data","turnover"],.commissioning,["OSHA-1910.147"]),
        (.troubleshooting,["symptom-vs-cause","hypothesis-set","measurement-plan","discriminating-test","intermittent-fault","proof-of-repair"],.diagnosis,[]),
        (.forensicDiagnostics,["soe","historian","plc-state","network-events","thermal-vibration","causal-dossier"],.rootCause,[]),
        (.engineeringAnalysis,["dc-op","transient","ac-bode","fft","monte-carlo","conservation"],.numericalReasoning,[]),
        (.naturalGasIE,["station-power","compressor-controls","instrument-air","recycle-antisurge","bms-esd","station-forensics"],.processReasoning,[]),
        (.coalMiningIE,["mine-power","belt-protection","ventilation-instruments","mine-water","prep-controls","mine-forensics"],.processReasoning,[]),
        (.documentation,["one-line","elementary","loop-sheet","io-list","cause-effect","maintenance-record"],.documentation,[]),
        (.leadershipInstruction,["teach-back","coach-measurement","review-evidence","write-scenario","assess-competency","mentor-transfer"],.documentation,[])
    ];for (domain,names,competency,refs) in specs {for (idx,name) in names.enumerated(){let difficulty=EEDifficulty57(rawValue:min(6,idx+1)) ?? .forensic;let id="57-\(domain.rawValue)-\(name)";skills.append(.init(id:id,title:name.replacingOccurrences(of:"-",with:" ").capitalized,domain:domain,type:idx<2 ? .concept:(idx<4 ? .procedure:.transfer),difficulty:difficulty,prerequisites:idx==0 ? []:["57-\(domain.rawValue)-\(names[idx-1])"],competency:competency,safetyGate:(domain == .electricalSafety || domain == .lotoEnergyControl) ? [.hazardRecognition,.energySourceIdentification,.isolationPlan,.verifyDeenergized,.storedEnergy,.restoration][idx] : .none,referenceIDs:refs,transferTargets:transferTargets(for:domain)))}}}
    func transferTargets(for d:EETrainingDomain57)->[EETrainingDomain57]{switch d{case .electricalTheory,.dcCircuits,.acCircuits:return [.electronics,.motorControls,.instrumentation];case .groundingBonding,.overcurrentProtection:return [.industrialPower,.naturalGasIE,.coalMiningIE];case .motorControls,.motors:return [.drives,.naturalGasIE,.coalMiningIE];case .instrumentation,.calibration:return [.processControl,.naturalGasIE,.coalMiningIE];case .plc,.industrialNetworks:return [.processControl,.naturalGasIE,.coalMiningIE];case .embedded,.canBus:return [.industrialNetworks,.forensicDiagnostics];default:return [.troubleshooting,.forensicDiagnostics]}}
    mutating func buildModules() {
        modules = []
        for d in EETrainingDomain57.allCases {
            let ds = skills.filter { $0.domain == d }
            guard !ds.isEmpty else { continue }
            for level in EEDifficulty57.allCases {
                let eligible = ds.filter { $0.difficulty.rawValue <= level.rawValue }
                guard !eligible.isEmpty else { continue }
                modules.append(.init(id: "57-module-\(d.rawValue)-\(level.rawValue)", title: "\(d.rawValue) • \(level)", domain: d, difficulty: level, skillIDs: eligible.map(\.id), stages: EETrainingStage56.allCases, modes: [.demonstration,.guided,.assisted,.independent,.assessment,.forensicCase], minimumEvidence: max(1,level.rawValue), randomizedFaultFamilies: level.rawValue >= 3 ? ["open","short","highResistance","miswire","intermittent","drift","misconfiguration","mechanicalBinding"] : [], estimatedMinutes: 20 + level.rawValue * 15))
            }
        }
    }
    mutating func buildTransfers() {
        transfers = []
        for s in skills where s.difficulty.rawValue >= 3 {
            for t in s.transferTargets.prefix(2) {
                let families = ["highResistance","intermittent","misconfiguration","open"]
                let stableIndex = s.id.utf8.reduce(0) { ($0 + Int($1)) % families.count }
                transfers.append(.init(id: "57-transfer-\(s.id)-\(t.rawValue)", sourceSkillID: s.id, destination: t, title: "Apply \(s.title) in \(t.rawValue)", hiddenFaultFamily: families[stableIndex], requiredEvidenceKinds: ["measurement","drawing","simulationProvenance","verification"], instrumentLimit: max(2,7-s.difficulty.rawValue)))
            }
        }
    }
    public func skill(_ id:String)->EESkill57?{skills.first{$0.id==id}}
    public func availableSkills(completed:Set<String>)->[EESkill57]{skills.filter{$0.prerequisites.allSatisfy(completed.contains)}}
    public func references(for skill:EESkill57)->[EETrainingReference57]{self.references.filter{skill.referenceIDs.contains($0.id)}}
}

public struct EEAdaptiveTrainingEngine57: Sendable, Codable, Equatable {
    public var catalog=EEDeepTrainingCatalog57(); public var completed:Set<String>=[]; public var mastery:[String:Double]=[:]; public var spacing:[String:EESpacingState57]=[:]; public var attempts:[EEAttemptTelemetry57]=[]
    public init(){for s in catalog.skills{mastery[s.id]=0;spacing[s.id] = .init(skillID:s.id)}}
    public mutating func record(_ attempt:EEAttemptTelemetry57,currentDay:Int){attempts.append(attempt);let old=mastery[attempt.skillID] ?? 0;mastery[attempt.skillID]=min(1,max(0,old*0.65+attempt.score*0.35));spacing[attempt.skillID]?.record(score:attempt.score,currentDay:currentDay);if attempt.score>=0.78 && attempt.unsafeActions==0 && attempt.rootCauseCorrect && attempt.repairVerified{completed.insert(attempt.skillID)}}
    public func dueSkills(day:Int)->[EESkill57]{catalog.skills.filter{(spacing[$0.id]?.dueDay ?? 0)<=day && (mastery[$0.id] ?? 0)<0.92}}
    public func weakestSkills(limit:Int=5)->[EESkill57]{catalog.skills.sorted{(mastery[$0.id] ?? 0)<(mastery[$1.id] ?? 0)}.prefix(limit).map{$0}}
    public func recommended(day:Int,limit:Int=8)->[EESkill57]{let available=catalog.availableSkills(completed:completed);return available.sorted{a,b in let ad=spacing[a.id]?.dueDay ?? 0,bd=spacing[b.id]?.dueDay ?? 0;if (ad<=day) != (bd<=day){return ad<=day};return (mastery[a.id] ?? 0)<(mastery[b.id] ?? 0)}.prefix(limit).map{$0}}
}
public struct EERev57DeepTrainingSystem: Sendable, Codable { public var base=EERev56NumericalTrainingExpansion(); public var training=EEAdaptiveTrainingEngine57(); public init(){} }
