import Foundation

// MARK: - Rev60 Six-Pathway Professional Academy
// Original competency architecture. External training publishers and standards are provenance only.

public enum EEProfessionalPath60: String, CaseIterable, Sendable, Codable { case apprenticeElectrician, journeymanElectrician, masterElectrician, ieTechnician, controlsTechnician, commissioningSpecialist }
public enum EEProfessionalBand60: Int, CaseIterable, Sendable, Codable { case foundation = 1, developing, fieldReady, independent, advanced, lead, mastery, capstone }
public enum EEStationKind60: String, CaseIterable, Sendable, Codable { case theory, calculation, codeNavigation, drawingTrace, physicalBuild, inspection, instrumentPractical, commissioning, troubleshooting, repairVerification, documentation, oralDefense, transfer, forensic }
public enum EECareerPerspective60: String, CaseIterable, Sendable, Codable { case install, inspect, calculate, designReview, measure, calibrate, program, commission, diagnose, reconstruct, lead, teach }

public struct EEPathwayTopic60: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var path:EEProfessionalPath60; public var band:EEProfessionalBand60; public var title:String
    public var domains:[EETrainingDomain57]; public var perspectives:[EECareerPerspective60]; public var stations:[EEStationKind60]
    public var prerequisites:[String]; public var minimumEvidence:Int; public var safetyGates:[EESafetyGate57]; public var references:[String]
}
public struct EEPracticalStation60: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var path:EEProfessionalPath60; public var title:String; public var station:EEStationKind60; public var assetClass:String
    public var allowedInstruments:[String]; public var documentSet:[String]; public var faultFamilies:[String]; public var requiredEvidence:[String]
    public var safetyGates:[EESafetyGate57]; public var timeBudgetMinutes:Int; public var variants:Int
}
public struct EECapstonePhase60: Identifiable, Sendable, Codable, Equatable { public var id:String; public var title:String; public var objectives:[String]; public var requiredEvidence:Int; public var safetyCritical:Bool }
public struct EECareerCapstone60: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var path:EEProfessionalPath60; public var title:String; public var phases:[EECapstonePhase60]; public var estimatedMinutes:Int; public var minimumScore:Double
}
public struct EEPathwayTranscript60: Sendable, Codable, Equatable {
    public var path:EEProfessionalPath60; public var topicScores:[String:Double]=[:]; public var practicalScores:[String:Double]=[:]; public var capstoneScores:[String:Double]=[:]; public var unsafeEvents:Int=0
    public init(path:EEProfessionalPath60){self.path=path}
    public var average:Double { let v=Array(topicScores.values)+Array(practicalScores.values)+Array(capstoneScores.values); return v.isEmpty ? 0 : v.reduce(0,+)/Double(v.count) }
    public func ready(for band:EEProfessionalBand60, catalog:EEProfessionalAcademyCatalog60)->Bool { guard unsafeEvents == 0 else{return false}; let ids=catalog.topics.filter{$0.path==path && $0.band.rawValue <= band.rawValue}.map(\.id); guard !ids.isEmpty else{return false}; return ids.allSatisfy{(topicScores[$0] ?? 0) >= 0.75} }
}
public struct EECrossCareerScenario60: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var asset:String; public var principle:String; public var perspectives:[EEProfessionalPath60:String]
}

