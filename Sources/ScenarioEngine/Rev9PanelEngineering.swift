import Foundation
import ElectricalCore
import CircuitMNA

// MARK: - Physical panel engineering
public enum MountSurface:String,Sendable,Codable { case backplate, door, dinRail }
public struct EngineeringDevice:Identifiable,Sendable,Codable,Equatable {
 public var id:String; public var kind:PanelDeviceKind; public var surface:MountSurface; public var position:PanelPoint; public var size:PanelSize; public var tag:String; public var heatWatts:Double; public var requiredClearanceMM:Double
 public init(id:String,kind:PanelDeviceKind,surface:MountSurface = .backplate,position:PanelPoint,size:PanelSize,tag:String?=nil,heatWatts:Double=0,requiredClearanceMM:Double=10){self.id=id;self.kind=kind;self.surface=surface;self.position=position;self.size=size;self.tag=tag ?? id;self.heatWatts=heatWatts;self.requiredClearanceMM=requiredClearanceMM}
}
public enum TerminalKind:String,Sendable,Codable { case feedThrough, fused, disconnect, ground, shield, multiLevel }
public struct TerminalPoint:Identifiable,Sendable,Codable,Equatable { public var id:String; public var strip:String; public var number:Int; public var kind:TerminalKind; public var node:String; public var level:Int; public init(id:String,strip:String,number:Int,kind:TerminalKind,node:String,level:Int=0){self.id=id;self.strip=strip;self.number=number;self.kind=kind;self.node=node;self.level=level} }
public struct TerminalStrip:Identifiable,Sendable,Codable,Equatable { public var id:String; public var terminals:[TerminalPoint]; public init(id:String,count:Int,prefix:String="X1"){self.id=id;self.terminals=(1...max(count,0)).map{.init(id:"\(prefix):\($0)",strip:prefix,number:$0,kind:.feedThrough,node:"N-\($0)")} } }
public struct WireIdentity:Sendable,Codable,Equatable { public var wireNumber:String; public var cableID:String?; public var ferruleFrom:String; public var ferruleTo:String; public init(wireNumber:String,cableID:String?=nil){self.wireNumber=wireNumber;self.cableID=cableID;self.ferruleFrom=wireNumber;self.ferruleTo=wireNumber} }
public struct EngineeredWire:Identifiable,Sendable,Codable,Equatable { public var id:String; public var identity:WireIdentity; public var from:String; public var to:String; public var conductorClass:ConductorClass; public var gaugeMM2:Double; public var route:[PanelPoint]; public var shieldDrainTerminal:String?; public init(id:String,number:String,from:String,to:String,conductorClass:ConductorClass,gaugeMM2:Double,route:[PanelPoint]=[]){self.id=id;self.identity = .init(wireNumber:number);self.from=from;self.to=to;self.conductorClass=conductorClass;self.gaugeMM2=gaugeMM2;self.route=route}; public var lengthMM:Double { guard route.count>1 else{return 0}; return zip(route,route.dropFirst()).reduce(0){$0+hypot($1.1.x-$1.0.x,$1.1.y-$1.0.y)} } }
public enum EngineeringIssue:String,Sendable,Codable,Equatable { case duplicateTag, duplicateWireNumber, missingTerminal, analogPowerSegregation, networkPowerSegregation, overfilledDuct, insufficientServiceClearance, excessivePanelHeat }
public struct PanelEngineeringReport:Sendable,Equatable { public var issues:[EngineeringIssue]; public var totalWireLengthMM:Double; public var valid:Bool{issues.isEmpty} }
public struct PanelEngineeringModel:Sendable,Codable,Equatable {
 public var enclosure=PanelSize(800,1000); public var devices:[EngineeringDevice]=[]; public var strips:[TerminalStrip]=[]; public var wires:[EngineeredWire]=[]; public var ducts:[WireDuct]=[]
 public init(){}
 public func validate()->PanelEngineeringReport { var issues:[EngineeringIssue]=[]; let tags=devices.map(\.tag); if Set(tags).count != tags.count {issues.append(.duplicateTag)}; let nums=wires.map{ $0.identity.wireNumber }; if Set(nums).count != nums.count {issues.append(.duplicateWireNumber)}; let endpoints=Set(strips.flatMap{$0.terminals.map(\.id)}).union(devices.map(\.id)); for w in wires { if !endpoints.contains(w.from) || !endpoints.contains(w.to){issues.append(.missingTerminal)} }; if ducts.contains(where:{$0.overfilled}){issues.append(.overfilledDuct)}; let heat=devices.reduce(0){$0+$1.heatWatts}; if heat/(enclosure.width*enclosure.height/1_000_000)>500{issues.append(.excessivePanelHeat)}; return .init(issues:Array(Set(issues)),totalWireLengthMM:wires.reduce(0){$0+$1.lengthMM}) }
}

// MARK: - Drawing / stable identity views
public enum DrawingView:String,Sendable,Codable,CaseIterable { case panelLayout, wiringDiagram, ladder, oneLine, ioDrawing, physicalMachine }
public struct CrossReference:Sendable,Codable,Equatable { public var identity:String; public var appearances:[DrawingView:String]; public init(identity:String,appearances:[DrawingView:String]){self.identity=identity;self.appearances=appearances} }
public struct DrawingIndex:Sendable,Codable,Equatable { public var refs:[String:CrossReference]=[:]; public init(){}; public mutating func register(_ id:String,view:DrawingView,label:String){var r=refs[id] ?? .init(identity:id,appearances:[:]);r.appearances[view]=label;refs[id]=r}; public func label(_ id:String,in view:DrawingView)->String?{refs[id]?.appearances[view]} }

