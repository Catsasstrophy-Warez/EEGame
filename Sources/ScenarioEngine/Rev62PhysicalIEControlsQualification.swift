import Foundation

// MARK: - Rev62 Physical I&E / Controls Qualification Layer
// Converts Rev61 curriculum metadata into deterministic, evidence-driven playable lab definitions.

public enum EELabDomain62: String, CaseIterable, Sendable, Codable { case transmitter, impulseSystem, loop, calibration, finalControl, plcRack, plcScan, sequence, drive, ethernet, serial, canBus, historian, integratedProcess }
public enum EETruthLayer62: String, CaseIterable, Sendable, Codable { case process, sensor, wiring, power, io, scaling, logic, network, presentation, history, mechanical }
public enum EELabAction62: String, CaseIterable, Sendable, Codable { case inspect, isolate, connect, configure, stimulate, measure, trend, forceForTraining, calibrate, stroke, trace, capture, repair, recommission, document }
public enum EEEvidenceType62: String, CaseIterable, Sendable, Codable { case visual, voltage, current, resistance, process, calibration, deviceStatus, rawIO, engineeringValue, logicState, packet, waveform, historian, soe, thermal, vibration, asLeft }

public struct EEPhysicalTestPoint62: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var assetID:String; public var label:String; public var truthLayer:EETruthLayer62; public var quantity:String; public var hazardous:Bool
    public init(id:String,assetID:String,label:String,truthLayer:EETruthLayer62,quantity:String,hazardous:Bool=false){self.id=id;self.assetID=assetID;self.label=label;self.truthLayer=truthLayer;self.quantity=quantity;self.hazardous=hazardous}
}
public struct EEPlayableLab62: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var profession:EEProfessionalPath60; public var domain:EELabDomain62; public var title:String; public var assetIDs:[String]
    public var testPoints:[EEPhysicalTestPoint62]; public var allowedActions:[EELabAction62]; public var requiredEvidence:[EEEvidenceType62]
    public var faultPool:[EEFaultClass61]; public var documents:[String]; public var safetyGates:[EESafetyGate57]; public var variantCount:Int; public var estimatedMinutes:Int
}
public struct EEDiagnosticObservation62: Identifiable, Sendable, Codable, Equatable { public var id:String; public var time:Double; public var testPointID:String; public var evidence:EEEvidenceType62; public var value:Double?; public var text:String; public var provenance:String; public init(id:String,time:Double,testPointID:String,evidence:EEEvidenceType62,value:Double?=nil,text:String,provenance:String){self.id=id;self.time=time;self.testPointID=testPointID;self.evidence=evidence;self.value=value;self.text=text;self.provenance=provenance} }
public struct EEQualificationSession62: Sendable, Codable, Equatable {
    public var labID:String; public var seed:UInt64; public var hiddenFault:EEFaultClass61; public var observations:[EEDiagnosticObservation62]=[]; public var unsafeActions:Int=0; public var repaired=false; public var recommissioned=false
    public mutating func record(_ o:EEDiagnosticObservation62){ observations.append(o) }
    public var evidenceKinds:Set<EEEvidenceType62>{ Set(observations.map(\.evidence)) }
    public func score(required:[EEEvidenceType62])->Double { guard unsafeActions == 0 else { return 0.25 }; let coverage=Double(Set(required).intersection(evidenceKinds).count)/Double(max(1,Set(required).count)); return min(1, coverage*0.7 + (repaired ? 0.15:0) + (recommissioned ? 0.15:0)) }
}

