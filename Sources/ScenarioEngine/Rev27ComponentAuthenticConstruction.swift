import Foundation

// Rev27 — component-authentic terminals, tools, workmanship provenance, SCCR groundwork,
// and vendor-aware maintenance workflows. Educational simulation only.

public enum TerminalTechnology: String, Sendable, Codable, CaseIterable {
    case screwClamp, springCage, pushIn, pushX, stud, lug, pluggable, fusedDisconnect, knifeDisconnect, protectiveEarth, shieldClamp
}
public enum ConductorPreparation: String, Sendable, Codable { case bare, ferrule, ringLug, forkLug, pinTerminal }

public struct TerminalDefinition: Sendable, Codable, Hashable {
    public var id:String; public var technology:TerminalTechnology
    public var minAreaMM2:Double; public var maxAreaMM2:Double
    public var stripMinMM:Double; public var stripMaxMM:Double
    public var accepted:Set<ConductorPreparation>
    public var torqueRangeNM:ClosedRange<Double>?
    public var testPoint:Bool; public var bridgeSlot:Bool
    public init(id:String,technology:TerminalTechnology,minAreaMM2:Double,maxAreaMM2:Double,stripMinMM:Double,stripMaxMM:Double,accepted:Set<ConductorPreparation>,torqueRangeNM:ClosedRange<Double>?=nil,testPoint:Bool=true,bridgeSlot:Bool=true){self.id=id;self.technology=technology;self.minAreaMM2=minAreaMM2;self.maxAreaMM2=maxAreaMM2;self.stripMinMM=stripMinMM;self.stripMaxMM=stripMaxMM;self.accepted=accepted;self.torqueRangeNM=torqueRangeNM;self.testPoint=testPoint;self.bridgeSlot=bridgeSlot}
    public func accepts(areaMM2:Double, preparation:ConductorPreparation, stripMM:Double)->Bool { areaMM2 >= minAreaMM2 && areaMM2 <= maxAreaMM2 && accepted.contains(preparation) && stripMM >= stripMinMM && stripMM <= stripMaxMM }
    public func torqueAcceptable(_ nm:Double)->Bool { guard let r=torqueRangeNM else{return true}; return r.contains(nm) }
}

public enum ToolCondition: String, Sendable, Codable { case good, worn, damaged, misadjusted }
public struct ToolTruth: Sendable, Codable, Hashable {
    public var id:String; public var kind:AssemblyTool; public var condition:ToolCondition = .good
    public var calibrationErrorFraction:Double=0; public var selectedDieMM2:Double?; public var torqueSettingNM:Double?
    public init(id:String,kind:AssemblyTool){self.id=id;self.kind=kind}
    public func actualTorque()->Double? { guard let s=torqueSettingNM else{return nil}; return s * (1 + calibrationErrorFraction) }
    public func crimpCompression(for conductorMM2:Double)->Double { guard kind == .ferruleCrimper else{return 0}; guard condition != .damaged else{return 0.45}; guard let die=selectedDieMM2 else{return 0.65}; let mismatch=abs(die-conductorMM2)/max(0.1,conductorMM2); return max(0.35,1.0-mismatch*1.6) * (condition == .worn ? 0.82 : 1.0) }
}

public struct AuthenticTermination: Sendable, Codable, Hashable {
    public var wire:String; public var conductorAreaMM2:Double; public var preparation:ConductorPreparation; public var stripMM:Double
    public var terminal:TerminalDefinition; public var appliedTorqueNM:Double?; public var crimp:CrimpTruth?
    public var landed=true
    public init(wire:String,conductorAreaMM2:Double,preparation:ConductorPreparation,stripMM:Double,terminal:TerminalDefinition,appliedTorqueNM:Double?=nil,crimp:CrimpTruth?=nil,landed:Bool=true){self.wire=wire;self.conductorAreaMM2=conductorAreaMM2;self.preparation=preparation;self.stripMM=stripMM;self.terminal=terminal;self.appliedTorqueNM=appliedTorqueNM;self.crimp=crimp;self.landed=landed}
    public var findings:[String] { var a:[String]=[]; if !terminal.accepts(areaMM2:conductorAreaMM2,preparation:preparation,stripMM:stripMM){a.append("terminal/conductor preparation mismatch")}; if let t=appliedTorqueNM,!terminal.torqueAcceptable(t){a.append("terminal torque outside component definition")}; if preparation == .ferrule && crimp == nil {a.append("ferrule not crimped")}; if crimp?.grade == .failed {a.append("failed crimp")}; if !landed {a.append("not landed")}; return a }
    public var healthy:Bool { findings.isEmpty }
    public var addedResistanceOhms:Double { var r=0.0005; if !healthy {r += 0.08}; if let c=crimp {r += c.addedResistanceOhms}; return r }
}

public struct ConstructionToolbox: Sendable, Codable {
    public var tools:[String:ToolTruth]=[:]
    public init(){ tools["STRIP-1"] = .init(id:"STRIP-1",kind:.wireStripper); tools["CRIMP-1"] = .init(id:"CRIMP-1",kind:.ferruleCrimper); tools["TORQUE-1"] = .init(id:"TORQUE-1",kind:.torqueScrewdriver); tools["DMM-1"] = .init(id:"DMM-1",kind:.multimeter); tools["LOOP-1"] = .init(id:"LOOP-1",kind:.loopCalibrator) }
    public mutating func configureCrimper(_ id:String,dieMM2:Double){tools[id]?.selectedDieMM2=dieMM2}
    public mutating func configureTorque(_ id:String,nm:Double){tools[id]?.torqueSettingNM=nm}
}

