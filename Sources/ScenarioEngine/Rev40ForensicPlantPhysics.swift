import Foundation

public struct EEStationHeader: Sendable, Codable, Equatable {
    public var suctionPSI = 82.0, dischargePSI = 185.0, demand = 2.1
    public var unitShares:[String:Double] = ["COMP-1":0.5,"COMP-2":0.5]
    public init(){}
    public mutating func balance(available:[String:Double], dt:Double) {
        let total=max(0.001,available.values.reduce(0,+)); unitShares.removeAll(keepingCapacity:true); for (id,v) in available { unitShares[id]=v/total }
        let capacity=available.values.reduce(0,+); dischargePSI += ((165 + capacity*18 - demand*8)-dischargePSI)*min(1,dt/15)
        suctionPSI += ((88-demand*3)-suctionPSI)*min(1,dt/20)
    }
}

public struct EEPVDiagramPoint: Sendable, Codable, Equatable { public var crankDeg:Double; public var pressurePSI:Double; public var volumeFraction:Double }
public struct EERecipThrowPhysics: Sendable, Codable, Equatable {
    public var id:String; public var boreIn=8.0, strokeIn=6.0, rodIn=2.0, suctionPSI=85.0, dischargePSI=185.0, clearance=0.12
    public var suctionValveHealth=1.0, dischargeValveHealth=1.0
    public init(id:String){self.id=id}
    public func pvDiagram(samples:Int=72)->[EEPVDiagramPoint] { (0..<max(8,samples)).map { i in let a=Double(i)/Double(max(1,samples-1))*360; let v=clearance + (1-clearance)*(1-cos(a * .pi/180))/2; let compression=a < 180; let leak=(2-suctionValveHealth-dischargeValveHealth)*0.12; let p = compression ? suctionPSI + (dischargePSI-suctionPSI)*pow(max(0.001,v),0.55)*(1-leak) : dischargePSI-(dischargePSI-suctionPSI)*pow(max(0.001,1-v),0.65)*(1-leak); return .init(crankDeg:a,pressurePSI:max(suctionPSI*0.8,p),volumeFraction:v) } }
    public var pistonAreaIn2:Double { .pi*boreIn*boreIn/4 }
    public var rodAreaIn2:Double { .pi*rodIn*rodIn/4 }
    public var compressionRodLoadLbf:Double { dischargePSI*pistonAreaIn2 - suctionPSI*(pistonAreaIn2-rodAreaIn2) }
}

public struct EEVibrationSpectrumBin: Sendable, Codable, Equatable { public var order:Double; public var amplitude:Double; public var label:String }
public struct EEVibrationAnalyzer: Sendable, Codable, Equatable {
    public init(){}
    public func spectrum(rpm:Double, valveHealth:Double, rodDropMM:Double)->[EEVibrationSpectrumBin] { let fault=max(0,1-valveHealth); return [
        .init(order:1,amplitude:0.08+abs(rodDropMM)*0.15,label:"1× running"),
        .init(order:2,amplitude:0.04+abs(rodDropMM)*0.08,label:"2× running"),
        .init(order:4,amplitude:0.03+fault*0.55,label:"valve impact band"),
        .init(order:8,amplitude:0.02+fault*0.8,label:"high-frequency impact") ] }
}

public struct EEMotorEquivalentCircuit: Sendable, Codable, Equatable {
    public var lineVoltage=480.0, frequency=60.0, poles=4.0, statorR=0.18, rotorR=0.14, leakageX=0.55, slip=0.025
    public init(){}
    public var synchronousRPM:Double { 120*frequency/poles }
    public var rotorRPM:Double { synchronousRPM*(1-slip) }
    public var phaseCurrent:Double { let v=lineVoltage/sqrt(3); return v/sqrt(pow(statorR+rotorR/max(0.005,slip),2)+pow(leakageX,2)) }
    public var copperLossW:Double { 3*phaseCurrent*phaseCurrent*statorR }
}

public enum EEVFDStage:String,CaseIterable,Sendable,Codable { case input, rectifier, precharge, dcBus, inverter, motor }
public struct EEVFDInternals: Sendable, Codable, Equatable {
    public var inputVAC=480.0, dcBusV=648.0, capacitorHealth=1.0, prechargeComplete=true, carrierHz=4000.0, modulation=0.72, dcRippleV=3.0
    public init(){}
    public mutating func tick(load:Double,dt:Double){ let target=inputVAC*sqrt(2)*0.955; dcBusV += (target-dcBusV)*min(1,dt/0.25); dcRippleV=2+load*8/max(0.2,capacitorHealth); modulation=max(0,min(1,load)) }
}

public struct EETripCurvePoint: Sendable, Codable, Equatable { public var multiple:Double; public var seconds:Double; public init(multiple:Double,seconds:Double){self.multiple=multiple;self.seconds=seconds} }
public struct EETripCurve: Sendable, Codable, Equatable {
    public var id:String; public var points:[EETripCurvePoint]
    public init(id:String,points:[EETripCurvePoint]){self.id=id;self.points=points.sorted{$0.multiple<$1.multiple}}
    public func tripTime(multiple:Double)->Double? { guard multiple>=points.first?.multiple ?? .infinity else{return nil}; for p in points where multiple<=p.multiple{return p.seconds}; return points.last?.seconds }
}
public struct EECoordinationStudy: Sendable, Codable, Equatable { public var upstream:EETripCurve; public var downstream:EETripCurve; public init(upstream:EETripCurve,downstream:EETripCurve){self.upstream=upstream;self.downstream=downstream}; public func selective(at multiple:Double)->Bool { guard let u=upstream.tripTime(multiple:multiple),let d=downstream.tripTime(multiple:multiple) else{return false}; return d < u } }

