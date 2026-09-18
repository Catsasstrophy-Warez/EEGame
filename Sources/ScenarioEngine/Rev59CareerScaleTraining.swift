import Foundation

// MARK: - Rev59 Career-Scale Training & Assessment
// Original simulation-backed curriculum. External standards/publishers are provenance only.

public enum EEPathway59: String, CaseIterable, Sendable, Codable { case apprenticeElectrician, journeymanElectrician, masterElectrician, ieTechnician, controlsTechnician, commissioningSpecialist, forensicEngineer, instructor }
public enum EEExamSection59: String, CaseIterable, Sendable, Codable { case theory, calculations, codeNavigation, drawings, practical, diagnostics, safety, documentation, oralDefense }
public enum EECodeLookupSkill59: String, CaseIterable, Sendable, Codable { case identifyScope, identifyDefinition, navigateHierarchy, selectApplicableRuleFamily, recognizeException, identifyEditionAndJurisdiction, distinguishCodeFromWorkPractice, documentCitation }
public enum EEOralPromptKind59: String, CaseIterable, Sendable, Codable { case explainPhysics, defendMeasurement, defendRootCause, explainSafetyPlan, compareAlternatives, teachBack, incidentDefense }

public struct EEPathwayRequirement59: Sendable, Codable, Equatable {
    public var domain: EETrainingDomain57; public var minimumCompletedNodes:Int; public var minimumAverageScore:Double
}
public struct EEPathway59Model: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var pathway:EEPathway59; public var title:String; public var requirements:[EEPathwayRequirement59]
    public var requiredPracticals:[String]; public var requiredCapstones:[String]; public var examSections:[EEExamSection59]; public var minimumOverall:Double
}

public struct EECodeNavigationExercise59: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var title:String; public var skill:EECodeLookupSkill59; public var scenario:String
    public var searchTerms:[String]; public var expectedRuleFamily:String; public var edition:String; public var jurisdictionNote:String
    public var referenceIDs:[String]
    public func grade(ruleFamily:String, identifiedEdition:String)->Double {
        let family = ruleFamily.caseInsensitiveCompare(expectedRuleFamily) == .orderedSame ? 0.7 : 0
        let ed = identifiedEdition == edition ? 0.3 : 0
        return family + ed
    }
}

public struct EECalculationLab59: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var problem:EEGeneratedProblem58; public var predicted:Double; public var simulated:Double; public var measured:Double
    public var predictionTolerance:Double; public var reconciliationPrompt:String
    public init(id:String,problem:EEGeneratedProblem58,predicted:Double,simulated:Double,measured:Double,predictionTolerance:Double,reconciliationPrompt:String){self.id=id;self.problem=problem;self.predicted=predicted;self.simulated=simulated;self.measured=measured;self.predictionTolerance=predictionTolerance;self.reconciliationPrompt=reconciliationPrompt}
    public var predictionError:Double { abs(predicted-problem.expected) }
    public var simulationError:Double { abs(simulated-problem.expected) }
    public var measurementError:Double { abs(measured-simulated) }
    public var passed:Bool { predictionError <= predictionTolerance && simulationError <= max(problem.tolerance,predictionTolerance) }
}

public struct EEPracticalVariant59: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var basePracticalID:String; public var seed:UInt64; public var hiddenFault:String; public var shuffledTestPoints:[String]; public var unavailableInstrument:String?
}
public struct EEPracticalGenerator59: Sendable, Codable, Equatable {
    public init(){}
    public func generate(from practical:EEInstrumentPractical58, seed:UInt64)->EEPracticalVariant59 {
        let faults=["open","highResistance","miswire","intermittent","drift","groundReference","supplySag"]
        let fault=faults[Int(seed % UInt64(faults.count))]
        let points=practical.requiredTestPoints.sorted { a,b in
            let av=UInt64(a.utf8.reduce(0){$0 &+ UInt64($1)}) &+ seed
            let bv=UInt64(b.utf8.reduce(0){$0 &+ UInt64($1)}) &+ seed
            return av < bv
        }
        let unavailable = practical.allowedInstruments.count > 1 && seed % 3 == 0 ? practical.allowedInstruments[Int(seed % UInt64(practical.allowedInstruments.count))] : nil
        return .init(id:"59-\(practical.id)-\(seed)",basePracticalID:practical.id,seed:seed,hiddenFault:fault,shuffledTestPoints:points,unavailableInstrument:unavailable)
    }
}

