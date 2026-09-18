import Foundation

public enum EEFacilityLevel80: String, Codable, CaseIterable, Sendable {
    case station="Station", building="Building", mccLineup="MCC Lineup", mccSection="MCC Section"
    case bucket="Bucket", plcCabinet="PLC Cabinet", terminal="Terminal", fieldCable="Field Cable"
    case fieldJB="Field JB", instrument="Instrument", actuator="Actuator", process="Process"
}

public enum EEDomain80: String, Codable, CaseIterable, Sendable {
    case power="Power", control="Control", instrumentation="Instrumentation"
    case network="Network", mechanical="Mechanical", process="Process"
}

public struct EEFacilityObject80: Identifiable, Codable, Hashable, Sendable {
    public let id:String
    public let name:String
    public let level:EEFacilityLevel80
    public let domain:EEDomain80
    public let parentID:String?
    public init(id:String,name:String,level:EEFacilityLevel80,domain:EEDomain80,parentID:String?=nil) {
        self.id=id; self.name=name; self.level=level; self.domain=domain; self.parentID=parentID
    }
}

public struct EECausalNode80: Identifiable, Codable, Hashable, Sendable {
    public let id:String
    public let label:String
    public let domain:EEDomain80
    public let expected:Bool
    public let observed:Bool
    public let identity:String
}

public struct EEFirstDivergence80: Codable, Equatable, Sendable {
    public let upstreamID:String?
    public let nodeID:String?
    public let explanation:String
}

public enum EEFacilityTwin80 {
    public static let objects:[EEFacilityObject80] = [
        .init(id:"STN-01",name:"Compression Station",level:.station,domain:.process),
        .init(id:"ER-01",name:"Electrical Room",level:.building,domain:.power,parentID:"STN-01"),
        .init(id:"MCC-2",name:"MCC-2 Lineup",level:.mccLineup,domain:.power,parentID:"ER-01"),
        .init(id:"MCC-2B",name:"MCC-2B Section",level:.mccSection,domain:.power,parentID:"MCC-2"),
        .init(id:"BKT-04",name:"Starter Bucket 04",level:.bucket,domain:.power,parentID:"MCC-2B"),
        .init(id:"PLC-1",name:"PLC Cabinet",level:.plcCabinet,domain:.control,parentID:"ER-01"),
        .init(id:"TB1:12",name:"Terminal TB1:12",level:.terminal,domain:.control,parentID:"PLC-1"),
        .init(id:"W-1207",name:"Field Cable W-1207",level:.fieldCable,domain:.control,parentID:"TB1:12"),
        .init(id:"JB-14",name:"Field Junction Box 14",level:.fieldJB,domain:.control,parentID:"W-1207"),
        .init(id:"PIT-101",name:"Pressure Transmitter",level:.instrument,domain:.instrumentation,parentID:"JB-14"),
        .init(id:"SOL-101",name:"Valve Solenoid",level:.actuator,domain:.control,parentID:"JB-14"),
        .init(id:"XV-101",name:"Shutdown Valve",level:.actuator,domain:.mechanical,parentID:"SOL-101"),
        .init(id:"PROC-101",name:"Compression Process",level:.process,domain:.process,parentID:"XV-101")
    ]

    public static func breadcrumb(for id:String)->[EEFacilityObject80] {
        var result:[EEFacilityObject80]=[]
        var current=objects.first{$0.id==id}
        var guardCount=0
        while let c=current, guardCount<20 {
            result.insert(c,at:0)
            current=c.parentID.flatMap{pid in objects.first{$0.id==pid}}
            guardCount += 1
        }
        return result
    }

    public static func causalChain(failure:EEFailureMode79)->[EECausalNode80] {
        let states:[Bool]
        switch failure {
        case .healthy: states=[true,true,true,true,true,true,true]
        case .highResistance: states=[true,true,true,false,false,false,false]
        case .openCircuit: states=[true,true,false,false,false,false,false]
        case .shortToGround: states=[true,true,false,false,false,false,false]
        }
        let defs:[(String,String,EEDomain80,String)] = [
            ("HMI-CMD","HMI Command",.control,"HMI"),
            ("PLC-DO4","PLC DO4",.control,"PLC DO4"),
            ("TB1:12","TB1:12",.control,"TB1:12"),
            ("SOL-101","Solenoid",.control,"SOL-101"),
            ("XV-101","Valve Motion",.mechanical,"XV-101"),
            ("PIT-101","Process Response",.instrumentation,"PIT-101"),
            ("HMI-PV","HMI Feedback",.process,"HMI")
        ]
        return defs.enumerated().map { i,d in
            .init(id:d.0,label:d.1,domain:d.2,expected:true,observed:states[i],identity:d.3)
        }
    }

    public static func firstDivergence(_ chain:[EECausalNode80])->EEFirstDivergence80 {
        guard let idx=chain.firstIndex(where:{$0.expected != $0.observed}) else {
            return .init(upstreamID:chain.last?.id,nodeID:nil,explanation:"No divergence. Command and response chain agree.")
        }
        let node=chain[idx]
        let up=idx>0 ? chain[idx-1].id:nil
        return .init(upstreamID:up,nodeID:node.id,
                     explanation:"Expected state is present upstream but not observed at \(node.label). Test this boundary before moving downstream.")
    }
}
