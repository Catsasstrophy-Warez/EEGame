import Foundation

public struct EESpatialTwinBinding81: Identifiable, Codable, Hashable, Sendable {
    public let id:String
    public let facilityID:String
    public let electricalNode:String?
    public let conductorID:String?
    public let schematicRef:String?
    public let parentID:String?
    public init(id:String,facilityID:String,electricalNode:String?=nil,conductorID:String?=nil,schematicRef:String?=nil,parentID:String?=nil) {
        self.id=id; self.facilityID=facilityID; self.electricalNode=electricalNode; self.conductorID=conductorID; self.schematicRef=schematicRef; self.parentID=parentID
    }
}

public enum EESpatialTwinManifest81 {
    public static let bindings:[EESpatialTwinBinding81] = [
        .init(id:"entity.mcc2b",facilityID:"MCC-2B",schematicRef:"E-104",parentID:"ER-01"),
        .init(id:"entity.plc1",facilityID:"PLC-1",schematicRef:"E-104",parentID:"MCC-2B"),
        .init(id:"entity.tb112",facilityID:"TB1:12",electricalNode:"TB1:12",conductorID:"W-1207",schematicRef:"E-104",parentID:"PLC-1"),
        .init(id:"entity.jb14",facilityID:"JB-14",conductorID:"W-1207",schematicRef:"E-104",parentID:"STN-01"),
        .init(id:"entity.pit101",facilityID:"PIT-101",electricalNode:"PIT-101",conductorID:"W-2011",schematicRef:"P&ID-101",parentID:"JB-14"),
        .init(id:"entity.xv101",facilityID:"XV-101",electricalNode:"SOL-101",conductorID:"W-1207",schematicRef:"P&ID-101",parentID:"STN-01")
    ]
    public static func binding(facilityID:String)->EESpatialTwinBinding81? { bindings.first{$0.facilityID==facilityID} }
    public static func validate()->[String] {
        var errors:[String]=[]
        let ids=bindings.map(\.id)
        if Set(ids).count != ids.count { errors.append("Duplicate spatial entity IDs") }
        for b in bindings where !EEFacilityTwin80.objects.contains(where:{$0.id==b.facilityID}) {
            errors.append("Unknown facility identity \(b.facilityID)")
        }
        return errors
    }
}