public struct EEOralDefense59: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var kind:EEOralPromptKind59; public var prompt:String; public var requiredConcepts:[String]; public var forbiddenShortcuts:[String]
    public func grade(concepts:[String], evidenceCount:Int, unsafeClaims:Int)->Double {
        guard unsafeClaims == 0 else { return 0.35 }
        let hits=requiredConcepts.filter{concepts.contains($0)}.count
        let conceptScore=requiredConcepts.isEmpty ? 1 : Double(hits)/Double(requiredConcepts.count)
        return min(1,0.8*conceptScore + 0.2*min(1,Double(evidenceCount)/3))
    }
}

public struct EEInstructorDashboard59: Sendable, Codable, Equatable {
    public var cohortName:String="Training Cohort"; public var assignedNodeIDs:Set<String>=[]; public var assignedPracticalIDs:Set<String>=[]; public var assignedCapstoneIDs:Set<String>=[]
    public var learnerScores:[String:[String:Double]]=[:]; public var safetyEvents:[String:Int]=[:]
    public init(){}
    public mutating func record(learner:String,item:String,score:Double,unsafe:Int=0){learnerScores[learner,default:[:]][item]=score;safetyEvents[learner,default:0]+=unsafe}
    public func average(for learner:String)->Double {let v=Array(learnerScores[learner]?.values ?? [:].values);return v.isEmpty ? 0 : v.reduce(0,+)/Double(v.count)}
}

public struct EEInstructorScenarioAuthor59: Sendable, Codable, Equatable {
    public init(){}
    public func make(id:String,title:String,domain:EETrainingDomain57,assets:[String],faultFamilies:[String],documents:[String],instruments:[String],objectives:[String],evidence:[String],safety:[EESafetyGate57],seed:UInt64)->EEInstructorScenario57 {
        .init(id:id,title:title,domain:domain,assetIDs:assets,hiddenFaults:faultFamilies,availableDocuments:documents,allowedInstruments:instruments,objectives:objectives,requiredEvidence:evidence,forbiddenReveals:["fault identity","replacement answer","scripted next measurement"],safetyGates:safety,seed:seed)
    }
}

