import Foundation

public enum EEFocusAction72: String, Codable, CaseIterable, Sendable {
    case inspect, measure, trace, drawing, history, plot, cutaway
}

public enum EEConstructionLevel72: String, Codable, CaseIterable, Sendable {
    case demonstrate, trace, guidedBuild, independentBuild, commissioningChallenge
}

public enum EEAnalysisKind72: String, Codable, CaseIterable, Sendable {
    case operatingPoint, transient, dcSweep, acSweep, parameterSweep
    case temperatureSweep, tolerance, worstCase, sensitivity
}

public struct EETerminalConnection72: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var from: String
    public var to: String
    public var conductor: String
    public var wireNumber: String
    public var resistanceOhm: Double
    public var temperatureC: Double

    public init(
        id: String,
        from: String,
        to: String,
        conductor: String = "copper",
        wireNumber: String = "",
        resistanceOhm: Double = 0.01,
        temperatureC: Double = 25
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.conductor = conductor
        self.wireNumber = wireNumber
        self.resistanceOhm = resistanceOhm
        self.temperatureC = temperatureC
    }
}

public struct EEElectricalVision72: Codable, Equatable, Sendable {
    public var identity: String
    public var voltageIn: Double
    public var voltageOut: Double
    public var currentA: Double
    public var resistanceOhm: Double
    public var temperatureC: Double

    public var voltageDrop: Double { voltageIn - voltageOut }
    public var powerW: Double { currentA * voltageDrop }

    public init(
        identity: String,
        voltageIn: Double,
        voltageOut: Double,
        currentA: Double,
        resistanceOhm: Double,
        temperatureC: Double
    ) {
        self.identity = identity
        self.voltageIn = voltageIn
        self.voltageOut = voltageOut
        self.currentA = currentA
        self.resistanceOhm = resistanceOhm
        self.temperatureC = temperatureC
    }
}

public struct EEWorkOrder72: Identifiable, Codable, Sendable {
    public let id: String
    public var complaint: String
    public var equipment: String
    public var stage: String
    public var cost: Double
    public var downtimeMinutes: Double

    public init(
        id: String,
        complaint: String,
        equipment: String,
        stage: String = "dispatch",
        cost: Double = 0,
        downtimeMinutes: Double = 0
    ) {
        self.id = id
        self.complaint = complaint
        self.equipment = equipment
        self.stage = stage
        self.cost = cost
        self.downtimeMinutes = downtimeMinutes
    }
}

public struct EEInstrument72: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var kind: String
    public var inputImpedanceOhm: Double?
    public var burdenOhm: Double?
    public var bandwidthHz: Double?

    public init(
        id: String,
        name: String,
        kind: String,
        inputImpedanceOhm: Double? = nil,
        burdenOhm: Double? = nil,
        bandwidthHz: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.inputImpedanceOhm = inputImpedanceOhm
        self.burdenOhm = burdenOhm
        self.bandwidthHz = bandwidthHz
    }
}

public struct EEAnalysisRequest72: Identifiable, Codable, Sendable {
    public let id: String
    public var kind: EEAnalysisKind72
    public var target: String
    public var parameter: String?
    public var start: Double?
    public var stop: Double?
    public var points: Int
}

public struct EECrossDomainThread72: Codable, Sendable {
    public var command: [String]
    public var response: [String]
}

public struct EEIntegratedLabRuntime72: Codable, Sendable {
    public var ux = EECompetitiveUXRuntime71()
    public var constructionLevel: EEConstructionLevel72 = .guidedBuild
    public var connections: [EETerminalConnection72] = []
    public var workOrders: [EEWorkOrder72] = []
    public var instruments: [EEInstrument72] = []
    public var analyses: [EEAnalysisRequest72] = []
    public var focusActions: [EEFocusAction72] = EEFocusAction72.allCases

    public var thread = EECrossDomainThread72(
        command: ["HMI", "PLC", "DO", "TB1:12", "SOL-101", "Actuator", "Valve"],
        response: ["Valve", "Process", "PIT-101", "4-20mA", "AI", "Scaling", "HMI"]
    )

    public init() {
        instruments = [
            .init(id: "DMM-1", name: "Digital Multimeter", kind: "DMM", inputImpedanceOhm: 10_000_000),
            .init(id: "SCOPE-1", name: "4-Channel Scope", kind: "Oscilloscope", inputImpedanceOhm: 1_000_000, bandwidthHz: 100_000_000),
            .init(id: "LC-1", name: "Loop Calibrator", kind: "Loop", burdenOhm: 10)
        ]
    }

    public mutating func addConnection(_ connection: EETerminalConnection72) {
        connections.append(connection)
    }
}
