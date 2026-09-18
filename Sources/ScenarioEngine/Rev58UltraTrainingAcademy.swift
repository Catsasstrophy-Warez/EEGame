import Foundation

// MARK: - Rev58 Ultra Training Academy
// Original training architecture. External publishers/standards are provenance metadata only.

public enum EETrainingRole58: String, CaseIterable, Sendable, Codable { case helper, apprentice, electrician, journeyman, master, ieTechnician, controlsTechnician, commissioningTechnician, reliabilityTechnician, engineer, instructor }
public enum EEAssessmentKind58: String, CaseIterable, Sendable, Codable { case knowledgeCheck, codeNavigation, calculation, schematicTrace, physicalBuild, instrumentPractical, commissioningPractical, diagnosticCase, forensicCase, capstone, teachBack }
public enum EELearningObjectiveKind58: String, CaseIterable, Sendable, Codable { case remember, explain, calculate, locate, interpret, build, measure, analyze, diagnose, verify, document, transfer, teach }
public enum EEQuestionGeneratorKind58: String, CaseIterable, Sendable, Codable { case ohmsLaw, power, seriesParallel, voltageDivider, acImpedance, transformerRatio, threePhasePower, voltageDrop, motorSlip, fourToTwentyScaling, loopCompliance, adcScaling, canTermination }

public struct EECurriculumNode58: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var title:String; public var domain:EETrainingDomain57; public var difficulty:EEDifficulty57
    public var objectives:[EELearningObjectiveKind58]; public var prerequisites:[String]; public var labs:[String]; public var assessments:[EEAssessmentKind58]
    public var referenceIDs:[String]; public var transferContexts:[EETrainingDomain57]; public var minimumEvidence:Int
}

public struct EEGeneratedProblem58: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var kind:EEQuestionGeneratorKind58; public var prompt:String; public var inputs:[String:Double]; public var expected:Double; public var tolerance:Double; public var unit:String
    public func validate(_ answer:Double)->Bool { abs(answer-expected) <= tolerance }
}

