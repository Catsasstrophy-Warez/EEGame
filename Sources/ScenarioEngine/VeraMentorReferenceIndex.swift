import Foundation

// MARK: - Vera Mentor: code/reference knowledge index
//
// A curated, original-summary index of where a topic lives in NFPA 70E, the
// NEC (NFPA 70), and the kind of field quick-reference material found in
// "Ugly's Electrical References" — not a copy of any of those publications.
// No table values, code text, or figures are reproduced here: every entry
// names the article/section/table by number (a fact, not a copyrighted
// expression) and gives a short original description of what it governs, so
// Vera can point the player to the right place and the right adopted
// edition rather than inventing or reciting a citation. This mirrors the
// safety contract already in VeraMentorSpecification-equivalent form: Vera
// must say verification against the AHJ-adopted edition is required, never
// assume it has quoted a code section verbatim.

public enum EEVeraReferenceSource: String, Codable, Sendable, CaseIterable {
    case nec = "NEC (NFPA 70)"
    case nfpa70E = "NFPA 70E"
    case fieldReferenceGuide = "Field quick-reference"
}

public struct EEVeraCitation: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let source: EEVeraReferenceSource
    public let citation: String
    public let summary: String
    public let domains: [EEVeraMentorDomain]
    public let keywords: [String]

    public init(id: String, source: EEVeraReferenceSource, citation: String, summary: String, domains: [EEVeraMentorDomain], keywords: [String]) {
        self.id = id; self.source = source; self.citation = citation; self.summary = summary
        self.domains = domains; self.keywords = keywords
    }
}

