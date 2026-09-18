import Foundation

// Rev23 — Physical Loop Database + industrial control-panel architecture.
// Educational simulation. Layout rules are configurable engineering heuristics, not code compliance declarations.
public enum PanelZoneKind: String, Sendable, Codable { case incomingPower, motorPower, drivePower, controlPower, plcIO, safety, analogMarshalling, intrinsicSafety, network, burnerManagement, terminals, spare }
public struct PanelRect: Sendable, Codable, Hashable { public var x:Double; public var y:Double; public var w:Double; public var h:Double; public init(_ x:Double,_ y:Double,_ w:Double,_ h:Double){self.x=x;self.y=y;self.w=w;self.h=h}; public func intersects(_ b:PanelRect)->Bool{x < b.x+b.w && x+w>b.x && y<b.y+b.h && y+h>b.y} }
public enum PanelComponentKind: String, Sendable, Codable { case mainDisconnect, breaker, fuse, surgeProtection, powerSupply24V, ups, plc, remoteIO, mx5, safetyRelay, ethernetSwitch, canGateway, rs485Gateway, vfd, contactor, overload, interposingRelay, intrinsicSafetyBarrier, signalConditioner, terminalBlock, groundBar, shieldBar, profireBMS, ignitionInterface, hmi, thermostat, fan, heater, convenienceOutlet }
public struct PanelComponent: Sendable, Codable, Hashable { public var tag:String; public var kind:PanelComponentKind; public var zone:PanelZoneKind; public var rect:PanelRect; public var heatWatts:Double; public var voltageClass:Int; public init(tag:String,kind:PanelComponentKind,zone:PanelZoneKind,rect:PanelRect,heatWatts:Double=0,voltageClass:Int=24){self.tag=tag;self.kind=kind;self.zone=zone;self.rect=rect;self.heatWatts=heatWatts;self.voltageClass=voltageClass} }
public struct PanelArchitecture: Sendable, Codable { public var widthMM:Double; public var heightMM:Double; public var components:[PanelComponent]; public init(widthMM:Double=1000,heightMM:Double=1800,components:[PanelComponent]=[]){self.widthMM=widthMM;self.heightMM=heightMM;self.components=components}
    public var audit:[String] { var a:[String]=[]; for i in components.indices { let c=components[i]; if c.rect.x<0 || c.rect.y<0 || c.rect.x+c.rect.w>widthMM || c.rect.y+c.rect.h>heightMM {a.append("\(c.tag) outside enclosure")}; for j in components.indices where j>i { if c.rect.intersects(components[j].rect){a.append("\(c.tag) overlaps \(components[j].tag)")} } }; let power=components.filter{$0.zone == .incomingPower || $0.zone == .drivePower || $0.zone == .motorPower}; let analog=components.filter{$0.zone == .analogMarshalling || $0.zone == .intrinsicSafety}; for p in power { for s in analog { let dx=max(0,max(p.rect.x-s.rect.x-s.rect.w,s.rect.x-p.rect.x-p.rect.w)); let dy=max(0,max(p.rect.y-s.rect.y-s.rect.h,s.rect.y-p.rect.y-p.rect.h)); if hypot(dx,dy)<100 {a.append("power/sensitive-signal separation low: \(p.tag) / \(s.tag)")} } }; if components.reduce(0,{$0+$1.heatWatts}) > 600 {a.append("panel heat load requires thermal review")}; return a }
}
public struct PanelTemplateFactory {
    public static func compressorUnitControl() -> PanelArchitecture { PanelArchitecture(components:[
        .init(tag:"DS-1",kind:.mainDisconnect,zone:.incomingPower,rect:.init(40,60,180,240),heatWatts:5,voltageClass:480),
        .init(tag:"PS-24",kind:.powerSupply24V,zone:.controlPower,rect:.init(280,70,120,140),heatWatts:35),
        .init(tag:"PLC-1",kind:.plc,zone:.plcIO,rect:.init(470,70,300,180),heatWatts:45),
        .init(tag:"NET-1",kind:.ethernetSwitch,zone:.network,rect:.init(800,70,120,100),heatWatts:12),
        .init(tag:"MX5-1",kind:.mx5,zone:.plcIO,rect:.init(470,310,220,160),heatWatts:20),
        .init(tag:"IS-1",kind:.intrinsicSafetyBarrier,zone:.intrinsicSafety,rect:.init(760,310,180,220),heatWatts:18),
        .init(tag:"TB-FIELD",kind:.terminalBlock,zone:.terminals,rect:.init(80,1450,820,100)),
        .init(tag:"PE",kind:.groundBar,zone:.terminals,rect:.init(80,1620,820,50)) ]) }
    public static func burnerPanel() -> PanelArchitecture { PanelArchitecture(widthMM:800,heightMM:1400,components:[
        .init(tag:"DS-BMS",kind:.mainDisconnect,zone:.incomingPower,rect:.init(40,60,140,200),voltageClass:120),
        .init(tag:"PS-BMS",kind:.powerSupply24V,zone:.controlPower,rect:.init(240,70,120,130),heatWatts:25),
        .init(tag:"BMS-1",kind:.profireBMS,zone:.burnerManagement,rect:.init(430,60,260,220),heatWatts:25),
        .init(tag:"K-IGN",kind:.ignitionInterface,zone:.burnerManagement,rect:.init(430,350,160,140),heatWatts:20),
        .init(tag:"K-PILOT",kind:.interposingRelay,zone:.burnerManagement,rect:.init(240,350,100,80)),
        .init(tag:"TB-BURNER",kind:.terminalBlock,zone:.terminals,rect:.init(70,1100,650,90)),
        .init(tag:"PE-BURNER",kind:.groundBar,zone:.terminals,rect:.init(70,1240,650,40)) ]) }
    public static func marshallingPanel() -> PanelArchitecture { PanelArchitecture(widthMM:1000,heightMM:1800,components:[
        .init(tag:"PS-MAR",kind:.powerSupply24V,zone:.controlPower,rect:.init(60,60,120,140),heatWatts:30),
        .init(tag:"IS-A",kind:.intrinsicSafetyBarrier,zone:.intrinsicSafety,rect:.init(260,60,280,500),heatWatts:60),
        .init(tag:"ISO-A",kind:.signalConditioner,zone:.analogMarshalling,rect:.init(620,60,280,500),heatWatts:60),
        .init(tag:"TB-FIELD",kind:.terminalBlock,zone:.terminals,rect:.init(80,1250,820,120)),
        .init(tag:"TB-SYSTEM",kind:.terminalBlock,zone:.terminals,rect:.init(80,1430,820,120)),
        .init(tag:"SHIELD",kind:.shieldBar,zone:.terminals,rect:.init(80,1600,820,40)) ]) }
}

