import Foundation
import ElectricalCore

// Rev22: field wiring, junction boxes, signal infrastructure, burner fuel train, and deeper final-control truth.
// Educational simulation only. Vendor-aware concepts are not a certified implementation of any OEM safety system.

public enum FieldSignalClass: String, Sendable, Codable { case analog4to20, discrete24V, thermocouple, rtd, can, rs485, ignition, protectiveEarth }
public enum ConductorFault: String, Sendable, Codable, Hashable { case open, shortToCommon, shortToSupply, groundLeakage, highResistance, reversedPolarity, wet }

public struct FieldTerminal: Sendable, Codable, Hashable {
    public var tag: String; public var number: String; public var torqueFraction: Double = 1; public var corrosion: Double = 0; public var wet: Bool = false
    public init(tag: String, number: String) { self.tag=tag; self.number=number }
    public var contactResistanceOhms: Double { 0.01 + pow(max(0,1-torqueFraction),2)*2 + corrosion*4 + (wet ? 0.2 : 0) }
}

public struct FieldConductor: Sendable, Codable {
    public var wireNumber: String; public var signalClass: FieldSignalClass; public var resistanceOhms: Double; public var faults: Set<ConductorFault> = []
    public init(_ wireNumber:String, _ signalClass:FieldSignalClass, resistanceOhms:Double=0.2){self.wireNumber=wireNumber;self.signalClass=signalClass;self.resistanceOhms=resistanceOhms}
    public func deliveredVoltage(source: Double, current: Double) -> Double? {
        if faults.contains(.open) { return nil }
        if faults.contains(.shortToCommon) { return 0 }
        var v = source - current * (resistanceOhms + (faults.contains(.highResistance) ? 25 : 0))
        if faults.contains(.shortToSupply) { v = max(v, 24) }
        if faults.contains(.reversedPolarity) { v = -v }
        if faults.contains(.groundLeakage) || faults.contains(.wet) { v *= 0.7 }
        return v
    }
}

public struct ShieldDrain: Sendable, Codable {
    public var groundedAtSource=false; public var groundedAtField=false; public var continuous=true; public var groundPotentialVolts=0.0
    public init() {}
    public var groundLoop: Bool { groundedAtSource && groundedAtField && abs(groundPotentialVolts) > 0.05 }
    public var inducedErrorMilliamps: Double { guard continuous else { return 0.08 }; return groundLoop ? min(2,abs(groundPotentialVolts)*0.12) : 0 }
}

public struct InstrumentFieldCable: Sendable, Codable {
    public var tag:String; public var conductors:[FieldConductor]; public var shield=ShieldDrain(); public var waterIngress=0.0
    public init(tag:String, conductors:[FieldConductor]){self.tag=tag;self.conductors=conductors}
    public var insulationMegohms: Double { max(0.01, 500 * (1-waterIngress) * (1-waterIngress)) }
}

public struct JunctionBox: Sendable, Codable {
    public var tag:String; public var terminals:[FieldTerminal]; public var waterIngress=0.0
    public init(tag:String, terminals:[FieldTerminal]){self.tag=tag;self.terminals=terminals}
    public var degradedTerminalCount:Int { terminals.filter{$0.contactResistanceOhms > 0.1}.count }
}

public enum SignalConditionerFault:String,Sendable,Codable,Hashable { case open, saturated, offset, lossOfPower }
public struct AnalogSignalConditioner: Sendable, Codable {
    public var powered=true; public var isolation=true; public var offsetMA=0.0; public var faults:Set<SignalConditionerFault>=[]
    public init(){}
    public func output(inputMA:Double)->Double? { guard powered && !faults.contains(.lossOfPower) && !faults.contains(.open) else{return nil}; if faults.contains(.saturated){return 20}; return min(22,max(0,inputMA+offsetMA+(faults.contains(.offset) ? 1.5:0))) }
}

