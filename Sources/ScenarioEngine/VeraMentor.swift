import Foundation

// MARK: - Vera Mentor
//
// Ported from the I&E Trainer app's Vera mentor module and adapted to
// ElectricEngineerGame's domains and conventions. Vera is a safety-gated,
// deterministic peer mentor: it never replaces the engineer of record, an
// AHJ, or the player's own energy-isolation/permit confirmations, and it
// has no connected or on-device model behind it yet — only the explicit
// extension point for one (`EEVeraMentorProvider`).
//
// The safety gate (`EEVeraSafetyRouter.gate`) always runs before any
// provider is consulted, and a provider receives only the already-gated
// context/response — it cannot be used to bypass the gate.

public enum EEVeraMentorDomain: String, CaseIterable, Codable, Sendable, Identifiable {
    case electrical
    case instrumentation
    case naturalGas
    case coalMining
    case rotatingEquipment
    case processSafety

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .electrical: "Electrical"
        case .instrumentation: "Instrumentation & controls"
        case .naturalGas: "Natural gas process"
        case .coalMining: "Coal mining & prep plant"
        case .rotatingEquipment: "Rotating equipment"
        case .processSafety: "Process safety"
        }
    }
}

public struct EEVeraMentorPathway: Sendable {
    public let domain: EEVeraMentorDomain
    public let independentEvidence: [String]
    public let escalationTriggers: [String]
}

public enum EEVeraMentorDomainKnowledge {
    public static func pathway(for domain: EEVeraMentorDomain) -> EEVeraMentorPathway {
        switch domain {
        case .electrical:
            EEVeraMentorPathway(domain: domain,
                independentEvidence: ["Verify source and control power at the correct test points", "Check phase-to-phase/phase-to-ground condition against the approved procedure", "Compare protective-device, contactor, overload, and PLC permissive states"],
                escalationTriggers: ["Arc-flash boundary or energized work is involved", "Backfeed, induced voltage, or an unidentified source is possible", "Protective devices, ESD, or interlocks would need to be bypassed"])
        case .instrumentation:
            EEVeraMentorPathway(domain: domain,
                independentEvidence: ["Compare a safe independent process indication with the instrument PV", "Trace the 4-20 mA/pulse/discrete signal at defined boundaries", "Confirm loop power, polarity, terminations, barrier/fuse status, and AI scaling"],
                escalationTriggers: ["Calibration would alter a protective, custody, or emissions function", "Opening a hazardous enclosure or disturbing impulse tubing is required", "The instrument identity, range, or approved test point is uncertain"])
        case .naturalGas:
            EEVeraMentorPathway(domain: domain,
                independentEvidence: ["Use approved area classification drawings, P&IDs, and the current operating procedure", "Compare pressure, temperature, flow, and valve position with independent indications", "Check gas detection, ESD, flame detection, compressor permissives, and instrument-air status"],
                escalationTriggers: ["Any confirmed/suspected release, fire, loss of containment, or unexplained detector response", "Pressure boundary, relief, ESD, compressor protection, or custody measurement is affected", "The area classification, gas test, permit, or operating state is not known"])
        case .coalMining:
            EEVeraMentorPathway(domain: domain,
                independentEvidence: ["Confirm methane% and CO ppm at the affected ventilation branch before anything else", "Compare shearer/AFC/shield telemetry against the last known-good baseline", "Check the incident recorder for the earliest abnormal frame, not the loudest one"],
                escalationTriggers: ["Methane reads above the alarm threshold at any monitored sensor", "A hydraulic shield, AFC, or belt protective interlock is affected", "Ventilation fan pressure or airflow has dropped below the approved minimum"])
        case .rotatingEquipment:
            EEVeraMentorPathway(domain: domain,
                independentEvidence: ["Confirm process conditions and local mechanical indicators before touching a probe or coupling", "Compare redundant vibration/speed/temperature channels, not one", "Check lube oil, seal gas, cooling, instrument air, and driver permissives", "Preserve trip logs and pre-trip trends before any reset"],
                escalationTriggers: ["Protection is active or a restart could damage equipment", "A guard, coupling, or pressure boundary would be disturbed", "The cause-and-effect or trip-reset authority is unclear"])
        case .processSafety:
            EEVeraMentorPathway(domain: domain,
                independentEvidence: ["Review current cause-and-effect, proof-test, bypass, and impairment records", "Confirm alarm, trip, final element, and feedback independently", "Record the exact device identity, state, time, and permissive/interlock context"],
                escalationTriggers: ["A safety function is unavailable, bypassed, or repeatedly failing", "A test could initiate a hazardous state", "The required impairment response or compensating measure is unknown"])
        }
    }
}