public struct EEProblemFactory58: Sendable, Codable, Equatable {
    public init(){}
    public func generate(kind:EEQuestionGeneratorKind58, seed:UInt64)->EEGeneratedProblem58 {
        let a = Double(2 + Int(seed % 19)); let b = Double(5 + Int((seed / 7) % 31)); let c = Double(10 + Int((seed / 13) % 91))
        switch kind {
        case .ohmsLaw: let v=a*12, r=b; return .init(id:"P-\(seed)-ohm",kind:kind,prompt:"A source is \(v) V across \(r) Ω. Calculate current.",inputs:["V":v,"R":r],expected:v/r,tolerance:1e-9,unit:"A")
        case .power: let v=a*24, i=b/10; return .init(id:"P-\(seed)-power",kind:kind,prompt:"Calculate real DC power from voltage and current.",inputs:["V":v,"I":i],expected:v*i,tolerance:1e-9,unit:"W")
        case .seriesParallel: let r1=a*10,r2=b*10; return .init(id:"P-\(seed)-series",kind:kind,prompt:"Calculate equivalent resistance of two series resistors.",inputs:["R1":r1,"R2":r2],expected:r1+r2,tolerance:1e-9,unit:"Ω")
        case .voltageDivider: let vin=c,r1=a*100,r2=b*100; return .init(id:"P-\(seed)-divider",kind:kind,prompt:"Calculate unloaded divider output.",inputs:["Vin":vin,"R1":r1,"R2":r2],expected:vin*r2/(r1+r2),tolerance:1e-9,unit:"V")
        case .acImpedance: let r=a*10,x=b*10; return .init(id:"P-\(seed)-z",kind:kind,prompt:"Calculate impedance magnitude from R and X.",inputs:["R":r,"X":x],expected:sqrt(r*r+x*x),tolerance:1e-9,unit:"Ω")
        case .transformerRatio: let vp=c*10,ratio=a; return .init(id:"P-\(seed)-xfmr",kind:kind,prompt:"Ideal transformer secondary voltage from primary voltage and turns ratio Np:Ns.",inputs:["Vp":vp,"ratio":ratio],expected:vp/ratio,tolerance:1e-9,unit:"V")
        case .threePhasePower: let v=480.0,i=a*3,pf=0.7+Double(seed%25)/100; return .init(id:"P-\(seed)-3p",kind:kind,prompt:"Calculate balanced three-phase real power.",inputs:["VLL":v,"I":i,"PF":pf],expected:sqrt(3)*v*i*pf,tolerance:1e-6,unit:"W")
        case .voltageDrop: let i=a*2,r=b/100; return .init(id:"P-\(seed)-vd",kind:kind,prompt:"Calculate conductor voltage drop from load current and total path resistance.",inputs:["I":i,"Rpath":r],expected:i*r,tolerance:1e-9,unit:"V")
        case .motorSlip: let ns=1800.0,nr=ns-Double(seed%120+20); return .init(id:"P-\(seed)-slip",kind:kind,prompt:"Calculate induction motor slip percent.",inputs:["Ns":ns,"Nr":nr],expected:(ns-nr)/ns*100,tolerance:1e-9,unit:"%")
        case .fourToTwentyScaling: let pct=Double(seed%101); return .init(id:"P-\(seed)-420",kind:kind,prompt:"Convert percent of calibrated span to loop current.",inputs:["percent":pct],expected:4+16*pct/100,tolerance:1e-9,unit:"mA")
        case .loopCompliance: let supply=24.0,load=Double(250+Int(seed%251)),ma=20.0; return .init(id:"P-\(seed)-compliance",kind:kind,prompt:"Calculate voltage remaining after loop load drop at 20 mA.",inputs:["Vs":supply,"Rload":load,"mA":ma],expected:supply-(ma/1000)*load,tolerance:1e-9,unit:"V")
        case .adcScaling: let ref=5.0,counts=Double(seed%4096); return .init(id:"P-\(seed)-adc",kind:kind,prompt:"Convert 12-bit ADC counts to voltage.",inputs:["Vref":ref,"counts":counts],expected:ref*counts/4095,tolerance:1e-9,unit:"V")
        case .canTermination: let r=120.0; return .init(id:"P-\(seed)-can",kind:kind,prompt:"Calculate equivalent resistance of two equal CAN terminators in parallel.",inputs:["R1":r,"R2":r],expected:60,tolerance:1e-9,unit:"Ω")
        }
    }
}

public struct EESchematicTraceChallenge58: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var title:String; public var orderedIdentities:[String]; public var distractors:[String]; public var hiddenOpenAt:String?
    public func grade(_ submitted:[String])->Double { guard !orderedIdentities.isEmpty else{return 1}; let n=min(submitted.count,orderedIdentities.count); let hits=(0..<n).filter{submitted[$0]==orderedIdentities[$0]}.count; return Double(hits)/Double(orderedIdentities.count) }
}

public struct EEInstrumentPractical58: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var title:String; public var allowedInstruments:[String]; public var requiredTestPoints:[String]; public var requiredEvidence:[String]; public var maxRedundantMeasurements:Int; public var safetyGates:[EESafetyGate57]
}

public struct EECompetencyTranscript58: Sendable, Codable, Equatable {
    public var role:EETrainingRole58; public var completedNodes:Set<String>=[]; public var assessmentScores:[String:Double]=[:]; public var practicalPasses:Set<String>=[]; public var unsafeEvents:Int=0; public var evidenceArtifacts:Int=0
    public init(role:EETrainingRole58 = .apprentice) { self.role=role }
    public var completionCount:Int { completedNodes.count }
}

public struct EECapstone58: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var title:String; public var domains:[EETrainingDomain57]; public var stages:[String]; public var hiddenFaultFamilies:[String]; public var requiredDocuments:[String]; public var requiredEvidence:[String]; public var minimumScore:Double
}

