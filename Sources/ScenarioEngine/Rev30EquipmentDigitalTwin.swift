import Foundation

public enum TwinLifecycleState: String, Sendable, Codable { case installed, commissioned, operating, degraded, failed, maintenance, calibrationRequired, recommissioning, retired }
public enum TwinEventKind: String, Sendable, Codable { case install, configure, commission, operate, alarm, diagnostic, maintenance, calibrate, repair, recommission }
public struct TwinEvent: Sendable, Codable, Hashable { public var sequence:Int; public var kind:TwinEventKind; public var summary:String; public var evidence:String; public init(_ sequence:Int,_ kind:TwinEventKind,_ summary:String,evidence:String=""){self.sequence=sequence;self.kind=kind;self.summary=summary;self.evidence=evidence} }
public struct EquipmentConfiguration: Sendable, Codable, Hashable { public var values:[String:Double]; public var text:[String:String]; public init(values:[String:Double]=[:],text:[String:String]=[:]){self.values=values;self.text=text} }
public struct CalibrationRecord: Sendable, Codable, Hashable { public var sequence:Int; public var kind:String; public var passed:Bool; public var reference:String; public init(sequence:Int,kind:String,passed:Bool,reference:String){self.sequence=sequence;self.kind=kind;self.passed=passed;self.reference=reference} }
public struct MaintenanceRecord: Sendable, Codable, Hashable { public var sequence:Int; public var action:String; public var completed:Bool; public var invalidatedCalibration:Bool; public init(sequence:Int,action:String,completed:Bool=true,invalidatedCalibration:Bool=false){self.sequence=sequence;self.action=action;self.completed=completed;self.invalidatedCalibration=invalidatedCalibration} }

public struct EquipmentDigitalTwin: Sendable, Codable {
    public var tag:String; public var definitionID:String; public var installedLocation:String; public var state:TwinLifecycleState = .installed
    public var configuration=EquipmentConfiguration(); public var events:[TwinEvent]=[]; public var calibrations:[CalibrationRecord]=[]; public var maintenance:[MaintenanceRecord]=[]
    public var latentDefects:[LatentWorkmanshipDefect]=[]; public var commissioning:CommissioningSheet?; public var hoursOperating:Double=0
    public init(tag:String,definitionID:String,installedLocation:String,commissioning:CommissioningSheet?=nil){self.tag=tag;self.definitionID=definitionID;self.installedLocation=installedLocation;self.commissioning=commissioning;record(.install,"Installed \(tag) at \(installedLocation)")}
    public mutating func record(_ kind:TwinEventKind,_ summary:String,evidence:String=""){events.append(.init(events.count+1,kind,summary,evidence:evidence))}
    public mutating func configure(values:[String:Double]=[:],text:[String:String]=[:]){for (k,v) in values{configuration.values[k]=v};for (k,v) in text{configuration.text[k]=v};record(.configure,"Configuration changed")}
    public mutating func addMaintenance(_ action:String,invalidatesCalibration:Bool=false){maintenance.append(.init(sequence:events.count+1,action:action,invalidatedCalibration:invalidatesCalibration));state = invalidatesCalibration ? .calibrationRequired : .maintenance;record(.maintenance,action)}
    public mutating func addCalibration(_ kind:String,passed:Bool,reference:String){calibrations.append(.init(sequence:events.count+1,kind:kind,passed:passed,reference:reference));record(.calibrate,kind,evidence:reference);if passed && state == .calibrationRequired{state = .recommissioning}}
    public mutating func operate(hours:Double,load:Double=0.5,temperatureC:Double=30,vibration:Double=0.2,moisture:Double=0.1){hoursOperating += max(0,hours);for i in latentDefects.indices{latentDefects[i].age(load:load,temperatureC:temperatureC,vibration:vibration,moisture:moisture,dtHours:hours)};if latentDefects.contains(where:{$0.revealed}){state = .degraded};record(.operate,"Operated \(hours) h")}
    public var revealedDefects:[LatentWorkmanshipDefect]{latentDefects.filter{$0.revealed}}
    public var readyForService:Bool { commissioning?.complete == true && state != .calibrationRequired && state != .failed && revealedDefects.isEmpty }
}

