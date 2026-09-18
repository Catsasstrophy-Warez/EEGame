import Foundation

public enum EEProtectionDevice83: String, Codable, CaseIterable, Sendable {
    case disconnect="DS-04", fuseA="F1-04", fuseB="F2-04", fuseC="F3-04", overload="OL-04"
}
public struct EECommissioningState83: Codable, Equatable, Sendable {
    public var disconnectClosed=true
    public var fuseAHealthy=true
    public var fuseBHealthy=true
    public var fuseCHealthy=true
    public var overloadTripped=false
    public var plcDO4=true
    public var solenoidCoilHealthy=true
    public var valveMechanicallyFree=true
    public init() {}
    public var controlPowerAvailable:Bool { disconnectClosed && fuseAHealthy && fuseBHealthy && fuseCHealthy && !overloadTripped }
    public var solenoidEnergized:Bool { controlPowerAvailable && plcDO4 && solenoidCoilHealthy }
    public var valveOpen:Bool { solenoidEnergized && valveMechanicallyFree }
    public mutating func toggle(_ device:EEProtectionDevice83) {
        switch device {
        case .disconnect: disconnectClosed.toggle()
        case .fuseA: fuseAHealthy.toggle()
        case .fuseB: fuseBHealthy.toggle()
        case .fuseC: fuseCHealthy.toggle()
        case .overload: overloadTripped.toggle()
        }
    }
}
public struct EEConductor83: Identifiable, Codable, Hashable, Sendable {
    public let id:String
    public let from:String
    public let to:String
    public let wireNumber:String
    public let domain:EEDomain80
}
public enum EEPhysicalNetwork83 {
    public static let conductors:[EEConductor83] = [
        .init(id:"c1",from:"PLC DO4",to:"TB1:12",wireNumber:"W-1207",domain:.control),
        .init(id:"c2",from:"TB1:12",to:"JB-14",wireNumber:"W-1207",domain:.control),
        .init(id:"c3",from:"JB-14",to:"SOL-101",wireNumber:"W-1207",domain:.control),
        .init(id:"c4",from:"SOL-101",to:"0V",wireNumber:"W-1208",domain:.control),
        .init(id:"c5",from:"PIT-101",to:"AI-04",wireNumber:"W-2011",domain:.instrumentation)
    ]
    public static func energized(_ c:EEConductor83,state:EECommissioningState83)->Bool {
        if c.wireNumber=="W-1207" { return state.controlPowerAvailable && state.plcDO4 }
        if c.wireNumber=="W-1208" { return state.solenoidEnergized }
        return state.controlPowerAvailable
    }
}
public struct EEActuatorCutaway83: Codable, Equatable, Sendable {
    public var coilCurrentA:Double
    public var magneticForceN:Double
    public var plungerPosition:Double
    public var valveStemPosition:Double
    public var processOpen:Bool
}
public enum EEActuation83 {
    public static func solve(state:EECommissioningState83,currentA:Double)->EEActuatorCutaway83 {
        let i=state.solenoidEnergized ? max(0,currentA):0
        let force=min(1,i/0.020)*18
        let plunger=state.solenoidEnergized ? min(1,force/12):0
        let stem=state.valveMechanicallyFree ? plunger:0
        return .init(coilCurrentA:i,magneticForceN:force,plungerPosition:plunger,valveStemPosition:stem,processOpen:stem>0.8)
    }
}
