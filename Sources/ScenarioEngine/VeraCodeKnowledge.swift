import Foundation

// MARK: - Vera Mentor: controlling-authority index
//
// Ported from the I&E Trainer app's VeraCodeKnowledge.swift. Distinct from
// VeraMentorReferenceIndex.swift: that file cites specific articles/sections
// scoped to a query; this one names the small set of top-level authorities
// (NFPA 70E, NEC, OSHA, and the player's own licensed Ugly's references)
// that govern a domain at all, with real public URLs to those publishers —
// not copyrighted text, just where to buy/verify the adopted edition — and
// an explicit statement of which authority controls what.

public struct EEVeraCodeReference: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let authority: String
    public let edition: String
    public let topic: String
    public let fieldUse: String
    public let sourceURL: URL

    public init(id: String, authority: String, edition: String, topic: String, fieldUse: String, sourceURL: URL) {
        self.id = id; self.authority = authority; self.edition = edition
        self.topic = topic; self.fieldUse = fieldUse; self.sourceURL = sourceURL
    }
}

public enum EEVeraCodeKnowledge {
    public static let references: [EEVeraCodeReference] = [
        .init(id: "nfpa-70e-2024", authority: "NFPA 70E", edition: "2024", topic: "Electrical safety in the workplace",
              fieldUse: "Safety-related work practices, shock and arc-flash risk assessment, approach boundaries, energized-work controls, PPE, training, and maintenance context. Verify the adopted edition and employer electrical safety program.",
              sourceURL: URL(string: "https://link.nfpa.org/all-publications/70E/2024")!),
        .init(id: "nfpa-70-2023", authority: "NFPA 70 / NEC", edition: "2023", topic: "Electrical installation",
              fieldUse: "Installation and equipment requirements. Use the adopted edition, AHJ interpretations, listed/labeled equipment instructions, and the applicable article/section/table before treating a conclusion as final.",
              sourceURL: URL(string: "https://link.nfpa.org/all-publications/70/2023")!),
        .init(id: "osha-1910-subpart-s", authority: "OSHA", edition: "29 CFR 1910 Subpart S", topic: "Workplace electrical safety",
              fieldUse: "Regulatory requirements for electrical systems and safety-related work practices; OSHA remains the regulatory authority for covered workplaces.",
              sourceURL: URL(string: "https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910SubpartS")!),
        .init(id: "osha-1910-333", authority: "OSHA", edition: "29 CFR 1910.333", topic: "Selection and use of work practices",
              fieldUse: "Deenergization, work near energized parts, and conditions requiring consistent safety-related work practices.",
              sourceURL: URL(string: "https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.333")!),
        .init(id: "uglys-electrical-references-2023", authority: "Ugly's Electrical References", edition: "2023", topic: "Licensed field reference",
              fieldUse: "Use the player's own licensed edition for formulas, conversions, NEMA configurations, conduit bending, ampacity, conduit fill, transformer/control wiring, and quick tables. Do not treat it as a substitute for NEC, NFPA 70E, OSHA, the AHJ, or the site procedure.",
              sourceURL: URL(string: "https://www.uglys.net/ugly-s-electrical-references-2023-edition")!),
        .init(id: "uglys-70e-2024", authority: "Ugly's Electrical Safety and NFPA 70E", edition: "2024", topic: "Safety field reference",
              fieldUse: "Use the licensed book for quick-reference safety summaries and tables; verify every safety-critical value against the adopted NFPA 70E, employer program, and task-specific risk assessment.",
              sourceURL: URL(string: "https://www.uglys.net/uglys-products/ugly%27s-electrical-safety-and-nfpa-70e--2024-edition")!)
    ]

    /// The Ugly's field-reference entry is scoped to hands-on installation
    /// domains (electrical, instrumentation, PLC/automation panels) rather
    /// than shown for every domain — a coal-mining atmosphere alarm has no
    /// use for a conduit-bending quick reference.
    public static func references(for domain: EEVeraMentorDomain) -> [EEVeraCodeReference] {
        switch domain {
        case .electrical, .plcAutomation, .instrumentation:
            return references
        case .naturalGas, .coalMining, .rotatingEquipment, .processSafety:
            return references.filter { $0.id != "uglys-electrical-references-2023" }
        }
    }

    public static var authorityBoundary: String {
        "OSHA is the regulatory authority for covered workplace requirements; NFPA 70E addresses electrical safety in the workplace; the NEC addresses installation; Ugly's is a licensed quick-reference aid, not a substitute for any of the above. The adopted edition, AHJ, employer program, engineer of record, site procedure, and equipment instructions control the final decision."
    }
}
