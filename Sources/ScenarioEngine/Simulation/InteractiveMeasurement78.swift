import Foundation

public enum EEProbeNode78: String, Codable, CaseIterable, Sendable {
    case ground = "0V"
    case source = "24VDC"
    case tb112 = "TB1:12"
    case sol101 = "SOL-101"
    case ai04 = "AI-04"
    case pit101 = "PIT-101"
}

public struct EEProbeMeasurement78: Codable, Equatable, Sendable {
    public var red: EEProbeNode78
    public var black: EEProbeNode78
    public var volts: Double
    public var valid: Bool
    public init(red: EEProbeNode78, black: EEProbeNode78, volts: Double, valid: Bool = true) {
        self.red=red; self.black=black; self.volts=volts; self.valid=valid
    }
}

public extension EESimulationCoordinator75 {
    func nodeVoltage78(_ node: EEProbeNode78) -> Double {
        switch node {
        case .ground: return 0
        case .source: return snapshot.sourceVoltage
        case .tb112, .sol101: return snapshot.terminalVoltage
        case .ai04: return min(10, max(0, snapshot.currentA * 500))
        case .pit101: return min(24, max(0, 4 + snapshot.currentA * 800))
        }
    }

    func measure78(red: EEProbeNode78, black: EEProbeNode78) -> EEProbeMeasurement78 {
        EEProbeMeasurement78(red:red, black:black, volts:nodeVoltage78(red)-nodeVoltage78(black))
    }
}


public enum EEFailureMode79: String, Codable, CaseIterable, Sendable {
    case healthy = "Healthy"
    case highResistance = "High Resistance"
    case openCircuit = "Open Circuit"
    case shortToGround = "Short to Ground"
}

public struct EEScopeSample79: Codable, Equatable, Sendable {
    public var time: Double
    public var channel1: Double
    public var channel2: Double
    public init(time: Double, channel1: Double, channel2: Double) {
        self.time=time; self.channel1=channel1; self.channel2=channel2
    }
}

public struct EEForensicFrame79: Codable, Equatable, Sendable {
    public var time: Double
    public var selectedIdentity: String
    public var redNode: EEProbeNode78
    public var blackNode: EEProbeNode78
    public var measuredVolts: Double
    public var currentA: Double
    public var temperatureC: Double
    public var failure: EEFailureMode79
    public init(time: Double, selectedIdentity: String, redNode: EEProbeNode78, blackNode: EEProbeNode78, measuredVolts: Double, currentA: Double, temperatureC: Double, failure: EEFailureMode79) {
        self.time = time
        self.selectedIdentity = selectedIdentity
        self.redNode = redNode
        self.blackNode = blackNode
        self.measuredVolts = measuredVolts
        self.currentA = currentA
        self.temperatureC = temperatureC
        self.failure = failure
    }
}

public extension EESimulationCoordinator75 {
    func scopeSamples79(red: EEProbeNode78, black: EEProbeNode78, count: Int = 96) -> [EEScopeSample79] {
        let n=max(8,count)
        let base=measure78(red:red,black:black).volts
        return (0..<n).map { i in
            let t=Double(i)/Double(n-1)*0.120
            let ripple=sin(t*Double.pi*120.0)*min(0.15,abs(base)*0.008)
            let plcPulse=(Int(t*1000) % 20 < 10) ? 1.0 : 0.0
            return EEScopeSample79(time:t,channel1:base+ripple,channel2:plcPulse*min(10,abs(base)))
        }
    }
}