public enum EEVeraMentorSafetyStatus: String, CaseIterable, Codable, Sendable {
    case unknown
    case confirmedSafe
    case stopAndEscalate
}

public struct EEVeraMentorContext: Codable, Sendable {
    public var domain: EEVeraMentorDomain = .instrumentation
    public var symptom: String = ""
    public var equipmentID: String = ""
    public var areaClassificationKnown = false
    public var gasTestCurrent = false
    public var energyIsolatedAndVerified = false
    public var identityConfirmed = false
    public var safetyFunctionAffected = false
    public var evidenceCount = 0
    public var firstDivergence: String?

    public init(domain: EEVeraMentorDomain = .instrumentation, symptom: String = "", equipmentID: String = "") {
        self.domain = domain
        self.symptom = symptom
        self.equipmentID = equipmentID
    }
}

public struct EEVeraMentorDiagnosticResponse: Sendable {
    public let status: EEVeraMentorSafetyStatus
    public let title: String
    public let message: String
    public let nextActions: [String]
    public let pathway: EEVeraMentorPathway
}

public enum EEVeraMentorDiagnosticEngine {
    public static func response(for context: EEVeraMentorContext) -> EEVeraMentorDiagnosticResponse {
        let pathway = EEVeraMentorDomainKnowledge.pathway(for: context.domain)
        if context.safetyFunctionAffected && !context.energyIsolatedAndVerified {
            return EEVeraMentorDiagnosticResponse(status: .stopAndEscalate, title: "Protective function affected",
                message: "Stop troubleshooting at the equipment boundary. Do not defeat, force, jumper, or reset a protective function to continue.",
                nextActions: ["Notify the responsible operator/control-room authority", "Confirm the required safe state and compensating measures", "Use only an approved proof-test or restoration procedure with qualified personnel"],
                pathway: pathway)
        }
        if !context.identityConfirmed {
            return EEVeraMentorDiagnosticResponse(status: .stopAndEscalate, title: "Confirm the asset before measuring",
                message: "Vera will not infer a device identity from a label or screen alone. Match the tag, drawing, terminal, and current procedure before touching the circuit.",
                nextActions: ["Confirm station, unit, tag, service, and revision-controlled drawing", "Record the normal operating state and the exact symptom", "Stop if the physical device and control-system identity do not agree"],
                pathway: pathway)
        }
        if context.domain == .naturalGas || context.domain == .coalMining {
            if !context.areaClassificationKnown || !context.gasTestCurrent {
                return EEVeraMentorDiagnosticResponse(status: .stopAndEscalate, title: "Area and atmosphere gate",
                    message: "Before field measurements in a gassy area, confirm the area classification, current gas-test/permit requirements, and that the selected instruments and work method are approved for that area.",
                    nextActions: ["Review the area classification drawing and site permit requirements", "Confirm current gas test and required continuous monitoring", "Use only approved equipment and stop on any unexpected gas, fire, or detector indication"],
                    pathway: pathway)
            }
        }
        if !context.energyIsolatedAndVerified {
            return EEVeraMentorDiagnosticResponse(status: .stopAndEscalate, title: "Establish zero energy or approved test boundary",
                message: "The next diagnostic step depends on whether the work is energized, de-energized, or covered by an approved live-test method. Do not assume a switch, HMI state, or open fuse proves isolation.",
                nextActions: ["Identify electrical, pneumatic, hydraulic, pressure, thermal, mechanical, and stored energy", "Apply the approved isolation and verification procedure", "Verify at the exact points that could be exposed, including possible backfeed or reaccumulation"],
                pathway: pathway)
        }
        if context.evidenceCount == 0 {
            return EEVeraMentorDiagnosticResponse(status: .confirmedSafe, title: "Build an evidence anchor",
                message: "Start with the earliest safe, independent observation. Separate process truth from the instrument/signal path before changing configuration.",
                nextActions: pathway.independentEvidence.prefix(2).map { $0 } + ["Record the reading, units, test point, instrument ID, time, and operating state"],
                pathway: pathway)
        }
        if let firstDivergence = context.firstDivergence, !firstDivergence.isEmpty {
            return EEVeraMentorDiagnosticResponse(status: .confirmedSafe, title: "First divergence: \(firstDivergence)",
                message: "The evidence has narrowed the fault boundary. Verify the boundary with one independent confirmation before repair, then preserve the original condition for the debrief.",
                nextActions: ["Repeat or cross-check the abnormal result with an independent method", "Check the upstream/downstream interface at the boundary", "Repair only under the approved procedure, then run restoration proof"],
                pathway: pathway)
        }
        return EEVeraMentorDiagnosticResponse(status: .confirmedSafe, title: "Continue the signal-chain investigation",
            message: "Do not choose the first abnormal indication as the root cause. Compare the process, field device, wiring/barrier, I/O, logic, and display in order until the first disagreement is proven.",
            nextActions: ["Test the next signal-chain boundary with the most discriminating safe method", "Capture both the result and the expected value", "Reassess the remaining candidates after each independent result"],
            pathway: pathway)
    }
}

