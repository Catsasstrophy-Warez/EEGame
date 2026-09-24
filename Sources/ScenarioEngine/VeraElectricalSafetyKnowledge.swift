import Foundation

// MARK: - Vera Mentor: operational safety checklist knowledge
//
// Ported from the I&E Trainer app's VeraElectricalSafetyKnowledge.swift.
// Distinct from both the citation index and the code-knowledge authority
// list: each entry here is a disciplined checklist for one recurring
// situation — what to verify, what NOT to infer (a common wrong shortcut),
// and when to stop and escalate — rather than a pointer to a numbered
// article. None of this is standards text; it is original operational
// guidance for asking the right question and locating the controlling
// requirement in the adopted source, same discipline as the rest of Vera's
// knowledge base.

public struct EEVeraSafetyKnowledgeEntry: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let family: String
    public let title: String
    public let verify: [String]
    public let doNotInfer: [String]
    public let escalateWhen: [String]

    public init(id: String, family: String, title: String, verify: [String], doNotInfer: [String], escalateWhen: [String]) {
        self.id = id; self.family = family; self.title = title
        self.verify = verify; self.doNotInfer = doNotInfer; self.escalateWhen = escalateWhen
    }
}

public enum EEVeraElectricalSafetyKnowledge {
    public static let entries: [EEVeraSafetyKnowledgeEntry] = [
        .init(id: "70e-program", family: "NFPA 70E", title: "Electrical safety program",
              verify: ["Employer program, qualified-person criteria, training, job briefing, and periodic review", "Roles: employer, electrically qualified person, host/operator, and work leader"],
              doNotInfer: ["A worker's title proves qualification", "A generic PPE label proves the task is covered"],
              escalateWhen: ["The job briefing, training, or responsible authority is missing"]),
        .init(id: "70e-planning", family: "NFPA 70E", title: "Job planning and risk assessment",
              verify: ["Task sequence, shock/arc-flash hazards, boundaries, tools, test method, abnormal conditions, and emergency response", "Condition of maintenance and available fault/current information"],
              doNotInfer: ["An energized condition is acceptable merely because the task is routine", "A label is current without verifying its study basis and equipment condition"],
              escalateWhen: ["The equipment condition, incident-energy basis, or boundary is unknown"]),
        .init(id: "70e-esc", family: "NFPA 70E", title: "Electrically safe work condition",
              verify: ["Identify all sources, interrupt load, open disconnects, release stored energy, apply lock/tag, verify absence of voltage, and control re-energization", "Test instrument operation before and after the absence-of-voltage test"],
              doNotInfer: ["An open control switch, PLC state, HMI state, or blown fuse proves isolation", "A single disconnect covers backfeed, alternate sources, UPS, capacitors, or pneumatic/hydraulic energy"],
              escalateWhen: ["Any source, stored energy, backfeed path, or verification point is unidentified"]),
        .init(id: "70e-shock", family: "NFPA 70E", title: "Shock risk and approach boundaries",
              verify: ["Nominal voltage, exposed live parts, approach boundary basis, restricted/prohibited limitations where applicable, insulating tools and barriers", "The task-specific risk assessment and adopted tables"],
              doNotInfer: ["Distance alone makes an unqualified person qualified", "A meter reading without a defined reference proves a deenergized circuit"],
              escalateWhen: ["The boundary, nominal voltage, or exposed-part condition is uncertain"]),
        .init(id: "70e-arc", family: "NFPA 70E", title: "Arc-flash risk",
              verify: ["Arc-flash boundary, incident-energy or PPE-category method, equipment labeling basis, enclosure condition, clearing time, and task posture", "PPE selection, clothing system, eye/face protection, hearing protection, and body protection required by the task"],
              doNotInfer: ["PPE makes energized work automatically justified", "A low-current control circuit is harmless without verifying available energy and source relationships"],
              escalateWhen: ["The incident-energy analysis, label, maintenance condition, or energized-work justification is unavailable"]),
        .init(id: "70e-test", family: "NFPA 70E", title: "Test instruments and diagnostic work",
              verify: ["Instrument rating, leads/probes, CAT rating, inspection, function check, method of use, and exposed-part access", "Whether testing can be done from a safe boundary or under an approved energized-work plan"],
              doNotInfer: ["A meter's voltage range alone establishes CAT suitability", "A clamp reading proves the circuit is safe to contact"],
              escalateWhen: ["The measurement requires opening equipment or approaching exposed parts without an approved method"]),
        .init(id: "nec-90-110", family: "NEC", title: "Code use, listing, working space, and equipment condition",
              verify: ["Adopted edition, AHJ amendments, listed/labeled equipment, manufacturer instructions, working space, guarding, identification, and accessible disconnecting means"],
              doNotInfer: ["A general rule overrides a product listing or special occupancy requirement", "A field condition is code-compliant because it resembles a prior installation"],
              escalateWhen: ["The AHJ edition, listing, or working-space condition is disputed"]),
        .init(id: "nec-250", family: "NEC", title: "Grounding and bonding",
              verify: ["System grounding, equipment grounding conductors, bonding jumpers, electrode system, objectionable current, separately derived systems, and continuity", "Fault-current path and overcurrent protection coordination"],
              doNotInfer: ["Neutral and equipment grounding conductor are interchangeable downstream of the permitted bonding point", "A low-resistance reading alone proves an effective fault-current path under fault conditions"],
              escalateWhen: ["Grounding/bonding changes affect a classified area, separately derived system, or protective device operation"]),
        .init(id: "nec-300-310", family: "NEC", title: "Wiring methods and conductors",
              verify: ["Conductor type, insulation rating, ampacity adjustment/correction, terminal temperature limits, raceway fill, derating, wet location, support, protection, and separation", "The adopted tables and equipment termination limitations"],
              doNotInfer: ["Nameplate current alone selects conductor size", "Conduit fill or ampacity can be estimated from memory for a final installation decision"],
              escalateWhen: ["The installation is classified, high-temperature, multi-circuit, or subject to unusual derating"]),
        .init(id: "nec-430", family: "NEC", title: "Motors, controllers, and motor circuits",
              verify: ["Motor FLC basis, branch-circuit conductors, short-circuit/ground-fault protection, overloads, disconnecting means, controller ratings, grounding, and locked-rotor/start behavior", "VFD input/output rules, bypass arrangements, and manufacturer instructions"],
              doNotInfer: ["Overload setting and short-circuit protection serve the same function", "VFD output conductors can be treated exactly like ordinary branch-circuit conductors"],
              escalateWhen: ["Motor protection, VFD bypass, emergency shutdown, or hazardous-location equipment is involved"]),
        .init(id: "nec-500-505", family: "NEC", title: "Hazardous locations",
              verify: ["Class/division or zone, gas/vapor group, temperature class, boundary drawings, equipment marking, wiring method, seals, intrinsically safe entity parameters, and maintenance condition", "API RP 500/505, site drawings, listing, and AHJ requirements"],
              doNotInfer: ["A device is suitable because its enclosure looks industrial", "A seal, barrier, purge, or intrinsic-safety interface can be changed without design review"],
              escalateWhen: ["Classification, equipment marking, seal-off, IS parameters, purge/pressurization, or AHJ interpretation is uncertain"]),
        .init(id: "uglys-field-math", family: "Ugly's", title: "Field calculations and lookups",
              verify: ["Known inputs, units, temperature assumptions, conductor material, system configuration, significant figures, and the licensed edition/table used", "Independent check against the adopted NEC, manufacturer data, or engineering calculation"],
              doNotInfer: ["A pocket-reference result is an approval", "A remembered formula substitutes for verifying table scope and assumptions"],
              escalateWhen: ["The result affects protection, conductor sizing, arc-flash energy, or a final installation"]),
        .init(id: "uglys-bending", family: "Ugly's", title: "Conduit and wiring field reference",
              verify: ["Raceway type/size, bend geometry, take-up, offsets, shrink, fill, conductor pulling limits, support, and equipment entry requirements", "Actual manufacturer dimensions and the adopted installation rules"],
              doNotInfer: ["A bending shortcut proves compliance", "A visually clean installation proves adequate fill, support, or bonding"],
              escalateWhen: ["The raceway is classified, crowded, damaged, or pulling tension/clearance is uncertain"]),
        .init(id: "plc-online-edit", family: "Controls", title: "Online edits to a live control system",
              verify: ["Approved change-control record, current running program revision, rollback plan, and authorized controls owner sign-off", "Whether the edit touches a permissive, interlock, or safety-relevant rung"],
              doNotInfer: ["An online edit that compiles cleanly is automatically safe to download", "A forced or overridden I/O point used during troubleshooting was ever meant to stay forced"],
              escalateWhen: ["The edit would change a permissive, interlock, or safety-relevant rung", "No change-control record, rollback plan, or authorized sign-off exists"])
    ]

    public static func entries(for family: String) -> [EEVeraSafetyKnowledgeEntry] {
        entries.filter { $0.family == family }
    }
}
