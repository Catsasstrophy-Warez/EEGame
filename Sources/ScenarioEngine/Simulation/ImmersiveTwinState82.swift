import Foundation

public enum EECabinetAccess82: String, Codable, CaseIterable, Sendable {
    case closed="Closed", doorOpen="Door Open", deadFrontRemoved="Dead Front Removed", bucketWithdrawn="Bucket Withdrawn"
}
public enum EEVisualMode82: String, Codable, CaseIterable, Sendable {
    case normal="Normal", electrical="Electrical", thermal="Thermal", goldenThread="Golden Thread"
}
public struct EEComponentTelemetry82: Codable, Equatable, Sendable {
    public var identity:String
    public var voltage:Double
    public var currentA:Double
    public var temperatureC:Double
    public var energized:Bool
    public var highlighted:Bool
}
public enum EEImmersiveTwin82 {
    public static let goldenRoute=["PLC DO4","TB1:12","W-1207","JB-14","SOL-101","XV-101","PROC-101"]
    public static func telemetry(identity:String, simulation:EESimulationCoordinator75, failure:EEFailureMode79)->EEComponentTelemetry82 {
        let chain=EEFacilityTwin80.causalChain(failure:failure)
        let observed=chain.first{$0.identity==identity}?.observed ?? true
        let voltage:Double
        switch identity {
        case "TB1:12": voltage=simulation.nodeVoltage78(.tb112)
        case "SOL-101","XV-101": voltage=simulation.nodeVoltage78(.sol101)
        case "PIT-101": voltage=simulation.nodeVoltage78(.pit101)
        default: voltage=0
        }
        let heatBoost:Double
        switch failure {
        case .healthy: heatBoost=0
        case .highResistance: heatBoost=(identity=="TB1:12" || identity=="W-1207") ? 55:4
        case .openCircuit: heatBoost=1
        case .shortToGround: heatBoost=(identity=="W-1207" || identity=="TB1:12") ? 80:8
        }
        return .init(identity:identity,voltage:voltage,currentA:simulation.snapshot.currentA,
                     temperatureC:simulation.snapshot.temperatureC+heatBoost,
                     energized:observed && voltage > 1,highlighted:goldenRoute.contains(identity))
    }
}