public enum EEVeraReferenceIndex {
    /// Every summary here is an original paraphrase of what the numbered
    /// article/section governs, not quoted text — and every entry ends with
    /// "verify against the AHJ-adopted edition" being Vera's job, not the
    /// player's guess. Table/figure values themselves are never given; only
    /// that the table exists and what it is used for.
    public static let entries: [EEVeraCitation] = [
        // NEC — installation rules
        .init(id: "nec-110.26", source: .nec, citation: "NEC 110.26",
              summary: "Minimum working space and dedicated equipment space around electrical equipment likely to require examination, adjustment, servicing, or maintenance while energized.",
              domains: [.electrical, .instrumentation, .processSafety], keywords: ["clearance", "working space", "access", "dedicated space"]),
        .init(id: "nec-210.8", source: .nec, citation: "NEC 210.8",
              summary: "Ground-fault circuit-interrupter protection requirements for personnel, by occupancy and receptacle location.",
              domains: [.electrical], keywords: ["gfci", "ground fault", "receptacle"]),
        .init(id: "nec-240", source: .nec, citation: "NEC 240 (Article)",
              summary: "General overcurrent protection: conductor protection against overcurrent, standard ampere ratings, and location requirements for overcurrent devices.",
              domains: [.electrical, .instrumentation], keywords: ["overcurrent", "breaker", "fuse", "protection"]),
        .init(id: "nec-250", source: .nec, citation: "NEC 250 (Article)",
              summary: "Grounding and bonding: system grounding, equipment grounding conductor sizing, bonding of enclosures and metal parts, and grounding electrode requirements.",
              domains: [.electrical, .instrumentation, .rotatingEquipment], keywords: ["ground", "bonding", "grounding electrode", "egc"]),
        .init(id: "nec-310.16", source: .nec, citation: "NEC Table 310.16",
              summary: "Allowable ampacity table for insulated conductors by conductor size, insulation type, and ambient temperature — consult the table itself for the rated value, plus applicable derating/adjustment factors elsewhere in Article 310.",
              domains: [.electrical], keywords: ["ampacity", "conductor sizing", "wire size", "derating"]),
        .init(id: "nec-430", source: .nec, citation: "NEC 430 (Article)",
              summary: "Motor circuits and controllers: full-load current tables (by motor type/voltage), branch-circuit conductor and short-circuit protection sizing, and overload protection sizing.",
              domains: [.electrical, .rotatingEquipment], keywords: ["motor", "flc", "overload", "starter", "branch circuit"]),
        .init(id: "nec-500", source: .nec, citation: "NEC 500-516 (Articles)",
              summary: "Hazardous (classified) locations: class/division and zone system, area classification documentation, and equipment/wiring method requirements for each classified area.",
              domains: [.naturalGas, .coalMining, .processSafety], keywords: ["classified area", "hazardous location", "class 1", "zone", "division"]),
        .init(id: "nec-700", source: .nec, citation: "NEC 700-702 (Articles)",
              summary: "Emergency, legally required standby, and optional standby power systems: transfer equipment, wiring, and testing/maintenance requirements.",
              domains: [.electrical, .processSafety], keywords: ["emergency power", "standby", "transfer switch", "generator"]),

        // NFPA 70E — energized-work and shock/arc-flash protection
        .init(id: "nfpa70e-120", source: .nfpa70E, citation: "NFPA 70E Article 120",
              summary: "Establishing an electrically safe work condition: the process order (identify sources, interrupt load, disconnect, visually verify open, test for absence of voltage, ground/bond where required, lock and tag) that a real LOTO procedure must follow.",
              domains: [.electrical, .instrumentation, .rotatingEquipment, .processSafety], keywords: ["loto", "lockout", "tagout", "electrically safe work condition", "esw"]),
        .init(id: "nfpa70e-130", source: .nfpa70E, citation: "NFPA 70E Article 130",
              summary: "Work involving electrical hazards: when energized work is/is not permitted, the energized-work permit, and the arc-flash/shock risk assessment process that determines PPE category and boundaries — the PPE category tables themselves live in this article's referenced tables and must be read from the adopted edition, not assumed.",
              domains: [.electrical, .instrumentation, .rotatingEquipment], keywords: ["arc flash", "ppe", "risk assessment", "energized work permit", "boundary"]),
        .init(id: "nfpa70e-shock-boundaries", source: .nfpa70E, citation: "NFPA 70E Table 130.4(E)(a)",
              summary: "Approach boundaries to exposed energized conductors/parts (limited and restricted approach boundary concept) — the distance values are voltage-dependent and must be read from the adopted edition's table, never assumed from memory.",
              domains: [.electrical, .instrumentation], keywords: ["approach boundary", "limited approach", "restricted approach", "shock protection"]),

        // Field quick-reference — general formulas, not tabulated values
        .init(id: "field-voltage-drop", source: .fieldReferenceGuide, citation: "Voltage drop estimate",
              summary: "VD (single-phase, approx.) = 2 x K x I x D / CM, where K is conductor resistivity, I is load current, D is one-way distance, and CM is conductor circular-mil area; three-phase uses 1.732 in place of 2. Use for a first-pass check only — verify against the actual conductor/table data and any local voltage-drop limit.",
              domains: [.electrical, .instrumentation], keywords: ["voltage drop", "vd", "long run", "undersized"]),
        .init(id: "field-motor-flc-estimate", source: .fieldReferenceGuide, citation: "Motor FLC cross-check",
              summary: "A measured motor current far from the NEC Table 430 full-load current value (not the nameplate current) for that motor type/voltage is itself a diagnostic signal — cross-check both nameplate FLA and the NEC table FLC, since branch-circuit and overload sizing is based on the table value, not nameplate.",
              domains: [.rotatingEquipment, .electrical], keywords: ["motor current", "flc", "fla", "nameplate", "overload sizing"]),
        .init(id: "field-conduit-fill", source: .fieldReferenceGuide, citation: "Conduit/box fill concept",
              summary: "Conduit fill percentage and box fill (conductor volume allowance) are both governed by NEC tables (conduit fill in Chapter 9, box fill in 314.16) — a field quick-reference gives the same numbers in a faster-to-scan layout, but the NEC table is the authoritative source for the adopted edition.",
              domains: [.electrical], keywords: ["conduit fill", "box fill", "pull", "raceway"]),
        .init(id: "field-loop-power-budget", source: .fieldReferenceGuide, citation: "4-20 mA loop power budget",
              summary: "A 2-wire 4-20 mA loop's available voltage at the field device equals supply voltage minus the sum of every series drop (barrier/isolator, wiring resistance at 20 mA, and any other loop load) — a loop that reads correctly at 4 mA but degrades or dropouts near 20 mA is a classic under-budgeted loop, not a transmitter fault.",
              domains: [.instrumentation], keywords: ["loop power", "4-20ma", "barrier", "isolator", "dropout"])
    ]

    /// Free-text/domain retrieval. Deliberately simple substring matching
    /// over each entry's keywords/citation/summary — this is a small,
    /// bundled index, not a search engine, and simple matching keeps the
    /// mapping from query to citation auditable by reading this file.
    public static func retrieve(domain: EEVeraMentorDomain, query: String, limit: Int = 4) -> [EEVeraCitation] {
        let needles = query.lowercased().split(separator: " ").map(String.init).filter { $0.count > 2 }
        let scored: [(EEVeraCitation, Int)] = entries.compactMap { entry in
            guard entry.domains.contains(domain) else { return nil }
            var score = 0
            let haystack = (entry.keywords + [entry.citation, entry.summary]).joined(separator: " ").lowercased()
            for needle in needles where haystack.contains(needle) { score += 1 }
            return (entry, score)
        }
        let sorted = scored.sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.id < $1.0.id }
        let withMatches = sorted.filter { $0.1 > 0 }.map(\.0)
        let fallback = sorted.map(\.0)
        return Array((withMatches.isEmpty ? fallback : withMatches).prefix(max(0, limit)))
    }
}