public enum HartValue: Sendable, Codable, Hashable { case number(Double,String), text(String), flag(Bool) }
public struct HartWorkspace: Sendable, Codable {
    public var tag:String; public var definitionID:String; public var values:[String:HartValue]; public var alerts:[String]
    public init(tag:String,definitionID:String,values:[String:HartValue],alerts:[String]=[]){self.tag=tag;self.definitionID=definitionID;self.values=values;self.alerts=alerts}
}
public enum HartWorkspaceFactory {
    public static func make(twin:EquipmentDigitalTwin, registry:IndustrialEquipmentRegistry)->HartWorkspace? {
        guard let d=registry[twin.definitionID], d.interfaces.contains(where:{$0.kind == .hart}) else { return nil }
        if d.kind == .positioner { return .init(tag:twin.tag,definitionID:d.id,values:["analogInput":.number(twin.configuration.values["analogInputMA"] ?? 12,"mA"),"travel":.number(twin.configuration.values["travelPercent"] ?? 0,"%"),"supplyPressure":.number(twin.configuration.values["supplyPSI"] ?? 0,"psi"),"calibrationRequired":.flag(twin.state == .calibrationRequired)]) }
        let unit = twin.configuration.text["unit"] ?? "EU"
        let values: [String: HartValue] = [
            "PV": .number(twin.configuration.values["pv"] ?? 0, unit),
            "LRV": .number(twin.configuration.values["LRV"] ?? 0, unit),
            "URV": .number(twin.configuration.values["URV"] ?? 100, unit),
            "damping": .number(twin.configuration.values["damping"] ?? 0, "s"),
            "loopCurrent": .number(twin.configuration.values["loopCurrentMA"] ?? 4, "mA")
        ]
        return .init(tag:twin.tag, definitionID:d.id, values:values)
    }
}

public struct ToolSessionEntry: Sendable, Codable, Hashable { public var sequence:Int; public var pointID:String; public var identity:String; public var evidence:FieldToolEvidence; public init(sequence:Int,pointID:String,identity:String,evidence:FieldToolEvidence){self.sequence=sequence;self.pointID=pointID;self.identity=identity;self.evidence=evidence} }
public struct GoldenToolSession: Sendable, Codable {
    public var tool:FieldTool; public var entries:[ToolSessionEntry]=[]
    public init(tool:FieldTool){self.tool=tool}
    public mutating func measure(_ point:PhysicalTestPoint)->FieldToolEvidence { let e=tool.use(on:point);entries.append(.init(sequence:entries.count+1,pointID:point.id,identity:point.identity,evidence:e));return e }
    public func highlightedObjects(in thread:SynchronizedGoldenThread)->[GoldenSurface:String]{guard let id=entries.last?.identity else{return [:]};return thread.highlight(identity:id)}
}

public struct CommissioningDossier: Sendable, Codable { public var tag:String; public var definitionID:String; public var complete:Bool; public var evidence:[String]; public var maintenance:[String]; public var calibrations:[String]; public var eventCount:Int }
public enum DossierFactory { public static func make(_ t:EquipmentDigitalTwin)->CommissioningDossier { .init(tag:t.tag,definitionID:t.definitionID,complete:t.commissioning?.complete == true,evidence:t.commissioning?.checks.compactMap{$0.evidence.isEmpty ? nil : "\($0.id): \($0.evidence)"} ?? [],maintenance:t.maintenance.map{$0.action},calibrations:t.calibrations.map{"\($0.kind): \($0.passed ? "PASS":"FAIL") [\($0.reference)]"},eventCount:t.events.count) } }

public struct Rev30DigitalTwinPlant: Sendable, Codable {
    public var registry=Rev29EquipmentFactory.registry(); public var golden=SynchronizedGoldenThread.pit401(); public var pit:EquipmentDigitalTwin; public var dvc:EquipmentDigitalTwin
    public init(){var sheet=Rev28TrainingCell().sheet;for c in sheet.checks{sheet.record(c.id,result:.pass,evidence:"Rev30 verified")};pit = .init(tag:"PIT-401",definitionID:"PIT-GENERIC",installedLocation:"Separator discharge",commissioning:sheet);pit.configure(values:["LRV":0,"URV":300,"pv":150,"loopCurrentMA":12,"damping":1],text:["unit":"psi"]);pit.state = .operating;dvc = .init(tag:"DVC-201",definitionID:"DVC-GENERIC",installedLocation:"Recycle valve");dvc.configure(values:["analogInputMA":12,"travelPercent":50,"supplyPSI":80]);dvc.state = .operating}
}
