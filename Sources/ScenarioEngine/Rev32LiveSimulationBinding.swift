import Foundation

// Rev32 — live simulation binding. One mutable plant state drives UI, tools, Golden Thread,
// equipment twins, construction repair, commissioning evidence, and diagnostic history.
// Educational simulation only; real field work follows site procedures and OEM documentation.

public enum LiveEvidenceKind: String, Sendable, Codable { case process, hart, electrical, io, logic, hmi, maintenance, construction, burner, operatorAction }
public struct LiveEvidence: Sendable, Codable, Hashable {
    public var sequence:Int; public var kind:LiveEvidenceKind; public var source:String; public var identity:String; public var value:Double?; public var unit:String; public var note:String
    public init(sequence:Int,kind:LiveEvidenceKind,source:String,identity:String,value:Double?=nil,unit:String="",note:String=""){self.sequence=sequence;self.kind=kind;self.source=source;self.identity=identity;self.value=value;self.unit=unit;self.note=note}
}
public struct LiveSignalStage: Sendable, Codable, Hashable { public var id:String; public var value:Double; public var unit:String; public var healthy:Bool; public var note:String; public init(_ id:String,_ value:Double,_ unit:String,healthy:Bool=true,note:String=""){self.id=id;self.value=value;self.unit=unit;self.healthy=healthy;self.note=note} }
public enum LiveAction: Sendable, Codable, Hashable {
    case openDisconnect, closeDisconnect, measure(String), sourceSystemSide(Double), setPITRange(Double,Double), repairTermination, torqueTermination(Double), replaceDVCRelay, calibrateDVC, verifyDVCTracking, acknowledgeBurnerEvent
}

public struct Rev32LivePlant: Sendable, Codable {
    public var twins = Rev30DigitalTwinPlant()
    public var disconnectOpen = false
    public var terminationTorqueNM = 0.32
    public var terminationRepaired = false
    public var sourceOverrideMA:Double? = nil
    public var evidence:[LiveEvidence] = []
    public var dvcTrackingVerified = false
    public var burnerEventAcknowledged = false
    public var selectedIdentity = "PIT401_SIGNAL"
    public var dmm = FieldTool(id:"DMM-1",kind:.dmm,mode:.measureCurrent)
    public init(){record(.process,"PROCESS","PIT401_SIGNAL",150.2,"psi","Separator discharge reference")}

    public var processPSI:Double { 150.2 }
    public var pitPV:Double { twins.pit.configuration.values["pv"] ?? 150 }
    public var pitLoopMA:Double {
        let lrv=twins.pit.configuration.values["LRV"] ?? 0, urv=twins.pit.configuration.values["URV"] ?? 300
        guard urv > lrv else{return 4}
        return min(20,max(4,4 + 16 * (pitPV-lrv)/(urv-lrv)))
    }
    public var fieldMA:Double { pitLoopMA }
    public var downstreamMA:Double {
        if disconnectOpen { return sourceOverrideMA ?? 0 }
        if let sourceOverrideMA { return sourceOverrideMA }
        return terminationRepaired ? fieldMA : max(0,fieldMA - 3.26)
    }
    public var aiPercent:Double { min(100,max(0,(downstreamMA-4)/16*100)) }
    public var plcPSI:Double { let lrv=twins.pit.configuration.values["LRV"] ?? 0, urv=twins.pit.configuration.values["URV"] ?? 300; return lrv + aiPercent/100*(urv-lrv) }
    public var stages:[LiveSignalStage] {[
        .init("Process",processPSI,"psi"), .init("PIT-401",pitLoopMA,"mA"), .init("CBL-401",fieldMA,"mA"), .init("JB-4:12",fieldMA,"mA"),
        .init("DISC-401",downstreamMA,"mA",healthy:abs(downstreamMA-fieldMA)<0.15,note:disconnectOpen ? "OPEN / isolated" : (terminationRepaired ? "Repaired" : "First divergence")),
        .init("ISO-17",downstreamMA,"mA",healthy:abs(downstreamMA-fieldMA)<0.15), .init("MX5-AI3",aiPercent,"%",healthy:abs(downstreamMA-fieldMA)<0.15),
        .init("PLC",plcPSI,"psi",healthy:abs(plcPSI-processPSI)<3), .init("HMI",plcPSI,"psi",healthy:abs(plcPSI-processPSI)<3)
    ]}
    public var firstDivergence:String? { stages.first(where:{!$0.healthy})?.id }
    public var highlighted:[GoldenSurface:String] { twins.golden.highlight(identity:selectedIdentity) }
    public var dvcReady:Bool { twins.dvc.state == .recommissioning && dvcTrackingVerified }

    public mutating func perform(_ action:LiveAction) {
        switch action {
        case .openDisconnect: disconnectOpen=true; sourceOverrideMA=nil; record(.operatorAction,"DISC-401","PIT401_SIGNAL",nil,"","Opened test/disconnect boundary")
        case .closeDisconnect: disconnectOpen=false; sourceOverrideMA=nil; record(.operatorAction,"DISC-401","PIT401_SIGNAL",nil,"","Closed test/disconnect boundary")
        case .measure(let point): measure(point)
        case .sourceSystemSide(let ma): sourceOverrideMA=ma; record(.electrical,"CAL-1","PIT401_SIGNAL",ma,"mA","Known current sourced on system side")
        case .setPITRange(let lrv,let urv): twins.pit.configure(values:["LRV":lrv,"URV":urv]);record(.hart,"PIT-401","PIT401_SIGNAL",nil,"","Range changed to \(lrv)…\(urv)")
        case .repairTermination: terminationRepaired=true;terminationTorqueNM=0.6;sourceOverrideMA=nil;twins.pit.record(.repair,"DISC-401/TB termination repaired",evidence:"workmanship restored");record(.maintenance,"DISC-401","PIT401_SIGNAL",nil,"","Termination repaired")
        case .torqueTermination(let nm): terminationTorqueNM=nm;terminationRepaired = (0.54...0.66).contains(nm);record(.construction,"DISC-401","PIT401_SIGNAL",nm,"N·m",terminationRepaired ? "Torque accepted" : "Torque outside modeled window")
        case .replaceDVCRelay: twins.dvc.addMaintenance("replace pneumatic relay",invalidatesCalibration:true);dvcTrackingVerified=false;record(.maintenance,"DVC-201","DVC201",nil,"","Relay replaced; calibration required")
        case .calibrateDVC: twins.dvc.addCalibration("travel calibration",passed:true,reference:"LIVE-CAL");record(.maintenance,"DVC-201","DVC201",nil,"","Travel calibration passed")
        case .verifyDVCTracking: dvcTrackingVerified=true;record(.maintenance,"DVC-201","DVC201",nil,"","Tracking functional proof passed")
        case .acknowledgeBurnerEvent: burnerEventAcknowledged=true;record(.burner,"BMS-201","BMS201",nil,"","Event acknowledged")
        }
    }
    mutating func measure(_ point:String){
        let v:Double
        switch point {case "PIT-401","CBL-401","JB-4:12":v=fieldMA;case "DISC-401","ISO-17":v=downstreamMA;default:v=downstreamMA}
        record(.electrical,"DMM-1",selectedIdentity,v,"mA","Measured at \(point)")
    }
    mutating func record(_ kind:LiveEvidenceKind,_ source:String,_ identity:String,_ value:Double?,_ unit:String,_ note:String){evidence.append(.init(sequence:evidence.count+1,kind:kind,source:source,identity:identity,value:value,unit:unit,note:note))}
}