public struct AnalogGoldenThreadInstallation: Sendable {
    public var processValue=0.0; public var transmitter=IndicatingTransmitter(tag:"PIT-401",kind:.PIT,lrv:0,urv:300)
    public var cable=InstrumentFieldCable(tag:"CBL-PIT-401",conductors:[FieldConductor("401+",.analog4to20),FieldConductor("401-",.analog4to20)])
    public var junctionBox=JunctionBox(tag:"JB-4",terminals:[FieldTerminal(tag:"JB-4",number:"12"),FieldTerminal(tag:"JB-4",number:"13")])
    public var conditioner=AnalogSignalConditioner(); public var ai=AnalogInputElectricalModel()
    public init(){}
    public mutating func step(dt:Double){ transmitter.step(actual:processValue,dt:dt); var ma=transmitter.milliAmps + cable.shield.inducedErrorMilliamps; let r=junctionBox.terminals.reduce(0){$0+$1.contactResistanceOhms}; ma=max(0,ma-r*0.02); if cable.waterIngress>0.5 { ma *= 0.92 }; ma=conditioner.output(inputMA:ma) ?? 0; ai.loopMilliamps=ma }
}

public enum BurnerFuelFault:String,Sendable,Codable,Hashable { case regulatorFailedClosed, pilotIsolationClosed, pilotOrificePlugged, mainValveStuckClosed, lowSupplyPressure, flameRodContaminated, poorBurnerGround, ignitionSecondaryOpen }
public struct BurnerFuelTrain: Sendable, Codable {
    public var supplyPressurePSI=15.0; public var regulatorSetpointPSI=8.0; public var pilotCommand=false; public var mainCommand=false; public var ignitionCommand=false; public var faults:Set<BurnerFuelFault>=[]
    public private(set) var regulatedPressurePSI=0.0; public private(set) var pilotFlow=false; public private(set) var mainFlow=false; public private(set) var physicalFlame=false; public private(set) var flameProven=false
    public init(){}
    public mutating func step(){ let supply=faults.contains(.lowSupplyPressure) ? min(supplyPressurePSI,1):supplyPressurePSI; regulatedPressurePSI=faults.contains(.regulatorFailedClosed) ? 0:min(supply,regulatorSetpointPSI); pilotFlow=pilotCommand && regulatedPressurePSI>1 && !faults.contains(.pilotIsolationClosed) && !faults.contains(.pilotOrificePlugged); mainFlow=mainCommand && regulatedPressurePSI>1 && !faults.contains(.mainValveStuckClosed); let spark=ignitionCommand && !faults.contains(.ignitionSecondaryOpen); physicalFlame=(pilotFlow && spark) || (physicalFlame && (pilotFlow || mainFlow)); flameProven=physicalFlame && !faults.contains(.flameRodContaminated) && !faults.contains(.poorBurnerGround) }
}

public enum FinalControlFault:String,Sendable,Codable,Hashable { case lowAir, i2pFailed, relayRestricted, packingStiction, feedbackLost, actuatorLeak }
public struct FinalControlAssembly: Sendable, Codable {
    public var commandMA=4.0; public var airSupplyPSI=80.0; public var faults:Set<FinalControlFault>=[]; public private(set)var i2pPSI=3.0; public private(set)var actuatorPSI=0.0; public private(set)var stemPercent=0.0; public private(set)var feedbackPercent:Double?=0
    public init(){}
    public mutating func step(dt:Double){ let pct=min(1,max(0,(commandMA-4)/16)); let supply=faults.contains(.lowAir) ? min(airSupplyPSI,8):airSupplyPSI; i2pPSI=faults.contains(.i2pFailed) ? 0 : min(supply,3+12*pct); var chamber=faults.contains(.relayRestricted) ? i2pPSI*0.35:i2pPSI; if faults.contains(.actuatorLeak){chamber*=0.55}; actuatorPSI=chamber; let target=max(0,min(100,(chamber-3)/12*100)); let rate=faults.contains(.packingStiction) ? 3.0:40.0; let delta=max(-rate*dt,min(rate*dt,target-stemPercent)); stemPercent += delta; feedbackPercent=faults.contains(.feedbackLost) ? nil:stemPercent }
}

public struct Rev22FieldPackage: Sendable {
    public var analog=AnalogGoldenThreadInstallation(); public var burner=BurnerFuelTrain(); public var finalControl=FinalControlAssembly()
    public init(){}
    public mutating func step(dt:Double){analog.step(dt:dt);finalControl.step(dt:dt);burner.step()}
}
