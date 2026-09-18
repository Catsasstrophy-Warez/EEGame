import Foundation
import ElectricalCore
import CircuitMNA

// Rev67: deterministic island scheduling, multi-rate domains, physical instruments, instruction traces and fixed-storage forensics.
public struct EECompiledCircuit67: Sendable {
    public var circuit: Circuit
    public var model: SparseMNAModel
    public init(_ circuit:Circuit){ self.circuit=circuit; self.model=SparseMNACompiler.compile(circuit) }
    public mutating func restamp(){ SparseMNACompiler.stamp(circuit, into:&model) }
}

public struct EEIslandSolve67: Sendable, Equatable { public var index:Int; public var snapshot:ElectricalSnapshot?; public var error:String? }
public enum EEDeterministicIslandScheduler67 {
    /// Independent circuits are solved concurrently; results are sorted before publication so task completion order never becomes game truth.
    public static func solve(_ circuits:[Circuit]) async -> [EEIslandSolve67] {
        await withTaskGroup(of: EEIslandSolve67.self) { group in
            for (i,c) in circuits.enumerated(){ group.addTask { do { return .init(index:i,snapshot:try SparseDCSolver().solve(c),error:nil) } catch { return .init(index:i,snapshot:nil,error:String(describing:error)) } } }
            var out:[EEIslandSolve67]=[]; for await r in group { out.append(r) }; return out.sorted{$0.index<$1.index}
        }
    }
}

public enum EESimulationDomain67:String,Sendable,Codable,CaseIterable { case electrical,controls,mechanical,process,presentation }
public struct EEMultiRateClock67:Sendable,Codable,Equatable{
    public var time=0.0; public var periods:[EESimulationDomain67:Double] = [.electrical:0.001,.controls:0.01,.mechanical:0.01,.process:0.05,.presentation:1.0/30.0]
    private var next:[EESimulationDomain67:Double]=[:]
    public init(){}
    public mutating func advance(to target:Double)->[EESimulationDomain67]{ guard target>=time else{return []};time=target;var due:[EESimulationDomain67]=[];for d in EESimulationDomain67.allCases {let p=max(1e-6,periods[d] ?? 0.01);let n=next[d] ?? p;if target+1e-12>=n {due.append(d);var q=n;while q<=target {q += p};next[d]=q}};return due }
}

public enum EEInstrumentMode67:String,Sendable,Codable { case dmmVoltage,dmmCurrent,dmmResistance,insulationTest,loopMeasure,loopSource,loopSimulate }
public struct EEPhysicalInstrument67:Sendable,Codable,Equatable{
    public var mode:EEInstrumentMode67 = .dmmVoltage; public var redPoint:String?; public var blackPoint:String?; public var fuseIntact=true; public var testVoltage=500.0; public var loopSetpointMA=12.0; public var voltageInputOhms=10_000_000.0; public var burdenOhms=10.0
    public init(){}
    public func insulationResistance(leakageA:Double)->Double?{guard mode == .insulationTest, redPoint != nil, blackPoint != nil, leakageA>0 else{return nil};return testVoltage/leakageA}
    public func loopResult(supplyV:Double,externalOhms:Double)->Double?{switch mode{case .loopMeasure:return fuseIntact ? supplyV/max(1,externalOhms+burdenOhms):nil;case .loopSource,.loopSimulate:return loopSetpointMA;default:return nil}}
}

public enum EETransmitterTrimAction67:String,Sendable,Codable { case sensorZero,sensorSpan,outputFourMA,outputTwentyMA,rerange }
public struct EETransmitterService67:Sendable,Codable,Equatable{
    public var sensorZeroTrim=0.0; public var sensorSpanTrim=1.0; public var outputZeroTrimMA=0.0; public var outputSpanTrim=1.0; public var lrv=0.0; public var urv=100.0
    public init(){}
    public mutating func apply(_ action:EETransmitterTrimAction67, reference:Double, observed:Double){switch action{case .sensorZero:sensorZeroTrim += reference-observed;case .sensorSpan:if abs(observed)>1e-9{sensorSpanTrim *= reference/observed};case .outputFourMA:outputZeroTrimMA += 4-observed;case .outputTwentyMA:if abs(observed-4)>1e-9{outputSpanTrim *= 16/(observed-4)};case .rerange:lrv=min(reference,observed);urv=max(reference,observed)}}
}

public enum EEInstructionKind67:String,Sendable,Codable { case contactNO,contactNC,timerOn,counterUp,compare,move,output }
public struct EEInstructionTrace67:Identifiable,Sendable,Codable,Equatable { public var id:Int; public var scan:Int; public var rung:String; public var instruction:EEInstructionKind67; public var enabled:Bool; public var input:Double?; public var output:Double? }
public struct EEPLCInstructionRecorder67:Sendable,Codable,Equatable { public var traces:[EEInstructionTrace67]=[]; public init(){}; public mutating func record(scan:Int,rung:String,instruction:EEInstructionKind67,enabled:Bool,input:Double?=nil,output:Double?=nil){traces.append(.init(id:traces.count,scan:scan,rung:rung,instruction:instruction,enabled:enabled,input:input,output:output))} }

public struct EEForensicCircularBuffer67:Sendable,Codable,Equatable{
    public var capacity:Int; private var storage:[EEReplayFrame63?]; private var head=0; private var count=0
    public init(capacity:Int=4096){self.capacity=max(1,capacity);self.storage=Array(repeating:nil,count:max(1,capacity))}
    public mutating func append(_ frame:EEReplayFrame63){storage[head]=frame;head=(head+1)%capacity;count=min(capacity,count+1)}
    public var frames:[EEReplayFrame63]{ guard count>0 else{return []};let start=(head-count+capacity)%capacity;return (0..<count).compactMap{storage[(start+$0)%capacity]} }
    public func nearest(time:Double)->EEReplayFrame63?{frames.min{abs($0.time-time)<abs($1.time-time)}}
}

public struct EEQualificationWorkbench67:Sendable,Codable{
    public var base=EERev66DeepPhysicalControls(); public var clock=EEMultiRateClock67(); public var instrument=EEPhysicalInstrument67(); public var transmitterService=EETransmitterService67(); public var instructions=EEPLCInstructionRecorder67(); public var forensic=EEForensicCircularBuffer67(capacity:2400)
    public init(){}
    public mutating func advance(dt:Double){let target=clock.time+max(0,dt);let due=clock.advance(to:target);if due.contains(.process){base.manifold.step(dt:dt)};if due.contains(.electrical){base.transmitter.step(physicalInput:base.manifold.differential,dt:dt)};if due.contains(.controls){base.base.tick(dt:dt);let p=base.base.base.runtime.board.rig.plc;let scan=base.ladder.frames.count;base.ladder.append(time:target,inputs:["permissive":p.permissive,"request":p.runRequest],rungs:["run":p.permissive && p.runRequest],outputs:["output":p.output]);instructions.record(scan:scan,rung:"RUN",instruction:.contactNO,enabled:p.permissive);instructions.record(scan:scan,rung:"RUN",instruction:.output,enabled:p.output)};if let f=base.base.base.runtime.board.rig.replay.frames.last{forensic.append(f)}}
}