public struct EETrainingCatalog59: Sendable, Codable, Equatable {
    public var base=EEUltraTrainingCatalog58(); public var codeExercises:[EECodeNavigationExercise59]=[]; public var oralDefenses:[EEOralDefense59]=[]; public var pathways:[EEPathway59Model]=[]
    public init(){buildCodeExercises();buildOrals();buildPathways()}
    mutating func buildCodeExercises(){
        let skills=EECodeLookupSkill59.allCases
        let families=["scope/purpose","definitions","structure/navigation","applicable rule family","exceptions","edition/adoption","installation vs work practice","citation/provenance"]
        codeExercises=(0..<96).map { i in
            let s=skills[i % skills.count]
            return .init(id:"59-code-\(i)",title:"Code Navigation Practical \(i+1)",skill:s,scenario:"Inspect the simulated installation, identify the governing rule family, edition context, and evidence needed before making a compliance conclusion.",searchTerms:[s.rawValue,"installation","equipment"],expectedRuleFamily:families[i % families.count],edition:"2026 training map",jurisdictionNote:"Adoption and amendments vary by jurisdiction; exercise trains navigation and reasoning, not legal advice.",referenceIDs:["MH-NEC","NFPA70"])
        }
    }
    mutating func buildOrals(){oralDefenses=(0..<72).map{i in let k=EEOralPromptKind59.allCases[i % EEOralPromptKind59.allCases.count];return .init(id:"59-oral-\(i)",kind:k,prompt:"Defend your engineering reasoning for case \(i+1) using physical evidence, drawings, measurements, and verification.",requiredConcepts:["physical truth","evidence","verification"],forbiddenShortcuts:["guess","replace without test","unsafe energized assumption"])} }
    mutating func buildPathways(){
        func req(_ ds:[EETrainingDomain57],_ n:Int,_ score:Double)->[EEPathwayRequirement59]{ds.map{.init(domain:$0,minimumCompletedNodes:n,minimumAverageScore:score)}}
        pathways=[
            .init(id:"59-path-apprentice",pathway:.apprenticeElectrician,title:"Apprentice Electrician",requirements:req([.electricalTheory,.dcCircuits,.acCircuits,.codeNavigation,.wiringMethods,.electricalSafety,.testInstruments],8,0.72),requiredPracticals:["prac-dmm-control","prac-isolation"],requiredCapstones:[],examSections:[.theory,.calculations,.codeNavigation,.drawings,.safety],minimumOverall:0.75),
            .init(id:"59-path-journeyman",pathway:.journeymanElectrician,title:"Journeyman Electrician",requirements:req([.calculations,.codeNavigation,.groundingBonding,.overcurrentProtection,.servicesFeedersBranchCircuits,.transformers,.motors,.motorControls],12,0.80),requiredPracticals:["prac-dmm-control","prac-isolation"],requiredCapstones:["capstone-mcc"],examSections:[.theory,.calculations,.codeNavigation,.drawings,.practical,.diagnostics,.safety],minimumOverall:0.80),
            .init(id:"59-path-master",pathway:.masterElectrician,title:"Master Electrician",requirements:req([.calculations,.codeNavigation,.groundingBonding,.industrialPower,.hazardousLocations,.documentation,.leadershipInstruction],14,0.85),requiredPracticals:["prac-dmm-control","prac-isolation"],requiredCapstones:["capstone-mcc","capstone-forensic"],examSections:EEExamSection59.allCases,minimumOverall:0.86),
            .init(id:"59-path-ie",pathway:.ieTechnician,title:"Instrumentation & Electrical Technician",requirements:req([.instrumentation,.calibration,.plc,.drives,.processControl,.troubleshooting,.naturalGasIE,.coalMiningIE],12,0.84),requiredPracticals:["prac-loop","prac-dmm-control","prac-isolation"],requiredCapstones:["capstone-gas","capstone-coal"],examSections:[.theory,.drawings,.practical,.diagnostics,.safety,.documentation,.oralDefense],minimumOverall:0.84),
            .init(id:"59-path-controls",pathway:.controlsTechnician,title:"Controls Technician",requirements:req([.plc,.hmiScada,.industrialNetworks,.embedded,.canBus,.processControl,.forensicDiagnostics],12,0.84),requiredPracticals:["prac-loop"],requiredCapstones:["capstone-forensic"],examSections:[.theory,.drawings,.practical,.diagnostics,.documentation,.oralDefense],minimumOverall:0.84),
            .init(id:"59-path-commissioning",pathway:.commissioningSpecialist,title:"Commissioning Specialist",requirements:req([.commissioning,.documentation,.testInstruments,.instrumentation,.motorControls,.drives,.plc],12,0.86),requiredPracticals:["prac-dmm-control","prac-loop","prac-isolation"],requiredCapstones:["capstone-mcc","capstone-gas"],examSections:[.drawings,.practical,.diagnostics,.safety,.documentation,.oralDefense],minimumOverall:0.86),
            .init(id:"59-path-forensic",pathway:.forensicEngineer,title:"Forensic Engineer",requirements:req([.forensicDiagnostics,.engineeringAnalysis,.troubleshooting,.documentation,.leadershipInstruction],16,0.90),requiredPracticals:["prac-dmm-control","prac-loop"],requiredCapstones:["capstone-forensic"],examSections:[.theory,.calculations,.drawings,.diagnostics,.documentation,.oralDefense],minimumOverall:0.90),
            .init(id:"59-path-instructor",pathway:.instructor,title:"Instructor / Scenario Author",requirements:req([.leadershipInstruction,.documentation,.forensicDiagnostics,.electricalSafety],16,0.90),requiredPracticals:["prac-isolation"],requiredCapstones:["capstone-forensic"],examSections:[.practical,.diagnostics,.safety,.documentation,.oralDefense],minimumOverall:0.90)
        ]
    }
}

public struct EERev59CareerScaleTraining: Sendable, Codable {
    public var base=EERev58UltraTrainingAcademy(); public var catalog=EETrainingCatalog59(); public var practicalGenerator=EEPracticalGenerator59(); public var instructor=EEInstructorDashboard59(); public var author=EEInstructorScenarioAuthor59()
    public init(){}
}
