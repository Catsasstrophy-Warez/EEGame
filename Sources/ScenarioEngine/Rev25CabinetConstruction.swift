import Foundation

// Rev25 — cabinet construction truth below the wire: cable cores, ferrules/lugs,
// terminal-strip hardware, jumpers, shield clamps, door bonding, duct occupancy,
// and enclosure environmental control. Educational simulation, not a compliance engine.

public enum TerminationHardware: String, Sendable, Codable { case bare, ferrule, ringLug, forkLug, pinTerminal }
public enum TerminationCondition: String, Sendable, Codable { case correct, loose, overtorqued, wrongSize, missing, corroded }
public struct WireEnd: Sendable, Codable, Hashable {
    public var wireNumber:String; public var hardware:TerminationHardware; public var condition:TerminationCondition
    public init(_ wireNumber:String, hardware:TerminationHardware = .ferrule, condition:TerminationCondition = .correct){self.wireNumber=wireNumber;self.hardware=hardware;self.condition=condition}
    public var addedResistanceOhms:Double { switch condition { case .correct: return 0.0005; case .loose:return 0.08; case .overtorqued:return 0.01; case .wrongSize:return 0.03; case .missing:return 0.02; case .corroded:return 0.12 } }
}

public struct TerminalStripPosition: Sendable, Codable, Hashable {
    public var terminal:SpatialTerminal; public var end:WireEnd?; public var fused:Bool; public var fuseOpen:Bool; public var disconnectOpen:Bool
    public init(terminal:SpatialTerminal,end:WireEnd?=nil,fused:Bool=false,fuseOpen:Bool=false,disconnectOpen:Bool=false){self.terminal=terminal;self.end=end;self.fused=fused;self.fuseOpen=fuseOpen;self.disconnectOpen=disconnectOpen}
    public var conductive:Bool { !(fused && fuseOpen) && !disconnectOpen }
}
public struct TerminalJumper: Sendable, Codable, Hashable { public var from:String; public var to:String; public var installed:Bool; public init(_ from:String,_ to:String,installed:Bool=true){self.from=from;self.to=to;self.installed=installed} }
public struct TerminalStripAssembly: Sendable, Codable {
    public var tag:String; public var positions:[String:TerminalStripPosition]=[:]; public var jumpers:[TerminalJumper]=[]; public var leftEndStop=true; public var rightEndStop=true
    public init(tag:String){self.tag=tag}
    public mutating func add(_ p:TerminalStripPosition){positions[p.terminal.id]=p}
    public func continuity(from:String)->Set<String>{ var seen:Set<String>=[], q=[from]; while let x=q.first {q.removeFirst(); guard seen.insert(x).inserted, let px=positions[x], px.conductive else{continue}; for j in jumpers where j.installed { let n = j.from==x ? j.to : (j.to==x ? j.from:nil); if let n, positions[n]?.conductive == true, !seen.contains(n){q.append(n)} } }; return seen }
    public var audit:[String]{ var a:[String]=[]; if !leftEndStop || !rightEndStop {a.append("terminal strip missing end stop: \(tag)")}; for p in positions.values {if let e=p.end, e.condition != .correct {a.append("termination issue: \(p.terminal.id) \(e.condition.rawValue)")}; if p.fused && p.fuseOpen {a.append("open terminal fuse: \(p.terminal.id)")}}; return a }
}

public struct ConstructionCableCore: Sendable, Codable, Hashable { public var number:String; public var wireNumber:String; public var landedTerminal:String?; public var spare:Bool; public init(number:String,wireNumber:String,landedTerminal:String?=nil,spare:Bool=false){self.number=number;self.wireNumber=wireNumber;self.landedTerminal=landedTerminal;self.spare=spare} }
public struct ShieldClamp: Sendable, Codable, Hashable { public var id:String; public var grounded:Bool; public var drainConnected:Bool; public init(id:String,grounded:Bool=true,drainConnected:Bool=true){self.id=id;self.grounded=grounded;self.drainConnected=drainConnected} }
public struct CableFanout: Sendable, Codable {
    public var cableTag:String; public var gland:CableGland; public var cores:[ConstructionCableCore]; public var shield:ShieldClamp?
    public init(cableTag:String,gland:CableGland,cores:[ConstructionCableCore],shield:ShieldClamp?=nil){self.cableTag=cableTag;self.gland=gland;self.cores=cores;self.shield=shield}
    public var audit:[String]{ var a:[String]=[]; if !gland.sealed {a.append("unsealed gland: \(gland.id)")}; let landed=cores.compactMap{$0.landedTerminal}; if Set(landed).count != landed.count {a.append("multiple cable cores landed on same terminal")}; for c in cores where !c.spare && c.landedTerminal == nil {a.append("unlanded active core: \(c.wireNumber)")}; if let s=shield, !s.drainConnected {a.append("shield drain open: \(s.id)")}; return a }
}