public struct EEUltraTrainingCatalog58: Sendable, Codable, Equatable {
    public var references:[EETrainingReference57]; public var nodes:[EECurriculumNode58]=[]; public var traces:[EESchematicTraceChallenge58]=[]; public var practicals:[EEInstrumentPractical58]=[]; public var capstones:[EECapstone58]=[]
    public init(){ let base=EEDeepTrainingCatalog57(); references=base.references; addReferenceExtensions(); buildNodes(); buildTraces(); buildPracticals(); buildCapstones() }
    mutating func addReferenceExtensions(){ references += [
        .init(id:"MH-EXAM",title:"Mike Holt - Electrical Exam Preparation",authority:.trainingPublisher,edition:"2026",topicTags:["theory","code","calculations","exam navigation"],note:"Curriculum-shape reference only; proprietary questions and solutions are not reproduced."),
        .init(id:"MH-FIELD-BG",title:"Mike Holt - Field Applications for Bonding and Grounding",authority:.trainingPublisher,edition:"2026",topicTags:["bonding","grounding","field application"],note:"Public topic descriptions inform original simulation exercises; verify actual requirements in the adopted code."),
        .init(id:"OSHA-1910.147A",title:"OSHA 1910.147 Appendix A - Typical Minimal Lockout Procedure",authority:.lawOrRegulation,edition:nil,topicTags:["LOTO","procedure","energy isolation"],note:"Reference for training concepts only; real employers require machine-specific energy-control procedures where applicable.")
    ] }
    mutating func buildNodes(){
        nodes=[]; let base=EEDeepTrainingCatalog57()
        for skill in base.skills {
            for band in 1...4 {
                let diff=EEDifficulty57(rawValue:min(6,max(skill.difficulty.rawValue,band+1))) ?? .forensic
                let suffix=["concept","application","practical","transfer"][band-1]
                nodes.append(.init(id:"58-\(skill.id)-\(suffix)",title:"\(skill.title) • \(suffix.capitalized)",domain:skill.domain,difficulty:diff,objectives:band==1 ? [.explain,.interpret] : band==2 ? [.calculate,.analyze] : band==3 ? [.build,.measure,.verify] : [.diagnose,.transfer,.document],prerequisites:band==1 ? skill.prerequisites.map{"58-\($0)-concept"}:["58-\(skill.id)-\(["concept","application","practical"][band-2])"],labs:["simulation","drawing","instrument","evidence"],assessments:band==1 ? [.knowledgeCheck] : band==2 ? [.calculation,.codeNavigation] : band==3 ? [.physicalBuild,.instrumentPractical] : [.diagnosticCase,.teachBack],referenceIDs:skill.referenceIDs,transferContexts:skill.transferTargets,minimumEvidence:max(1,band)))
            }
        }
    }
    mutating func buildTraces(){ traces=[
        .init(id:"trace-starter",title:"Three-wire starter control path",orderedIdentities:["XFMR:X1","FU:C","STOP:1","OL:95","START:3","M:A1","XFMR:X2"],distractors:["M:L1","M:T1","PLC:I0"],hiddenOpenAt:nil),
        .init(id:"trace-loop",title:"4–20 mA loop Golden Thread",orderedIdentities:["PS24:+","PIT:+","PIT:-","JB:12","AI:3+","AI:3-","PS24:-"],distractors:["AO:2","SHIELD:FIELD"],hiddenOpenAt:"JB:12"),
        .init(id:"trace-vfd",title:"VFD run-command path",orderedIdentities:["PLC:O3","TB:21","VFD:DI1","VFD:COM"],distractors:["VFD:AI1","MOTOR:T1"],hiddenOpenAt:nil)
    ] }
    mutating func buildPracticals(){ practicals=[
        .init(id:"prac-dmm-control",title:"Control-circuit voltage-drop practical",allowedInstruments:["DMM"],requiredTestPoints:["XFMR:X1","FU:C","STOP:1","M:A1","XFMR:X2"],requiredEvidence:["source voltage","loaded drop","coil voltage","repair verification"],maxRedundantMeasurements:3,safetyGates:[.hazardRecognition]),
        .init(id:"prac-loop",title:"4–20 mA loop practical",allowedInstruments:["DMM","loop calibrator","HART communicator"],requiredTestPoints:["PIT:+","JB:12","AI:3+"],requiredEvidence:["loop current","range","compliance","as-left"],maxRedundantMeasurements:4,safetyGates:[.hazardRecognition]),
        .init(id:"prac-isolation",title:"Multi-energy isolation verification",allowedInstruments:["DMM","pressure gauge"],requiredTestPoints:["DISC:LOAD","DCBUS:+","AIR:HEADER"],requiredEvidence:["energy inventory","isolation","stored energy","verification","restoration"],maxRedundantMeasurements:2,safetyGates:[.energySourceIdentification,.isolationPlan,.storedEnergy,.verifyDeenergized,.restoration])
    ] }
    mutating func buildCapstones(){ capstones=[
        .init(id:"capstone-mcc",title:"Commission and diagnose an MCC-fed motor system",domains:[.industrialPower,.motorControls,.testInstruments,.commissioning,.troubleshooting],stages:["review drawings","inspect","calculate","build","energize","measure","fault diagnose","repair","prove","document"],hiddenFaultFamilies:["highResistance","singlePhasing","overload","miswire"],requiredDocuments:["one-line","elementary","terminal plan","motor data"],requiredEvidence:["preflight","measurements","root cause","repair verification","turnover"],minimumScore:0.82),
        .init(id:"capstone-gas",title:"Natural-gas compressor station I&E capstone",domains:[.naturalGasIE,.instrumentation,.plc,.drives,.processControl,.forensicDiagnostics],stages:["handoff","walkdown","Golden Thread","live measurements","historian/SOE","repair","recommission"],hiddenFaultFamilies:["loopResistance","sensorDrift","networkIntermittent","valveBinding"],requiredDocuments:["P&ID","loop sheet","I/O list","cause/effect"],requiredEvidence:["process","electrical","automation","verification"],minimumScore:0.85),
        .init(id:"capstone-coal",title:"Coal preparation and material-handling I&E capstone",domains:[.coalMiningIE,.motorControls,.instrumentation,.plc,.industrialNetworks,.forensicDiagnostics],stages:["shift review","plant trace","measure","isolate","repair","restart","forensic closeout"],hiddenFaultFamilies:["beltSensor","highResistance","mediumInstrumentBias","networkNoise"],requiredDocuments:["one-line","elementary","process drawing","I/O list"],requiredEvidence:["machine","electrical","process","historian","proof"],minimumScore:0.85),
        .init(id:"capstone-forensic",title:"Cross-domain forensic board",domains:[.forensicDiagnostics,.engineeringAnalysis,.documentation,.leadershipInstruction],stages:["preserve evidence","timeline","competing hypotheses","discriminating tests","causal graph","defense"],hiddenFaultFamilies:["compound","intermittent","latentWorkmanship"],requiredDocuments:["SOE","historian","maintenance","drawings"],requiredEvidence:["timeline","hypothesis matrix","physics","root cause","corrective action"],minimumScore:0.90)
    ] }
    public func unlocked(completed:Set<String>)->[EECurriculumNode58] { nodes.filter{$0.prerequisites.allSatisfy(completed.contains)} }
}

public struct EERev58UltraTrainingAcademy: Sendable, Codable {
    public var base=EERev57DeepTrainingSystem(); public var catalog=EEUltraTrainingCatalog58(); public var transcript=EECompetencyTranscript58(); public var problems=EEProblemFactory58()
    public init(){}
}