public struct ComponentAuthenticAssembly: Sendable, Codable {
    public var toolbox=ConstructionToolbox(); public var terminations:[String:AuthenticTermination]=[:]; public var evidence:[String]=[]
    public init(){}
    public mutating func terminate(wire:String,areaMM2:Double,preparation:ConductorPreparation,stripMM:Double,terminal:TerminalDefinition,crimperID:String?=nil,torqueToolID:String?=nil){
        var c:CrimpTruth?=nil
        if preparation == .ferrule, let id=crimperID, let tool=toolbox.tools[id] { c = CrimpTruth(hardware:.ferrule,conductorAreaMM2:areaMM2,ferruleAreaMM2:tool.selectedDieMM2 ?? areaMM2,compression:tool.crimpCompression(for:areaMM2)) }
        let torque=torqueToolID.flatMap{toolbox.tools[$0]?.actualTorque()}
        let t=AuthenticTermination(wire:wire,conductorAreaMM2:areaMM2,preparation:preparation,stripMM:stripMM,terminal:terminal,appliedTorqueNM:torque,crimp:c)
        terminations[wire]=t; evidence.append("terminate \(wire) -> \(terminal.id): \(t.healthy ? "PASS":"FINDING")")
    }
    public var ready:Bool { !terminations.isEmpty && terminations.values.allSatisfy{$0.healthy} }
}

public enum TerminalLibrary {
    public static let screwSignal = TerminalDefinition(id:"SCREW-SIGNAL",technology:.screwClamp,minAreaMM2:0.2,maxAreaMM2:4,stripMinMM:8,stripMaxMM:12,accepted:[.bare,.ferrule,.pinTerminal],torqueRangeNM:0.5...0.8)
    public static let pushInSignal = TerminalDefinition(id:"PUSHIN-SIGNAL",technology:.pushIn,minAreaMM2:0.2,maxAreaMM2:4,stripMinMM:8,stripMaxMM:12,accepted:[.bare,.ferrule,.pinTerminal],torqueRangeNM:nil)
    public static let pushXSignal = TerminalDefinition(id:"PUSHX-SIGNAL",technology:.pushX,minAreaMM2:0.34,maxAreaMM2:6,stripMinMM:8,stripMaxMM:14,accepted:[.bare,.ferrule],torqueRangeNM:nil)
    public static let studPower = TerminalDefinition(id:"STUD-POWER",technology:.stud,minAreaMM2:2.5,maxAreaMM2:95,stripMinMM:0,stripMaxMM:30,accepted:[.ringLug,.forkLug],torqueRangeNM:2...12,testPoint:false,bridgeSlot:false)
}

public struct CircuitProtectionElement: Sendable, Codable, Hashable { public var tag:String; public var sccrKA:Double; public init(_ tag:String,_ sccrKA:Double){self.tag=tag;self.sccrKA=sccrKA} }
public struct PanelSCCRStudy: Sendable, Codable {
    public var availableFaultCurrentKA:Double; public var elements:[CircuitProtectionElement]
    public init(availableFaultCurrentKA:Double,elements:[CircuitProtectionElement]){self.availableFaultCurrentKA=availableFaultCurrentKA;self.elements=elements}
    public var limitingComponent:CircuitProtectionElement? { elements.min{$0.sccrKA < $1.sccrKA} }
    public var educationalPanelSCCRKAGroundwork:Double { limitingComponent?.sccrKA ?? 0 }
    public var faultCurrentExceedsGroundwork:Bool { availableFaultCurrentKA > educationalPanelSCCRKAGroundwork }
}

public enum DVCMaintenanceAction: String, Sendable, Codable { case inspect, replaceRelay, calibrateTravel, verifyTracking }
public struct DVCMaintenanceRuntime: Sendable, Codable {
    public var relayReplaced=false; public var calibrated=true; public var trackingVerified=true; public var history:[DVCMaintenanceAction]=[]
    public init(){}
    public mutating func perform(_ a:DVCMaintenanceAction){history.append(a);switch a{case .replaceRelay:relayReplaced=true;calibrated=false;trackingVerified=false;case .calibrateTravel:calibrated=true;case .verifyTracking:trackingVerified=calibrated;case .inspect:break}}
    public var returnToServiceReady:Bool { (!relayReplaced || calibrated) && trackingVerified }
}

public struct BurnerTerminalCircuit: Sendable, Codable, Hashable {
    public var tag:String; public var positiveTerminal:String; public var negativeTerminal:String; public var commonedIncorrectly=false
    public init(tag:String,positiveTerminal:String,negativeTerminal:String){self.tag=tag;self.positiveTerminal=positiveTerminal;self.negativeTerminal=negativeTerminal}
    public var wiringHealthy:Bool {!commonedIncorrectly && positiveTerminal != negativeTerminal}
}
public struct BurnerFieldTerminalMap: Sendable, Codable {
    public var pilot=BurnerTerminalCircuit(tag:"PILOT",positiveTerminal:"PILOT+",negativeTerminal:"PILOT-")
    public var lowFire=BurnerTerminalCircuit(tag:"LOW-FIRE",positiveTerminal:"LOW+",negativeTerminal:"LOW-")
    public var highFire=BurnerTerminalCircuit(tag:"HIGH-FIRE",positiveTerminal:"HIGH+",negativeTerminal:"HIGH-")
    public var ignitionPrimary="IGN"; public var flameSense="ION"; public var earth="EARTH"
    public init(){}
    public var findings:[String] { [pilot,lowFire,highFire].filter{!$0.wiringHealthy}.map{"burner output wiring fault: \($0.tag)"} }
}
