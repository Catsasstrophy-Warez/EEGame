import Foundation

public enum EEShiftPriority:Int,CaseIterable,Sendable,Codable { case routine=1, production=2, safety=3 }
public enum EEShiftJobState:String,CaseIterable,Sendable,Codable { case queued, investigating, isolated, repaired, verified, closed }
public struct EEShiftWorkOrder:Sendable,Codable,Equatable { public var id:String; public var title:String; public var identity:String; public var priority:EEShiftPriority; public var state:EEShiftJobState = .queued; public var ageMinutes:Double=0; public var evidence:[String]=[]; public init(id:String,title:String,identity:String,priority:EEShiftPriority){self.id=id;self.title=title;self.identity=identity;self.priority=priority} }
public struct EEDegradingAsset:Sendable,Codable,Equatable { public var identity:String; public var resistanceOhm:Double; public var oxidation:Double; public var temperatureC:Double; public var vibration:Double; public init(identity:String,resistanceOhm:Double,oxidation:Double,temperatureC:Double,vibration:Double){self.identity=identity;self.resistanceOhm=resistanceOhm;self.oxidation=oxidation;self.temperatureC=temperatureC;self.vibration=vibration}; public mutating func tick(seconds:Double,currentA:Double){ let heat=currentA*currentA*resistanceOhm*seconds*0.08; temperatureC += heat - max(0,temperatureC-25)*0.002*seconds; oxidation=min(1,oxidation + max(0,temperatureC-45)*0.000002*seconds + vibration*0.000001*seconds); resistanceOhm *= 1 + oxidation*0.00002*seconds } }
public struct EESolverSnapshot:Sendable,Codable,Equatable { public var t:Double; public var nodeVolts:[String:Double]; public var branchAmps:[String:Double]; public var temperatures:[String:Double]; public var qualities:[String:Double] }
public struct EECurrentParticle:Sendable,Equatable { public var identity:String; public var normalizedPosition:Double; public var speed:Double }
public struct EECurrentFlowAnimator:Sendable { public init(){}; public func particles(snapshot:EESolverSnapshot,identity:String,count:Int=8)->[EECurrentParticle]{let a=abs(snapshot.branchAmps[identity] ?? 0); guard a > 0 else{return []}; return (0..<max(1,count)).map{EECurrentParticle(identity:identity,normalizedPosition:Double($0)/Double(max(1,count)),speed:min(1,max(0.05,a*80)))} } }
public struct EEProbeDragSession:Sendable,Equatable { public init(){}; public var red:String?; public var black:String?; public mutating func dropRed(on id:String){red=id}; public mutating func dropBlack(on id:String){black=id}; public var complete:Bool{red != nil && black != nil} }
public enum EETriggerSlope:String,Sendable,Codable { case rising, falling }
public struct EETriggerPoint:Sendable,Codable,Equatable { public var t:Double; public var value:Double; public init(t:Double,value:Double){self.t=t;self.value=value} }
public struct EETriggeredChannel:Sendable,Codable,Equatable { public var name:String; public var unit:String; public var scale:Double; public var points:[EETriggerPoint]; public init(name:String,unit:String,scale:Double,points:[EETriggerPoint]){self.name=name;self.unit=unit;self.scale=scale;self.points=points} }
public struct EEAdvancedScope:Sendable,Codable,Equatable { public init(triggerLevel:Double=0){self.triggerLevel=triggerLevel}; public var channels:[EETriggeredChannel]=[]; public var triggerChannel:String="CH1"; public var triggerLevel:Double=0; public var slope:EETriggerSlope = .rising; public var armed=true; public var captured=false; public mutating func ingest(_ channel:EETriggeredChannel){channels.removeAll{$0.name==channel.name};channels.append(channel); if armed, let c=channels.first(where:{$0.name==triggerChannel}), c.points.contains(where:{$0.value >= triggerLevel}) {captured=true;armed=false}} }
public struct EEThermalInterpolator:Sendable { public init(){}; public func temperature(x:Double,y:Double,frame:EEThermalFrame)->Double { guard !frame.pixels.isEmpty else{return 0}; let weighted=frame.pixels.map{p->(Double,Double) in let d=max(0.001,hypot(Double(p.x)-x,Double(p.y)-y));return(p.celsius,1/d)};return weighted.reduce(0){$0+$1.0*$1.1}/weighted.reduce(0){$0+$1.1} } }
public struct EEPlantReplay:Sendable { public init(timeline:EEForensicTimeline){self.timeline=timeline}; public var timeline:EEForensicTimeline; public func state(at t:Double)->[String:String]{Dictionary(uniqueKeysWithValues:timeline.events.filter{$0.t<=t}.map{($0.identity,$0.value)})} }
public struct EELessonGrade:Sendable,Equatable { public var score:Int; public var passed:Bool; public var findings:[String] }
public struct EEMotorLessonExecutor:Sendable { public init(){}; public func grade(lesson:EEMotorLesson,completed:[String],unsafeActions:Int)->EELessonGrade { let required=Set(["build","measure","verify"]); let missing=required.subtracting(completed); let score=max(0,100-missing.count*25-unsafeActions*20); return .init(score:score,passed:missing.isEmpty && unsafeActions==0 && score>=80,findings:missing.sorted()) } }
public struct EENetworkDecode:Sendable,Equatable { public var protocolName:String; public var summary:String; public var fields:[String:String] }
public struct EENetworkDecoder:Sendable { public init(){}; public func decode(_ p:EENetworkPacket)->EENetworkDecode { if p.protocolName=="CAN" { return .init(protocolName:"CAN",summary:"ID \(p.identifier), \(p.payload.count) byte payload",fields:["identifier":p.identifier,"valid":String(p.valid)])}; return .init(protocolName:p.protocolName,summary:"\(p.source) → \(p.destination)",fields:["identifier":p.identifier]) } }
public struct EEComponentCutaway:Sendable,Equatable { public init(id:String,layers:[String]){self.id=id;self.layers=layers}; public var id:String; public var layers:[String]; public var activeLayer:Int=0; public mutating func advance(){activeLayer=min(layers.count-1,activeLayer+1)} }
public struct EECareerProgress:Sendable,Codable,Equatable { public init(){}; public var xp:Int=0; public var completedJobs:Int=0; public var verifiedRootCauses:Int=0; public mutating func award(verified:Bool){completedJobs += 1;xp += verified ? 150:50;if verified{verifiedRootCauses += 1}} }
public struct EEPersistentShift: Sendable, Codable, Equatable {
    public var time: Double = 0
    public var jobs: [EEShiftWorkOrder]
    public var assets: [EEDegradingAsset]
    public var career = EECareerProgress()
    public init() {
        jobs = [
            .init(id:"WO-401",title:"Discharge pressure intermittent",identity:"DISC-401",priority:.production),
            .init(id:"WO-402",title:"MCC bucket hot spot",identity:"MCC-2B",priority:.safety),
            .init(id:"WO-403",title:"Valve travel deviation",identity:"DVC-201",priority:.routine)
        ]
        assets = [
            .init(identity:"DISC-401",resistanceOhm:18,oxidation:0.22,temperatureC:48,vibration:0.7),
            .init(identity:"MCC-2B",resistanceOhm:0.08,oxidation:0.1,temperatureC:52,vibration:0.2)
        ]
    }
    public mutating func tick(seconds: Double) {
        time += seconds
        for i in jobs.indices where jobs[i].state != .closed { jobs[i].ageMinutes += seconds/60 }
        for i in assets.indices { assets[i].tick(seconds:seconds,currentA:assets[i].identity == "DISC-401" ? 0.012 : 32) }
    }
    public func snapshot() -> EESolverSnapshot {
        .init(t:time,nodeVolts:["JB-4:12":24,"DISC-401":17.5],branchAmps:["PIT401_SIGNAL":0.00874,"MCC-2B":32],temperatures:Dictionary(uniqueKeysWithValues:assets.map{($0.identity,$0.temperatureC)}),qualities:["PIT401_SIGNAL":0.61])
    }
    public func encoded() throws -> Data { try JSONEncoder().encode(self) }
    public static func decoded(_ d: Data) throws -> Self { try JSONDecoder().decode(Self.self,from:d) }
}