public struct EEProfessionalAcademyCatalog60: Sendable, Codable, Equatable {
    public var topics:[EEPathwayTopic60]=[]; public var practicals:[EEPracticalStation60]=[]; public var capstones:[EECareerCapstone60]=[]; public var crossCareer:[EECrossCareerScenario60]=[]
    public init(){buildTopics();buildPracticals();buildCapstones();buildCrossCareer()}
    mutating func buildTopics(){
        let map:[EEProfessionalPath60:[String]] = [
            .apprenticeElectrician:["Tools, Materials & Workmanship","Electrical Math & Formulas","DC Circuit Fundamentals","AC Fundamentals","Print & Symbol Reading","NEC Navigation Foundations","Conductors & Ampacity Concepts","Boxes, Raceways & Cable Systems","Grounding & Bonding Foundations","Branch Circuits","Transformers Foundations","Three-Phase Foundations","Motors & Contactors","Three-Wire Motor Control","Test Instruments","Safe Isolation & Verification","Installation Inspection","Basic Troubleshooting","Repair & Proof","Job Documentation"],
            .journeymanElectrician:["Advanced Code Navigation","Load & Feeder Calculations","Services & Distribution","Conductor Sizing & Protection","Voltage Drop","Grounding & Bonding Diagnostics","Transformers","Generators & Standby Systems","Three-Phase Distribution","Motors, Controllers & MCCs","Motor Calculations","Overcurrent Protection","Power Quality Foundations","Wiring Methods Field Decisions","Special Occupancy Research","Hazardous Location Foundations","Renovation & Existing Conditions","Advanced Print Reading","Fault Isolation","Commissioning & Turnover"],
            .masterElectrician:["System Load Architecture","Service & Feeder Design Review","Transformer Application","Motor-System Design Review","Fault-Current Reasoning","Protection & Coordination Concepts","Grounding/Bonding Design Review","Power Quality & Harmonics","Emergency & Standby Architecture","Complex Code Research","Special Occupancies & Equipment","Installation Deficiency Review","Design Error Diagnosis","Estimating & Planning Concepts","Commissioning Acceptance","Root-Cause Review","Leadership & Supervision","Technical Documentation","Teach-Back & Mentoring","Master Design Defense"],
            .ieTechnician:["P&ID and Loop-Sheet Mastery","4-20 mA Loop Physics","Pressure & DP","Flow Measurement","Level Measurement","Temperature/RTD/Thermocouple","Switches & Discrete Instruments","Junction Boxes, Cable & Shielding","Barriers & Isolators","HART-Style Diagnostics","Calibration As-Found/As-Left","Control Valves & Positioners","Instrument Air","PLC I/O & Scaling","Process Dynamics","PID Fundamentals","MCC/VFD Interface","Historian & SOE","Intermittent Instrument Faults","Process Forensics"],
            .controlsTechnician:["Relay Logic to PLC","PLC Scan & Memory","Discrete I/O","Analog I/O & Scaling","Timers/Counters","Sequencing & State Machines","Permissives & Interlocks","PID Control","VFD Integration","Remote I/O","Industrial Ethernet","Serial Communications","HMI Design & Diagnostics","Alarm Rationalization Foundations","Historian & SOE","Managed Network Diagnostics","Device Replacement & Recommissioning","Configuration/Version Awareness","Control-System Forensics","Embedded/CAN Integration"],
            .commissioningSpecialist:["Document Readiness","Equipment Identity & Tagging","Construction Verification","Punch Management","Cable & Termination Inspection","Continuity/Insulation Concepts","Instrument Calibration Verification","Loop Checks","I/O Checkout","Motor Rotation & Bump Tests","MCC/VFD Checkout","Interlock & Permissive Testing","Cause-and-Effect Verification","Sequence Testing","Alarm Verification","Network Readiness","Energization Planning","Startup Support","Performance Testing","Turnover & As-Left Package"]
        ]
        topics=[]
        for path in EEProfessionalPath60.allCases { for (i,title) in (map[path] ?? []).enumerated() { let band=EEProfessionalBand60(rawValue:min(8,1+i/3))!; let domains=domainsFor(path:path,index:i); let refs=path == .apprenticeElectrician || path == .journeymanElectrician || path == .masterElectrician ? ["MH-APPRENTICESHIP","MH-NEC","MH-CALC","OSHA-1910.332","OSHA-1910.333"] : ["OSHA-1910.332","OSHA-1910.333"]; topics.append(.init(id:"60-\(path.rawValue)-\(i)",path:path,band:band,title:title,domains:domains,perspectives:perspectivesFor(path),stations:stationsFor(path),prerequisites:i==0 ? [] : ["60-\(path.rawValue)-\(i-1)"],minimumEvidence:max(1,band.rawValue/2),safetyGates:band.rawValue >= 3 ? [.hazardRecognition,.energySourceIdentification,.verifyDeenergized] : [.hazardRecognition],references:refs)) } }
    }
    func domainsFor(path:EEProfessionalPath60,index:Int)->[EETrainingDomain57]{ switch path { case .apprenticeElectrician:return [.electricalTheory,.dcCircuits,.acCircuits,.wiringMethods,.electricalSafety,.testInstruments]; case .journeymanElectrician:return [.calculations,.codeNavigation,.groundingBonding,.overcurrentProtection,.motorControls,.troubleshooting]; case .masterElectrician:return [.calculations,.codeNavigation,.industrialPower,.documentation,.leadershipInstruction,.engineeringAnalysis]; case .ieTechnician:return [.instrumentation,.calibration,.processControl,.plc,.drives,.troubleshooting]; case .controlsTechnician:return [.plc,.hmiScada,.industrialNetworks,.processControl,.embedded,.forensicDiagnostics]; case .commissioningSpecialist:return [.commissioning,.documentation,.testInstruments,.instrumentation,.motorControls,.plc] } }
    func perspectivesFor(_ p:EEProfessionalPath60)->[EECareerPerspective60]{ switch p {case .apprenticeElectrician:return [.install,.measure,.diagnose];case .journeymanElectrician:return [.install,.inspect,.calculate,.diagnose,.commission];case .masterElectrician:return [.calculate,.designReview,.inspect,.lead,.teach];case .ieTechnician:return [.measure,.calibrate,.commission,.diagnose,.reconstruct];case .controlsTechnician:return [.program,.commission,.diagnose,.reconstruct];case .commissioningSpecialist:return [.inspect,.measure,.calibrate,.commission,.lead]} }
    func stationsFor(_ p:EEProfessionalPath60)->[EEStationKind60]{ [.theory,.calculation,.drawingTrace,.physicalBuild,.instrumentPractical,.commissioning,.troubleshooting,.repairVerification,.documentation,.oralDefense,.transfer] + (p == .masterElectrician || p == .ieTechnician || p == .controlsTechnician ? [.forensic] : []) }
    mutating func buildPracticals(){ practicals=[]; let instruments=["DMM","Clamp Meter","Megohmmeter","Oscilloscope","Loop Calibrator","HART Communicator","Thermal Camera","Vibration Analyzer","Network Analyzer","CAN Analyzer"]; for p in EEProfessionalPath60.allCases { for i in 0..<12 { let inst=Array(instruments.prefix(min(instruments.count,2+i/2))); practicals.append(.init(id:"60-prac-\(p.rawValue)-\(i)",path:p,title:"\(p.rawValue) Practical Station \(i+1)",station:i < 3 ? .instrumentPractical : (i < 7 ? .troubleshooting : .commissioning),assetClass:["branch circuit","motor starter","MCC bucket","instrument loop","PLC panel","VFD system","networked machine"][i % 7],allowedInstruments:inst,documentSet:["one-line","elementary","wiring diagram","loop sheet","I/O list"],faultFamilies:["open","highResistance","miswire","intermittent","drift","misconfiguration","supplySag"],requiredEvidence:["simulation-backed measurement","physical test point","root-cause chain","post-repair verification"],safetyGates:[.hazardRecognition,.energySourceIdentification,.isolationPlan,.verifyDeenergized,.storedEnergy,.restoration],timeBudgetMinutes:30+i*10,variants:64)) } } }
    mutating func buildCapstones() {
        capstones = EEProfessionalPath60.allCases.map { path in
            let names = ["Plan","Research/Drawings","Safety & Energy","Inspect","Calculate/Predict","Measure","Diagnose/Execute","Repair/Correct","Commission","Prove","Document","Oral Defense"]
            let phases = names.enumerated().map { pair in
                EECapstonePhase60(id:"60-cap-\(path.rawValue)-\(pair.offset)", title:pair.element, objectives:["defensible evidence","physical truth","professional documentation"], requiredEvidence:max(1,pair.offset/2), safetyCritical:[2,6,8].contains(pair.offset))
            }
            return EECareerCapstone60(id:"60-capstone-\(path.rawValue)", path:path, title:"\(path.rawValue) Professional Capstone", phases:phases, estimatedMinutes:path == .apprenticeElectrician ? 180 : 360, minimumScore:path == .apprenticeElectrician ? 0.78 : 0.85)
        }
    }
    mutating func buildCrossCareer() {
        crossCareer = [
            EECrossCareerScenario60(id:"60-cross-starter", asset:"Three-wire motor starter", principle:"control power, seal-in, overload, contactor and process permissive", perspectives:[.apprenticeElectrician:"wire and prove basic starter", .journeymanElectrician:"install, calculate and diagnose starter/MCC", .masterElectrician:"review design, protection and deficiency", .ieTechnician:"prove field/process permissive and instrumentation", .controlsTechnician:"trace PLC permissive and I/O truth", .commissioningSpecialist:"verify complete cause/effect and turnover"]),
            EECrossCareerScenario60(id:"60-cross-loop", asset:"4-20 mA process loop", principle:"source, burden, scaling, grounding, calibration and control", perspectives:[.apprenticeElectrician:"identify conductors and safely trace wiring", .journeymanElectrician:"verify installation and power distribution", .masterElectrician:"review supply/protection/grounding architecture", .ieTechnician:"calibrate and diagnose full loop", .controlsTechnician:"prove AI scaling, logic, HMI and historian", .commissioningSpecialist:"execute loop check and as-left turnover"])
        ]
    }
}

public struct EERev60SixPathwayAcademy: Sendable, Codable { public var base=EERev59CareerScaleTraining(); public var academy=EEProfessionalAcademyCatalog60(); public init(){} }