public struct DoorBond: Sendable, Codable, Hashable { public var installed=true; public var resistanceOhms=0.03; public var flexCycles=0; public init(){}; public mutating func cycle(){flexCycles += 1; if flexCycles > 100_000 { resistanceOhms += 0.00001 }}; public var healthy:Bool{installed && resistanceOhms < 0.1} }
public struct DoorHarness: Sendable, Codable { public var conductors:[SpatialWire]=[]; public var serviceLoopMM:Double=150; public var flexCycles=0; public init(){}; public mutating func cycle(){flexCycles += 1}; public var fatigueRisk:Bool{serviceLoopMM < 75 || flexCycles > 250_000} }

public struct EnclosureClimate: Sendable, Codable {
    public var ambientC=25.0; public var internalC=25.0; public var humidityPercent=45.0; public var heaterOn=false; public var fanOn=false; public var thermostatFanOnC=35.0; public var heaterOnBelowC=5.0
    public init(){}
    public mutating func step(heatWatts:Double,dt:Double){heaterOn = internalC < heaterOnBelowC; fanOn = internalC > thermostatFanOnC; let heating=(heatWatts + (heaterOn ? 80:0))*0.00012*dt; let cooling=(internalC-ambientC)*(fanOn ? 0.02:0.004)*dt; internalC += heating-cooling}
    public var condensationRisk:Bool{humidityPercent > 85 && internalC < ambientC + 3}
}

public struct ConstructionCabinet: Sendable, Codable {
    public var cabinet:SpatialCabinet; public var strips:[TerminalStripAssembly]=[]; public var fanouts:[CableFanout]=[]; public var doorBond=DoorBond(); public var doorHarness=DoorHarness(); public var climate=EnclosureClimate()
    public init(cabinet:SpatialCabinet){self.cabinet=cabinet}
    public mutating func recalculateDuctFill(){ for i in cabinet.ducts.indices { let klass=cabinet.ducts[i].ductClass; cabinet.ducts[i].usedAreaMM2 = cabinet.wires.filter{$0.signalClass==klass || klass == .mixed}.reduce(0){$0+$1.areaMM2} } }
    public var audit:[String]{ cabinet.audit + strips.flatMap{$0.audit} + fanouts.flatMap{$0.audit} + (!doorBond.healthy ? ["door protective bond unhealthy"]:[]) + (doorHarness.fatigueRisk ? ["door harness fatigue risk"]:[]) + (climate.condensationRisk ? ["enclosure condensation risk"]:[]) }
}

public enum Rev25Factory {
    public static func instrumentCabinet()->ConstructionCabinet { var base=CabinetTemplateFactory.compressorControlSpatial(); base.addTerminal(.init(id:"TB1:2",deviceTag:"TB1",number:"2",function:.analog,position:.init(225,1450),railID:"DR-3")); var c=ConstructionCabinet(cabinet:base); var strip=TerminalStripAssembly(tag:"TB1"); strip.add(.init(terminal:base.terminals["TB1:1"]!,end:.init("401+"))); strip.add(.init(terminal:base.terminals["TB1:2"]!,end:.init("401-"))); c.strips=[strip]; c.fanouts=[.init(cableTag:"CBL-401",gland:base.glands[0],cores:[.init(number:"1",wireNumber:"401+",landedTerminal:"TB1:1"),.init(number:"2",wireNumber:"401-",landedTerminal:"TB1:2"),.init(number:"3",wireNumber:"SP1",spare:true)],shield:.init(id:"SC-401"))]; c.recalculateDuctFill(); return c }
}
