import Foundation
import ElectricalCore
import CircuitMNA

// Rev70: end-to-end I&E / Controls qualification jobs built on the unified Rev69 facility.
public enum EEQualificationDiscipline70: String, Sendable, Codable { case instrumentationElectrical, controls }
public enum EEQualificationPhase70: String, Sendable, Codable, CaseIterable {
    case briefing, documentReview, safetyPlan, asFound, fieldInspection, measurementPlan, evidenceCapture,
         hypothesis, discriminatingTest, firstDivergence, rootCause, repair, calibrationConfiguration,
         recommission, functionalProof, asLeft, documentation, oralDefense, complete
}
public enum EEFaultLayer70: String, Sendable, Codable, CaseIterable {
    case processConnection, sensor, transmitterConfiguration, copper, loopPower, analogInput, scaling,
         plcLogic, network, hmi, historian, finalControl
}
public struct EEJobDocument70: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var title:String; public var identities:[String]; public var available:Bool
    public init(id:String,title:String,identities:[String],available:Bool=true){self.id=id;self.title=title;self.identities=identities;self.available=available}
}
public struct EEJobEvidence70: Identifiable, Sendable, Codable, Equatable {
    public var id:Int; public var time:Double; public var identity:String; public var layer:EEFaultLayer70; public var observation:String; public var value:Double?; public var unit:String?; public var provenance:String
}
public struct EEHypothesis70: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var layer:EEFaultLayer70; public var statement:String; public var confidence:Double; public var contradicted:Bool
}
public struct EEQualificationJob70: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var title:String; public var discipline:EEQualificationDiscipline70; public var complaint:String
    public var documents:[EEJobDocument70]; public var hiddenFault:EEFaultLayer70; public var hiddenFaultDetail:String
    public var requiredIdentities:[String]; public var allowedInstruments:[String]; public var seed:UInt64
    public init(id:String,title:String,discipline:EEQualificationDiscipline70,complaint:String,documents:[EEJobDocument70],hiddenFault:EEFaultLayer70,hiddenFaultDetail:String,requiredIdentities:[String],allowedInstruments:[String],seed:UInt64){self.id=id;self.title=title;self.discipline=discipline;self.complaint=complaint;self.documents=documents;self.hiddenFault=hiddenFault;self.hiddenFaultDetail=hiddenFaultDetail;self.requiredIdentities=requiredIdentities;self.allowedInstruments=allowedInstruments;self.seed=seed}
}
public enum EEQualificationCatalog70 {
    public static let ieIntermittentPressure = EEQualificationJob70(
        id:"IE-70-001", title:"Intermittent Discharge Pressure Divergence", discipline:.instrumentationElectrical,
        complaint:"Local pressure and HMI intermittently disagree; two unexplained recycle events occurred overnight.",
        documents:[.init(id:"P&ID-201",title:"Compression P&ID",identities:["PIT-204"]),.init(id:"LOOP-204",title:"PIT-204 Loop Sheet",identities:["PIT-204","JB-204:12","AI-3"]),.init(id:"TERM-204",title:"Terminal Plan",identities:["JB-204:12","TB1:12"]),.init(id:"IO-3",title:"PLC I/O List",identities:["AI-3"])],
        hiddenFault:.copper, hiddenFaultDetail:"Vibration-sensitive high-resistance termination at JB-204:12", requiredIdentities:["PIT-204","JB-204:12","AI-3"], allowedInstruments:["DMM","Loop Calibrator","HART-style Communicator","Historian","PLC Monitor"], seed:70001)
    public static let controlsScaling = EEQualificationJob70(
        id:"CTRL-70-001", title:"First-Divergence Controls Investigation", discipline:.controls,
        complaint:"Field transmitter appears healthy while PLC/HMI process value is incorrect and sequence permissive drops intermittently.",
        documents:[.init(id:"LOOP-301",title:"Analog Loop Sheet",identities:["PIT-301","AI-7"]),.init(id:"PLC-XREF",title:"PLC Cross Reference",identities:["AI-7","PIT301_PV"]),.init(id:"NET-1",title:"Network Map",identities:["PLC-1","HMI-1"])],
        hiddenFault:.scaling, hiddenFaultDetail:"Incorrect engineering-unit scaling after configuration change", requiredIdentities:["PIT-301","AI-7","PIT301_PV"], allowedInstruments:["DMM","Loop Calibrator","PLC Scan Microscope","Packet Capture","Historian"], seed:70002)
    public static var flagship:[EEQualificationJob70] { [ieIntermittentPressure, controlsScaling] }
}
public struct EEQualificationSession70: Sendable, Codable, Equatable {
    public var job:EEQualificationJob70; public var phase:EEQualificationPhase70 = .briefing; public var evidence:[EEJobEvidence70]=[]; public var hypotheses:[EEHypothesis70]=[]
    public var firstDivergence:EEFaultLayer70?; public var diagnosedRootCause:String?; public var repairRecorded=false; public var recommissioned=false; public var asLeftProven=false; public var documentationComplete=false; public var oralDefenseComplete=false; public var unsafeActions=0
    public init(job:EEQualificationJob70){self.job=job}
    public mutating func advance(to next:EEQualificationPhase70){ phase=next }
    public mutating func addEvidence(identity:String,layer:EEFaultLayer70,observation:String,value:Double?=nil,unit:String?=nil,time:Double,provenance:String){ evidence.append(.init(id:evidence.count,time:time,identity:identity,layer:layer,observation:observation,value:value,unit:unit,provenance:provenance)) }
    public mutating func addHypothesis(id:String,layer:EEFaultLayer70,statement:String,confidence:Double){ hypotheses.append(.init(id:id,layer:layer,statement:statement,confidence:min(1,max(0,confidence)),contradicted:false)) }
    public mutating func discriminate(using layer:EEFaultLayer70){ for i in hypotheses.indices where hypotheses[i].layer != layer { hypotheses[i].confidence *= 0.55 } }
    public mutating func recordRootCause(layer:EEFaultLayer70,detail:String){ firstDivergence=layer; diagnosedRootCause=detail; phase = .rootCause }
    public mutating func recordRepair(){repairRecorded=true;phase = .repair}
    public mutating func recordRecommission(){recommissioned=true;phase = .recommission}
    public mutating func recordAsLeft(){asLeftProven=true;phase = .asLeft}
    public mutating func recordDocumentation(){documentationComplete=true;phase = .documentation}
    public mutating func recordOralDefense(){oralDefenseComplete=true;phase = .oralDefense}
    public var complete:Bool { firstDivergence == job.hiddenFault && repairRecorded && recommissioned && asLeftProven && documentationComplete && oralDefenseComplete && unsafeActions == 0 && evidence.count >= 4 }
    public var score:Double { var s=0.0; s += min(0.25,Double(evidence.count)*0.04); if firstDivergence == job.hiddenFault{s += 0.25}; if repairRecorded{s += 0.10}; if recommissioned{s += 0.10}; if asLeftProven{s += 0.10}; if documentationComplete{s += 0.10}; if oralDefenseComplete{s += 0.10}; if unsafeActions > 0{s=min(s,0.49)}; return min(1,s) }
}
public struct EERev70EndToEndQualificationJobs: Sendable, Codable {
    public var facility=EERev69UnifiedIndustrialTrainingFacility(); public var active=EEQualificationSession70(job:EEQualificationCatalog70.ieIntermittentPressure)
    public init(){}
    public mutating func select(_ job:EEQualificationJob70){active=EEQualificationSession70(job:job)}
    public mutating func synchronizeIdentity(_ identity:String){facility.identities.selected=identity}
}