public struct EEPhysicalAcademy62: Sendable, Codable, Equatable {
    public var labs:[EEPlayableLab62]
    public init(){ labs=Self.catalog() }
    public static func catalog()->[EEPlayableLab62] {
        var out:[EEPlayableLab62]=[]
        let ie:[(EELabDomain62,String,[EEFaultClass61])] = [
            (.transmitter,"Pressure transmitter measurement chain",[.drift,.rangeMismatch,.sensorDamage]),(.impulseSystem,"DP manifold and impulse-line physics",[.impulseRestriction,.pluggedLine,.leakage]),(.loop,"4–20 mA compliance and burden",[.highResistance,.loopPowerSag,.polarity]),(.calibration,"As-found/as-left calibration bench",[.calibrationShift,.rangeMismatch,.drift]),(.finalControl,"Valve and positioner response/signature",[.stiction,.airFailure,.positionFeedback]),(.integratedProcess,"Process loop forensic qualification",[.intermittent,.scalingMismatch,.configurationDrift])]
        let ctl:[(EELabDomain62,String,[EEFaultClass61])] = [
            (.plcRack,"Physical PLC rack and channel wiring",[.ioModule,.channelConfig,.openCircuit]),(.plcScan,"PLC scan microscope",[.logicDefect,.timingRace,.permissiveMissing]),(.sequence,"State-machine and sequence recovery",[.logicDefect,.permissiveMissing,.configurationDrift]),(.drive,"VFD command/reference ownership",[.networkLoss,.configurationDrift,.ioModule]),(.ethernet,"Industrial Ethernet evidence lab",[.duplicateAddress,.packetLoss,.timeSync]),(.serial,"Serial physical/configuration lab",[.polarity,.configurationDrift,.packetLoss]),(.canBus,"CAN physical-layer qualification",[.termination,.shortCircuit,.groundFault]),(.historian,"PLC/SOE/Historian synchronized replay",[.historianGap,.timeSync,.configurationDrift]),(.integratedProcess,"Controls first-divergence board",[.scalingMismatch,.logicDefect,.networkLoss])]
        func make(_ p:EEProfessionalPath60,_ spec:(EELabDomain62,String,[EEFaultClass61]),_ i:Int)->EEPlayableLab62 {
            let a="62-\(p.rawValue)-asset-\(i)"; let points=[EEPhysicalTestPoint62(id:"\(a)-source",assetID:a,label:"Source / field side",truthLayer:.process,quantity:"physical truth"),EEPhysicalTestPoint62(id:"\(a)-term",assetID:a,label:"Terminal / conductor",truthLayer:.wiring,quantity:"electrical"),EEPhysicalTestPoint62(id:"\(a)-io",assetID:a,label:"Controller I/O",truthLayer:.io,quantity:"raw state"),EEPhysicalTestPoint62(id:"\(a)-logic",assetID:a,label:"Logic / scaled value",truthLayer:.logic,quantity:"computed state"),EEPhysicalTestPoint62(id:"\(a)-history",assetID:a,label:"Historian / SOE",truthLayer:.history,quantity:"time evidence")]
            return .init(id:"62-\(p.rawValue)-\(spec.0.rawValue)",profession:p,domain:spec.0,title:spec.1,assetIDs:[a],testPoints:points,allowedActions:EELabAction62.allCases,requiredEvidence:p == .ieTechnician ? [.visual,.process,.current,.rawIO,.engineeringValue,.asLeft] : [.visual,.rawIO,.logicState,.packet,.soe,.asLeft],faultPool:spec.2,documents:["P&ID / elementary","loop or wiring sheet","terminal plan","I/O list","configuration baseline","maintenance history"],safetyGates:[.hazardRecognition,.energySourceIdentification,.isolationPlan,.verifyDeenergized,.storedEnergy,.restoration],variantCount:256,estimatedMinutes:90+i*15)
        }
        for (i,s) in ie.enumerated(){ out.append(make(.ieTechnician,s,i)) }; for (i,s) in ctl.enumerated(){ out.append(make(.controlsTechnician,s,i)) }
        return out
    }
    public var deterministicVariants:Int { labs.reduce(0){$0+$1.variantCount} }
    public func labs(for p:EEProfessionalPath60)->[EEPlayableLab62]{ labs.filter{$0.profession==p} }
}

public struct EERev62PhysicalIEControlsQualification: Sendable, Codable { public var base=EERev61IEControlsDeepAcademy(); public var physical=EEPhysicalAcademy62(); public init(){} }
