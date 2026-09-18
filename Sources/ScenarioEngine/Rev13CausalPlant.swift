import Foundation
import ElectricalCore
import CircuitMNA

public struct ProtectiveAccumulator: Sendable, Codable, Equatable {
    public var elapsedAbovePickup=0.0; public var tripped=false
    public init() {}
    public mutating func step(currentMultiple:Double, curve:TimeCurrentCurve, dt:Double) -> Bool {
        guard !tripped else { return true }
        guard currentMultiple > 1, let required=curve.tripTime(multiple:currentMultiple) else { elapsedAbovePickup=max(0,elapsedAbovePickup-dt); return false }
        elapsedAbovePickup += dt
        if elapsedAbovePickup + 1e-12 >= required { tripped=true }
        return tripped
    }
}

public struct Rev13CausalPlantRuntime: Sendable {
    public var time=0.0
    public var energized=true
    public var motorSpeedFraction=1.0
    public var processPressure=100.0
    public var protection=ProtectiveAccumulator()
    public var curve=TimeCurrentCurve(points:[.init(currentMultiple:2,seconds:2),.init(currentMultiple:10,seconds:0.05)])
    public var ledger=CausalEventLedger()
    public var profile=KernelProfile()
    private var faultEvent:Int?
    private var tripEvent:Int?
    public init() {}
    public mutating func injectFault(source:String="M-101") { if faultEvent == nil { faultEvent=ledger.append(time:time,kind:.faultApplied,source:source) } }
    public mutating func step(currentMultiple:Double, dt:Double) {
        time += dt; profile.record(domain:.electricalTransient)
        if faultEvent != nil && energized && protection.step(currentMultiple:currentMultiple,curve:curve,dt:dt) {
            let p=ledger.append(time:time,kind:.protectionTrip,source:"QF-101",causedBy:faultEvent); tripEvent=p
            energized=false
            _=ledger.append(time:time,kind:.busDeenergized,source:"MCC-1",causedBy:p)
        }
        profile.record(domain:.mechanical)
        if !energized { motorSpeedFraction=max(0,motorSpeedFraction-dt*0.5); if motorSpeedFraction > 0 && ledger.events.last?.kind != .motorCoast { _=ledger.append(time:time,kind:.motorCoast,source:"M-101",causedBy:tripEvent) } }
        profile.record(domain:.process)
        processPressure += ((energized ? 100.0 : 20.0)-processPressure)*min(1,dt*0.5)
    }
}

public struct PanelMaintainabilityAudit: Sendable, Equatable {
    public var wireLengthMM:Double; public var crossings:Int; public var inaccessibleTerminals:Int; public var mixedSignalRoutes:Int
    public var penalty:Int { min(100, Int(wireLengthMM/1000)*2 + crossings*3 + inaccessibleTerminals*12 + mixedSignalRoutes*10) }
    public var maintainability:Int { max(0,100-penalty) }
    public init(wireLengthMM:Double,crossings:Int,inaccessibleTerminals:Int,mixedSignalRoutes:Int){self.wireLengthMM=wireLengthMM;self.crossings=crossings;self.inaccessibleTerminals=inaccessibleTerminals;self.mixedSignalRoutes=mixedSignalRoutes}
}
