import Foundation

// MARK: - Vera Mentor: standards routing
//
// Ported from the I&E Trainer app's VeraStandardsNavigator.swift. Routes a
// free-text question to the right authority family before Vera discusses
// technical detail, independent of the citation index's domain+keyword
// retrieval. Deliberately conservative and keyword-based until a licensed
// standards retrieval source is connected — same discipline as the rest of
// this file's knowledge base: name the controlling authority, never the
// controlling text.

public enum EEVeraStandardsHazard: String, Codable, Sendable, CaseIterable {
    case shock
    case arcFlash
    case installation
    case hazardousLocation
    case controlSystem
    case motorAndDrive
    case groundingAndBonding
    case maintenance
}

public struct EEVeraStandardsRoute: Codable, Sendable, Equatable {
    public let hazards: [EEVeraStandardsHazard]
    public let authorities: [String]
    public let verificationQuestions: [String]
    public let safetyStopTriggers: [String]

    public init(hazards: [EEVeraStandardsHazard], authorities: [String], verificationQuestions: [String], safetyStopTriggers: [String]) {
        self.hazards = hazards; self.authorities = authorities
        self.verificationQuestions = verificationQuestions; self.safetyStopTriggers = safetyStopTriggers
    }
}

public enum EEVeraStandardsNavigator {
    public static func route(question: String, domain: EEVeraMentorDomain = .instrumentation) -> EEVeraStandardsRoute {
        let text = question.lowercased()
        var hazards: [EEVeraStandardsHazard] = []
        func add(_ hazard: EEVeraStandardsHazard) { if !hazards.contains(hazard) { hazards.append(hazard) } }

        if text.contains("arc") || text.contains("incident energy") || text.contains("energized") || text.contains("flash") { add(.arcFlash) }
        if text.contains("shock") || text.contains("approach boundary") || text.contains("exposed") { add(.shock) }
        if text.contains("class i") || text.contains("division") || text.contains("zone") || text.contains("intrinsic") || text.contains("seal-off") || text.contains("methane") { add(.hazardousLocation) }
        if text.contains("ground") || text.contains("bond") || text.contains("neutral") { add(.groundingAndBonding) }
        if text.contains("motor") || text.contains("vfd") || text.contains("overload") || text.contains("starter") { add(.motorAndDrive) }
        if text.contains("plc") || text.contains("logix") || text.contains("ethernet/ip") || text.contains("interlock") || text.contains("hmi") || text.contains("rung") || text.contains("ladder") { add(.controlSystem) }
        if text.contains("ampacity") || text.contains("conduit") || text.contains("wire") || text.contains("installation") || text.contains("breaker") { add(.installation) }
        if text.contains("maintenance") || text.contains("inspection") || text.contains("condition of maintenance") { add(.maintenance) }
        if hazards.isEmpty {
            switch domain {
            case .electrical: hazards = [.installation, .groundingAndBonding]
            case .plcAutomation: hazards = [.controlSystem]
            case .processSafety, .naturalGas, .coalMining: hazards = [.hazardousLocation, .maintenance]
            case .rotatingEquipment: hazards = [.motorAndDrive, .maintenance]
            case .instrumentation: hazards = [.maintenance]
            }
        }

        var authorities = ["Adopted NEC/NFPA 70 edition and AHJ amendments"]
        if hazards.contains(.shock) || hazards.contains(.arcFlash) || hazards.contains(.maintenance) {
            authorities.insert("NFPA 70E adopted edition and employer electrical safety program", at: 0)
        }
        if hazards.contains(.shock) || hazards.contains(.arcFlash) {
            authorities.append("OSHA 29 CFR 1910 Subpart S work-practice requirements")
        }
        if hazards.contains(.hazardousLocation) {
            authorities.append("Area-classification drawings, equipment listing, API RP 500/505 where applicable, and AHJ")
        }
        if hazards.contains(.controlSystem) {
            authorities.append("Approved controls-management procedure, running-project revision, OEM manuals, and authorized controls owner")
        }
        if hazards.contains(.motorAndDrive) {
            authorities.append("Equipment nameplate, manufacturer instructions, protection study, and approved one-line")
        }

        let questions = [
            "Which edition and jurisdiction are adopted, and are there AHJ amendments?",
            "Is this an installation question, a workplace safety question, a maintenance question, or a design/EOR question?",
            "What exact equipment marking, nameplate, drawing revision, and operating state control the decision?",
            "Which article, section, table, manufacturer instruction, or site procedure must be verified in the licensed source?"
        ]
        var stops = [
            "Do not treat a remembered article number, field label, or quick-reference value as final approval.",
            "Stop if the work would expose personnel to energized parts without an approved energized-work method and required PPE.",
            "Escalate stamped design, classified-area, protection-study, safety-system, or AHJ disputes to the responsible authority."
        ]
        if hazards.contains(.controlSystem) {
            stops.append("Do not force, inhibit, bypass, download, or make an online edit to a live control or safety system without authorization, change control, and rollback planning.")
        }
        if hazards.contains(.hazardousLocation) {
            stops.append("Stop when classification, gas test, equipment marking, seal/interface, or intrinsic-safety parameters are unknown.")
        }
        return EEVeraStandardsRoute(hazards: hazards, authorities: authorities, verificationQuestions: questions, safetyStopTriggers: stops)
    }
}