// MARK: - Provider boundary

public enum EEVeraMentorMode: String, CaseIterable, Codable, Sendable {
    case offlineDeterministic
    case onDeviceModel
    case connectedEnhancement
}

public struct EEVeraMentorReply: Sendable {
    public let mode: EEVeraMentorMode
    public let safety: EEVeraMentorDiagnosticResponse
    public let explanation: String
    public let citations: [EEVeraCitation]

    public init(mode: EEVeraMentorMode, safety: EEVeraMentorDiagnosticResponse, explanation: String, citations: [EEVeraCitation] = []) {
        self.mode = mode; self.safety = safety; self.explanation = explanation; self.citations = citations
    }
}

/// Implementations receive the already-gated context/response and may enrich
/// language, but must not override `EEVeraMentorDiagnosticEngine`'s
/// stop/escalate result. No implementation ships in this app yet.
public protocol EEVeraMentorProvider: Sendable {
    var mode: EEVeraMentorMode { get }
    func reply(for context: EEVeraMentorContext, safety: EEVeraMentorDiagnosticResponse) async -> EEVeraMentorReply
}

public enum EEVeraSafetyRouter {
    public static func gate(_ context: EEVeraMentorContext) -> EEVeraMentorDiagnosticResponse {
        EEVeraMentorDiagnosticEngine.response(for: context)
    }
}

public struct EEVeraOfflineProvider: EEVeraMentorProvider {
    public let mode = EEVeraMentorMode.offlineDeterministic
    public init() {}

    public func reply(for context: EEVeraMentorContext, safety: EEVeraMentorDiagnosticResponse) async -> EEVeraMentorReply {
        let explanation: String
        if safety.status == .stopAndEscalate {
            explanation = "Vera is holding the diagnostic path at the safety boundary. Resolve the required site conditions before selecting a measurement."
        } else if let divergence = context.firstDivergence, !divergence.isEmpty {
            explanation = "The working boundary is \(divergence). Preserve the original evidence, independently confirm the disagreement, and follow the approved repair and restoration procedure."
        } else {
            explanation = "Use the next discriminating observation to separate process truth from the signal path. Record the test point, instrument, units, operating state, expected value, and result."
        }
        return EEVeraMentorReply(mode: mode, safety: safety, explanation: explanation)
    }
}

public enum EEVeraMentorRuntime {
    public static let offline = EEVeraOfflineProvider()

    /// Safety is evaluated locally before any provider is called. This is the
    /// single entry point UI code should use for mentor responses.
    public static func reply(for context: EEVeraMentorContext, provider: EEVeraMentorProvider? = nil) async -> EEVeraMentorReply {
        let safety = EEVeraSafetyRouter.gate(context)
        let selectedProvider = provider ?? offline
        let base = await selectedProvider.reply(for: context, safety: safety)
        // Citations are attached here, after the provider runs, from the
        // bundled reference index — never invented by a provider. A stop
        // verdict still gets citations (the player needs to know where the
        // isolation/permit/area-classification requirement comes from too).
        let query = [context.symptom, context.firstDivergence ?? "", safety.title].joined(separator: " ")
        let citations = EEVeraReferenceIndex.retrieve(domain: context.domain, query: query)
        return EEVeraMentorReply(mode: base.mode, safety: base.safety, explanation: base.explanation, citations: citations)
    }
}