// MARK: - Deeper automation runtime
public enum TaskKind:String,Sendable,Codable { case continuous, periodic }
public struct PLCProgramTask:Identifiable,Sendable,Codable,Equatable { public var id:String; public var kind:TaskKind; public var period:Double; public var priority:Int; public var rungs:[[LadderInstruction]]; public var elapsed=0.0; public init(id:String,kind:TaskKind,period:Double=0.01,priority:Int=10,rungs:[[LadderInstruction]]){self.id=id;self.kind=kind;self.period=period;self.priority=priority;self.rungs=rungs} }
public struct PIDController:Sendable,Codable,Equatable { public var kp:Double; public var ki:Double; public var kd:Double; public var integral=0.0; public var previousError=0.0; public var outputMin=0.0; public var outputMax=100.0; public init(kp:Double,ki:Double,kd:Double){self.kp=kp;self.ki=ki;self.kd=kd}; public mutating func step(setpoint:Double,pv:Double,dt:Double)->Double{let e=setpoint-pv;integral += e*dt;let derivative=dt>0 ? (e-previousError)/dt:0;previousError=e;return min(max(kp*e+ki*integral+kd*derivative,outputMin),outputMax)} }
public struct ScheduledAutomationRuntime:Sendable { public var plc=AutomationRuntime(); public var tasks:[PLCProgramTask]=[]; public var scanCount=0; public init(){}; public mutating func step(dt:Double){ for i in tasks.indices.sorted(by:{tasks[$0].priority<tasks[$1].priority}) { tasks[i].elapsed += dt; let due=tasks[i].kind == .continuous || tasks[i].elapsed+1e-12 >= tasks[i].period; if due { for rung in tasks[i].rungs {plc.execute(rung,dt:dt)}; tasks[i].elapsed=0; scanCount += 1 } } } }

// MARK: - HMI / alarm engineering
public enum HMIObjectKind:String,Sendable,Codable { case numeric, indicator, command, faceplate, trend, alarmBanner }
public struct HMIObject:Identifiable,Sendable,Codable,Equatable { public var id:String; public var kind:HMIObjectKind; public var tag:String; public var label:String; public init(id:String,kind:HMIObjectKind,tag:String,label:String){self.id=id;self.kind=kind;self.tag=tag;self.label=label} }
public struct HMIScreen:Identifiable,Sendable,Codable,Equatable { public var id:String; public var title:String; public var objects:[HMIObject]; public init(id:String,title:String,objects:[HMIObject]=[]){self.id=id;self.title=title;self.objects=objects} }
public struct AlarmQualityReport:Sendable,Equatable { public var total:Int; public var duplicateMessages:Int; public var floodRisk:Bool }
public enum AlarmEngineering { public static func assess(_ events:[AlarmEvent],windowSeconds:Double=60)->AlarmQualityReport { let dup=events.count-Set(events.map(\.message)).count; let sorted=events.sorted{$0.timestamp<$1.timestamp}; var maxWindow=0; for e in sorted {let c=sorted.filter{$0.timestamp>=e.timestamp && $0.timestamp<=e.timestamp+windowSeconds}.count;maxWindow=max(maxWindow,c)}; return .init(total:events.count,duplicateMessages:dup,floodRisk:maxWindow>=10) } }

// MARK: - Industrial communications truth
public enum NetworkFault:String,Sendable,Codable { case none, duplicateAddress, badSubnet, packetLoss, linkDown, staleData }
public struct IndustrialNode:Identifiable,Sendable,Codable,Equatable { public var id:String; public var address:String; public var subnet:String; public var updatePeriod:Double; public var lastUpdate=0.0; public var fault:NetworkFault = .none; public init(id:String,address:String,subnet:String="255.255.255.0",updatePeriod:Double=0.02){self.id=id;self.address=address;self.subnet=subnet;self.updatePeriod=updatePeriod} }
public struct IndustrialNetwork:Sendable,Codable,Equatable { public var nodes:[IndustrialNode]=[]; public var time=0.0; public init(){}; public mutating func step(dt:Double){time += dt; let addresses=Dictionary(grouping:nodes,by:{$0.address}); for i in nodes.indices { if (addresses[nodes[i].address]?.count ?? 0)>1{nodes[i].fault = .duplicateAddress}; if nodes[i].fault == .none && time-nodes[i].lastUpdate >= nodes[i].updatePeriod {nodes[i].lastUpdate=time} } }; public func healthy(_ id:String)->Bool{nodes.first(where:{$0.id==id})?.fault == NetworkFault.none} }

// MARK: - Commissioning workflow
public enum CommissioningCheck:String,Sendable,Codable,CaseIterable { case visualInspection, torqueVerification, continuity, insulationResistance, groundBond, phaseRotation, ioCheckout, loopCalibration, interlockTest, safetyTest, functionalRun }
public struct CommissioningRecord:Sendable,Codable,Equatable { public var completed:Set<CommissioningCheck>=[]; public init(){}; public mutating func complete(_ check:CommissioningCheck){completed.insert(check)}; public var readyToEnergize:Bool{[.visualInspection,.torqueVerification,.continuity,.insulationResistance,.groundBond].allSatisfy(completed.contains)}; public var complete:Bool{Set(CommissioningCheck.allCases).isSubset(of:completed)} }

public struct Rev9AutomationPlant:Sendable { public var engineering=PanelEngineeringModel(); public var drawings=DrawingIndex(); public var controller=ScheduledAutomationRuntime(); public var hmi:[HMIScreen]=[]; public var network=IndustrialNetwork(); public var commissioning=CommissioningRecord(); public var cell=PanelBuildCell(); public init(){} }