public enum LoopNodeKind:String,Sendable,Codable { case processTap, fieldDeviceTerminal, cableCore, junctionTerminal, marshallingTerminal, barrier, conditioner, ioTerminal, ioChannel, controllerTag, networkNode, hmiTag, ground, shield }
public struct LoopNode:Sendable,Codable,Hashable { public var id:String; public var kind:LoopNodeKind; public var drawing:String?; public init(_ id:String,_ kind:LoopNodeKind,drawing:String?=nil){self.id=id;self.kind=kind;self.drawing=drawing} }
public struct LoopEdge:Sendable,Codable,Hashable { public var from:String; public var to:String; public var wireNumber:String?; public var cableTag:String?; public init(_ from:String,_ to:String,wireNumber:String?=nil,cableTag:String?=nil){self.from=from;self.to=to;self.wireNumber=wireNumber;self.cableTag=cableTag} }
public struct PhysicalLoopDatabase:Sendable,Codable { public var nodes:[String:LoopNode]=[:]; public var edges:[LoopEdge]=[]; public init(){}; public mutating func add(_ n:LoopNode){nodes[n.id]=n}; public mutating func connect(_ a:String,_ b:String,wire:String?=nil,cable:String?=nil){edges.append(.init(a,b,wireNumber:wire,cableTag:cable))}
    public func trace(from start:String)->[LoopNode]{ guard nodes[start] != nil else{return []}; var q=[start],seen:Set<String>=[],out:[LoopNode]=[]; while !q.isEmpty {let x=q.removeFirst(); guard !seen.contains(x) else{continue};seen.insert(x);if let n=nodes[x]{out.append(n)};for e in edges {if e.from==x && !seen.contains(e.to){q.append(e.to)};if e.to==x && !seen.contains(e.from){q.append(e.from)}}};return out }
    public var duplicateWireNumbers:[String]{ let xs=edges.compactMap{$0.wireNumber}; return Dictionary(grouping:xs,by:{$0}).filter{$0.value.count>1}.keys.sorted() }
}
public struct TypicalLoopFactory { public static func pit401()->PhysicalLoopDatabase { var d=PhysicalLoopDatabase(); [LoopNode("PIT-401:+",.fieldDeviceTerminal,drawing:"IL-401"),LoopNode("CBL-401:1",.cableCore),LoopNode("JB-4:12",.junctionTerminal,drawing:"WD-04"),LoopNode("MAR-1:17",.marshallingTerminal),LoopNode("IS-17:IN+",.barrier),LoopNode("IS-17:OUT+",.barrier),LoopNode("MX5-02:AI3+",.ioTerminal),LoopNode("MX5-02:AI3",.ioChannel),LoopNode("PLC:PIT401_PV",.controllerTag),LoopNode("HMI:PIT401",.hmiTag)].forEach{d.add($0)}; let ids=["PIT-401:+","CBL-401:1","JB-4:12","MAR-1:17","IS-17:IN+","IS-17:OUT+","MX5-02:AI3+","MX5-02:AI3","PLC:PIT401_PV","HMI:PIT401"]; for i in 0..<(ids.count-1){d.connect(ids[i],ids[i+1],wire:i<4 ? "401+":nil,cable:i<2 ? "CBL-401":nil)}; return d } }