public struct EEUPSCharger: Sendable, Codable, Equatable { public var acAvailable=true, chargerHealthy=true, batterySOC=1.0, dcV=24.4, loadA=5.0; public init(){}; public mutating func tick(dt:Double){ if acAvailable && chargerHealthy { batterySOC=min(1,batterySOC+dt/7200);dcV=24.4 } else { batterySOC=max(0,batterySOC-loadA*dt/160000);dcV=19.5+4.5*batterySOC } } }

public enum EEAIChannelFault:String,CaseIterable,Sendable,Codable { case none, openLoop, shorted, offset, gain, adcStuck, fieldPowerLost }
public struct EEAnalogInputChannel: Sendable, Codable, Equatable {
    public var id:String; public var fault:EEAIChannelFault = .none; public var offsetMA=0.0, gain=1.0, adcBits=16; public init(id:String){self.id=id}
    public func sample(mA:Double)->Double { switch fault { case .openLoop,.fieldPowerLost:return 0; case .shorted:return 20; case .adcStuck:return 12; default:break }; let x=max(0,min(24,(mA+offsetMA)*gain)); let n=pow(2,Double(adcBits))-1; return (x/24*n).rounded()/n*24 }
}

public struct EESwitchPort: Sendable, Codable, Equatable { public var id:String; public var up=true; public var errors=0; public var latencyMS=0.2; public init(id:String){self.id=id} }
public struct EEManagedSwitch: Sendable, Codable, Equatable { public var id:String; public var ports:[EESwitchPort]; public var activeUplink=0; public init(id:String,ports:Int){self.id=id;self.ports=(0..<ports).map{EESwitchPort(id:"P\($0+1)")}}; public mutating func failover(){ if ports.indices.contains(activeUplink){ports[activeUplink].up=false}; activeUplink=min(ports.count-1,activeUplink+1) } }

public struct EEHistorianSample: Sendable, Codable, Equatable { public var t:Double; public var value:Double; public init(t:Double,value:Double){self.t=t;self.value=value} }
public struct EEHistorianReconstructor: Sendable, Codable, Equatable { public init(){}; public func value(at t:Double,samples:[EEHistorianSample])->Double? { let s=samples.sorted{$0.t<$1.t}; guard let a=s.last(where:{$0.t<=t}) else{return nil}; guard let b=s.first(where:{$0.t>=t}), b.t != a.t else{return a.value}; let f=(t-a.t)/(b.t-a.t); return a.value+(b.value-a.value)*f } }

public struct EEValveSignaturePoint: Sendable, Codable, Equatable { public var command:Double; public var travel:Double; public var pressure:Double }
public struct EEValveSignatureAnalyzer: Sendable, Codable, Equatable { public init(){}; public func signature(stiction:Double,airPSI:Double)->[EEValveSignaturePoint] { stride(from:0.0,through:100.0,by:10).map{ c in let dead=stiction*100; let travel=max(0,c-dead)*(max(0,min(1,(airPSI-20)/80))); return .init(command:c,travel:min(100,travel),pressure:airPSI) } } }

public struct EECalibrationRecord: Sendable, Codable, Equatable { public var identity:String; public var asFound:[Double]; public var asLeft:[Double]; public var technician:String; public var timestamp:Double; public init(identity:String,asFound:[Double],asLeft:[Double],technician:String="player",timestamp:Double=0){self.identity=identity;self.asFound=asFound;self.asLeft=asLeft;self.technician=technician;self.timestamp=timestamp}; public var maxAsFoundError:Double { zip(asFound,asLeft).map{abs($0-$1)}.max() ?? 0 } }

public enum EEDrawingSurface:String,CaseIterable,Sendable,Codable { case pAndID, oneLine, elementary, loopSheet, ladder, hmi, physical3D }
public struct EEDrawingIdentity: Sendable, Codable, Equatable { public var identity:String; public var bindings:[EEDrawingSurface:String]; public init(identity:String,bindings:[EEDrawingSurface:String]){self.identity=identity;self.bindings=bindings} }

public struct EEForensicPlantRev40: Sendable, Codable, Equatable {
    public var rev39=EEIntegratedPlantRev39(); public var header=EEStationHeader(); public var compressorThrows=[EERecipThrowPhysics(id:"COMP-1-T1"),EERecipThrowPhysics(id:"COMP-2-T1")]; public var motor=EEMotorEquivalentCircuit(); public var vfd=EEVFDInternals(); public var ups=EEUPSCharger(); public var ai=EEAnalogInputChannel(id:"AI-2:3"); public var networkSwitch=EEManagedSwitch(id:"SW-CTRL-1",ports:4); public var calibration:[EECalibrationRecord]=[]
    public var identities=[EEDrawingIdentity(identity:"PIT-401",bindings:[.pAndID:"PIT-401",.loopSheet:"LOOP-401",.ladder:"PIT401_PV",.hmi:"UNIT2.DISCH",.physical3D:"COMP2/JB4/PIT401"])]
    public init(){}
    public mutating func tick(seconds:Double){rev39.tick(seconds:seconds); let avail=["COMP-1":0.9,"COMP-2":max(0.1,min(1,rev39.base.unit.rpm/1250))];header.balance(available:avail,dt:seconds); for i in compressorThrows.indices{compressorThrows[i].suctionPSI=header.suctionPSI;compressorThrows[i].dischargePSI=header.dischargePSI}; let load=max(0.1,min(1,rev39.base.unit.rpm/1250));vfd.tick(load:load,dt:seconds);ups.tick(dt:seconds)}
}
