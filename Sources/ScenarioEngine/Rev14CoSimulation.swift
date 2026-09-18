import Foundation
import ElectricalCore
import CircuitMNA

public enum CoSimulationClockMode: String, Sendable, Codable { case freeRunning, lockstep }
public enum IOSpace: String, Sendable, Codable { case physicalInput, physicalOutput, simulationInput, simulationOutput, marker, dataBlock }
public enum IODataType: String, Sendable, Codable { case boolean, int16, int32, float32, float64 }

public struct IOAddress: Sendable, Codable, Equatable, Hashable {
    public var space: IOSpace
    public var byte: Int
    public var bit: Int?
    public init(space: IOSpace, byte: Int, bit: Int? = nil) { self.space=space; self.byte=byte; self.bit=bit }
}

public struct TagBinding: Sendable, Codable, Equatable {
    public var plantTag: String
    public var address: IOAddress
    public var direction: SignalDirection
    public var dataType: IODataType
    public var scale: ClosedRange<Double>
    public init(plantTag:String,address:IOAddress,direction:SignalDirection,dataType:IODataType = .float64,scale:ClosedRange<Double> = 0...1) { self.plantTag=plantTag;self.address=address;self.direction=direction;self.dataType=dataType;self.scale=scale }
}

public enum BindingFinding: String, Sendable, Codable, Equatable { case duplicateAddress, physicalImageCollision, duplicatePlantTag, invalidBit }
public struct BindingAudit: Sendable, Equatable { public var findings:[BindingFinding]; public var valid:Bool { findings.isEmpty } }
public enum BindingValidator {
    public static func audit(_ bindings:[TagBinding], hardwareOwned:Set<IOAddress> = []) -> BindingAudit {
        var f:[BindingFinding]=[]
        var addresses=Set<IOAddress>(); var tags=Set<String>()
        for b in bindings {
            if !addresses.insert(b.address).inserted { f.append(.duplicateAddress) }
            if !tags.insert(b.plantTag).inserted { f.append(.duplicatePlantTag) }
            if hardwareOwned.contains(b.address) && (b.address.space == .physicalInput || b.address.space == .physicalOutput) { f.append(.physicalImageCollision) }
            if let bit=b.address.bit, !(0...7).contains(bit) { f.append(.invalidBit) }
        }
        return .init(findings:Array(Set(f)))
    }
}

public struct ProcessImage: Sendable {
    public var values:[IOAddress:Double]=[:]
    public init(){}
    public subscript(_ address:IOAddress) -> Double { get { values[address] ?? 0 } set { values[address]=newValue } }
}

public enum TransportHealth: String, Sendable, Codable { case healthy, delayed, stale, disconnected }
public struct TransportSample: Sendable, Codable, Equatable { public var sequence:UInt64;public var timestamp:Double;public var values:[String:Double]; public init(sequence:UInt64,timestamp:Double,values:[String:Double]){self.sequence=sequence;self.timestamp=timestamp;self.values=values} }
public struct TransportDiagnostics: Sendable, Equatable {
    public init(){}
    public var received:UInt64=0; public var dropped:UInt64=0; public var reordered:UInt64=0
    public var lastLatency=0.0; public var maxLatency=0.0; public var lastSequence:UInt64?
    public mutating func receive(_ sample:TransportSample,now:Double) {
        if let last=lastSequence { if sample.sequence <= last { reordered += 1 } else if sample.sequence > last+1 { dropped += sample.sequence-last-1 } }
        lastSequence=max(lastSequence ?? 0,sample.sequence); received += 1
        lastLatency=max(0,now-sample.timestamp); maxLatency=max(maxLatency,lastLatency)
    }
    public func health(now:Double,lastTimestamp:Double?,staleAfter:Double) -> TransportHealth {
        guard let t=lastTimestamp else { return .disconnected }
        let age=now-t; if age>staleAfter { return .stale }; if lastLatency>staleAfter*0.5 { return .delayed }; return .healthy
    }
}

public struct JitterStatistics: Sendable, Equatable {
    public private(set) var count=0; public private(set) var mean=0.0; public private(set) var m2=0.0; public private(set) var maxAbsolute=0.0
    public init(){}
    public mutating func record(expected:Double,actual:Double) { let e=actual-expected;count += 1;let d=e-mean;mean += d/Double(count);m2 += d*(e-mean);maxAbsolute=max(maxAbsolute,abs(e)) }
    public var standardDeviation:Double { count>1 ? sqrt(m2/Double(count-1)) : 0 }
}

public struct LockstepCoordinator: Sendable {
    public var quantum:Double; public private(set) var virtualTime=0.0; public private(set) var cycle:UInt64=0
    public init(quantum:Double=0.002){self.quantum=max(1e-6,quantum)}
    public mutating func nextStep() -> Double { cycle += 1;virtualTime += quantum;return quantum }
}

public struct PLCImageCycle: Sendable {
    public var inputs=ProcessImage(); public var outputs=ProcessImage(); public var scanCount:UInt64=0
    public init(){}
    public mutating func scan(logic:(ProcessImage,inout ProcessImage)->Void) { let snapshot=inputs;logic(snapshot,&outputs);scanCount += 1 }
}

public struct CoSimulationBridge: Sendable {
    public var bindings:[TagBinding]; public var plantValues:[String:Double]=[:]; public var controller=PLCImageCycle(); public var diagnostics=TransportDiagnostics(); public var lastPlantTimestamp:Double?
    public init(bindings:[TagBinding]){self.bindings=bindings}
    public mutating func writePlantInputs(timestamp:Double) { lastPlantTimestamp=timestamp;for b in bindings where b.direction == .plantToController { controller.inputs[b.address]=plantValues[b.plantTag] ?? 0 } }
    public mutating func readControllerOutputs() { for b in bindings where b.direction == .controllerToPlant { plantValues[b.plantTag]=controller.outputs[b.address] } }
}

public struct Rev14LockstepPlant: Sendable {
    public var coordinator=LockstepCoordinator(); public var bridge:CoSimulationBridge; public var skid=ProcessSkid()
    public init(){ bridge=CoSimulationBridge(bindings:[
        .init(plantTag:"LT-101",address:.init(space:.simulationInput,byte:10),direction:.plantToController),
        .init(plantTag:"P-101_SPEED",address:.init(space:.simulationOutput,byte:20),direction:.controllerToPlant)
    ]) }
    public mutating func cycle() {
        let dt=coordinator.nextStep()
        bridge.plantValues["LT-101"]=skid.levelTransmitter.outputMilliamps();bridge.writePlantInputs(timestamp:coordinator.virtualTime)
        bridge.controller.scan { input,output in let level=input[IOAddress(space:.simulationInput,byte:10)];output[IOAddress(space:.simulationOutput,byte:20)] = level < 12 ? 1 : 0 }
        bridge.readControllerOutputs();let cmd=bridge.plantValues["P-101_SPEED"] ?? 0;skid.step(pumpCommand:cmd,valveCommand:0.4,dt:dt)
    }
}
