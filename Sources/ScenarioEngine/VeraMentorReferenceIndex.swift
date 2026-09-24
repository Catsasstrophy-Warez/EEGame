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
    case msha = "MSHA (30 CFR)"
    case osha = "OSHA (29 CFR)"
    case industryStandard = "Industry standard"
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
        .init(id: "nec-90.4", source: .nec, citation: "NEC 90.4",
              summary: "Enforcement and the AHJ's authority: the AHJ interprets rules, approves equipment/materials, and grants special permission — a reminder that the code text alone does not settle an ambiguous field question; the AHJ's interpretation of the adopted edition does.",
              domains: [.electrical, .instrumentation, .naturalGas, .coalMining, .rotatingEquipment, .processSafety], keywords: ["ahj", "authority having jurisdiction", "interpretation", "enforcement"]),
        .init(id: "nec-100", source: .nec, citation: "NEC Article 100",
              summary: "Definitions used throughout the code, including \"qualified person\" — the defined term that gates who may perform many of the tasks NFPA 70E and the NEC both reference.",
              domains: [.electrical, .instrumentation, .rotatingEquipment, .processSafety], keywords: ["qualified person", "definition", "terminology"]),
        .init(id: "nec-300", source: .nec, citation: "NEC Article 300",
              summary: "General wiring methods and materials requirements applicable across raceway/cable types: conductor protection, burial depth, and general installation requirements common to most wiring methods.",
              domains: [.electrical, .instrumentation], keywords: ["wiring method", "raceway", "burial depth", "conductor protection"]),
        .init(id: "nec-314", source: .nec, citation: "NEC 314.16",
              summary: "Box fill calculation: how conductors, devices, and fittings count against a box's cubic-inch volume allowance for a given conductor size.",
              domains: [.electrical], keywords: ["box fill", "junction box", "pull box", "cubic inch"]),
        .init(id: "nec-408", source: .nec, citation: "NEC 408 (Article)",
              summary: "Switchboards, switchgear, and panelboards: overcurrent protection, clearances, and general construction/installation requirements for distribution equipment.",
              domains: [.electrical, .processSafety], keywords: ["panelboard", "switchboard", "switchgear", "distribution"]),
        .init(id: "nec-409", source: .nec, citation: "NEC Article 409",
              summary: "Industrial control panels: field- and factory-wired panel construction, marking, and short-circuit current rating (SCCR) requirements.",
              domains: [.electrical, .instrumentation], keywords: ["control panel", "sccr", "short circuit current rating"]),
        .init(id: "nec-445", source: .nec, citation: "NEC Article 445",
              summary: "Generators: overcurrent and disconnect requirements, nameplate data requirements, and location/ventilation considerations.",
              domains: [.electrical, .rotatingEquipment, .processSafety], keywords: ["generator", "genset", "prime mover"]),
        .init(id: "nec-450", source: .nec, citation: "NEC Article 450",
              summary: "Transformers: overcurrent protection sizing, ventilation, and installation clearance requirements by transformer type and location.",
              domains: [.electrical], keywords: ["transformer", "overcurrent protection", "ventilation", "kva"]),
        .init(id: "nec-501", source: .nec, citation: "NEC Article 501",
              summary: "Class I locations (flammable gas/vapor atmospheres): wiring methods, seals, and equipment requirements specific to Class I, further subdivided by Division or Zone per the area classification study.",
              domains: [.naturalGas, .coalMining, .processSafety], keywords: ["class i", "flammable gas", "conduit seal", "explosion proof"]),
        .init(id: "nec-503", source: .nec, citation: "NEC Article 503",
              summary: "Class II locations (combustible dust atmospheres): wiring methods and equipment requirements — the relevant classification for a coal-dust-bearing area distinct from the gassy Class I areas underground.",
              domains: [.coalMining], keywords: ["class ii", "combustible dust", "coal dust"]),
        .init(id: "nec-504", source: .nec, citation: "NEC Article 504",
              summary: "Intrinsically safe systems: wiring, separation, and installation requirements for intrinsically safe circuits and associated apparatus used to reduce ignition risk in a classified area.",
              domains: [.naturalGas, .coalMining, .instrumentation], keywords: ["intrinsically safe", "is barrier", "entity concept"]),
        .init(id: "nec-505", source: .nec, citation: "NEC Article 505",
              summary: "Zone 0/1/2 classification system for Class I locations (the IEC-aligned alternative to the Division system in Article 501) — an installation uses one system or the other per its area classification documentation, not a mix.",
              domains: [.naturalGas, .processSafety], keywords: ["zone 0", "zone 1", "zone 2", "iec classification"]),
        .init(id: "nec-210.19", source: .nec, citation: "NEC 210.19",
              summary: "Branch-circuit conductor minimum ampacity/sizing basis, including the general continuous-load 125% sizing consideration — a rule the loaded-conductor-in-a-continuous-duty circuit case checks against, separate from Table 310.16 ampacity itself.",
              domains: [.electrical], keywords: ["branch circuit sizing", "continuous load", "125 percent"]),
        .init(id: "nec-215.2", source: .nec, citation: "NEC 215.2",
              summary: "Feeder conductor minimum size and ampacity requirements — the feeder-level counterpart to 210.19's branch-circuit sizing rule.",
              domains: [.electrical], keywords: ["feeder sizing", "feeder ampacity"]),
        .init(id: "nec-220", source: .nec, citation: "NEC Article 220",
              summary: "Load calculation methods: general/standard vs. optional calculation procedures for determining a service, feeder, or branch circuit's calculated load — the basis a sizing exercise starts from before any table lookup.",
              domains: [.electrical], keywords: ["load calculation", "demand factor", "service sizing"]),
        .init(id: "nec-695", source: .nec, citation: "NEC Article 695",
              summary: "Fire pumps: dedicated power source requirements, overcurrent protection philosophy (sized to allow motor locked-rotor current to pass rather than trip), and transfer switch requirements distinct from ordinary motor circuits.",
              domains: [.electrical, .processSafety], keywords: ["fire pump", "locked rotor", "dedicated feeder"]),

        // OSHA — general industry electrical safety and permit requirements
        // (public federal regulation, same edition/amendment-verification
        // caveat as every other regulatory source in this index)
        .init(id: "osha-1910.147", source: .osha, citation: "29 CFR 1910.147",
              summary: "The general-industry lockout/tagout standard: energy-control program elements, the concept of an authorized vs. affected employee, and periodic inspection requirements — the general-industry counterpart to NFPA 70E's electrically-specific Article 120 procedure.",
              domains: [.electrical, .instrumentation, .rotatingEquipment, .coalMining, .processSafety], keywords: ["loto", "lockout tagout", "energy control program", "authorized employee"]),
        .init(id: "osha-1910.269", source: .osha, citation: "29 CFR 1910.269",
              summary: "Electric power generation, transmission, and distribution: minimum approach distances, qualification requirements, and work-practice rules specific to utility-scale electrical work — distinct in scope from general industrial electrical maintenance.",
              domains: [.electrical, .rotatingEquipment], keywords: ["power generation", "transmission", "minimum approach distance", "utility"]),
        .init(id: "osha-1910.146", source: .osha, citation: "29 CFR 1910.146",
              summary: "Permit-required confined space entry: atmospheric testing, permit system, attendant/entrant roles, and rescue provisions — directly relevant any time troubleshooting would require entering a vessel, sump, or other confined space in a mine or process facility.",
              domains: [.coalMining, .naturalGas, .processSafety], keywords: ["confined space", "permit required", "atmospheric testing", "entry"]),

        // Industry standards — area classification methodology and
        // functional-safety/arc-flash calculation methods referenced by,
        // but distinct from, the NEC/NFPA 70E articles above.
        .init(id: "api-rp-500-505", source: .industryStandard, citation: "API RP 500 / API RP 505",
              summary: "Recommended practice for classifying locations at petroleum facilities: API RP 500 uses the Class/Division system, API RP 505 the Zone system — the area-classification methodology a natural-gas facility's drawings are typically built from, feeding directly into which NEC article (501 or 505) governs the installation.",
              domains: [.naturalGas, .processSafety], keywords: ["api rp 500", "api rp 505", "area classification study", "petroleum facility"]),
        .init(id: "nfpa-497", source: .industryStandard, citation: "NFPA 497",
              summary: "Recommended practice for classifying flammable-liquid/gas areas, an alternative area-classification methodology to the API RPs, referenced by facilities outside the petroleum-specific API scope.",
              domains: [.naturalGas, .processSafety], keywords: ["nfpa 497", "flammable liquid classification", "area classification"]),
        .init(id: "nfpa-496", source: .industryStandard, citation: "NFPA 496",
              summary: "Purged and pressurized enclosures for electrical equipment: the Type X/Y/Z purge-protection concept used to install standard (non-explosion-proof) electrical equipment inside a classified area, with continuous purge/pressure monitoring.",
              domains: [.naturalGas, .instrumentation, .processSafety], keywords: ["purge", "pressurization", "type x", "type y", "type z"]),
        .init(id: "ieee-1584", source: .industryStandard, citation: "IEEE 1584",
              summary: "The incident-energy calculation method that NFPA 70E's risk assessment (130.5) references for the analytical method — bolted fault current, arc gap, working distance, and equipment class are the real inputs, so a stale short-circuit study invalidates the arc-flash label even if nothing else changed.",
              domains: [.electrical, .instrumentation, .rotatingEquipment], keywords: ["incident energy calculation", "arc flash study", "short circuit study", "arc flash label"]),
        .init(id: "iec-61511-isa-84", source: .industryStandard, citation: "IEC 61511 / ISA-84.00.01",
              summary: "Functional safety standard for safety instrumented systems (SIS) in the process industries: safety integrity level (SIL) selection, proof-test intervals, and the safety lifecycle a SIS's design and maintenance are meant to follow — the standard a process-safety impairment or bypass decision is ultimately measured against.",
              domains: [.processSafety, .naturalGas, .instrumentation], keywords: ["sis", "sil", "safety instrumented system", "proof test", "functional safety"]),

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
        .init(id: "nfpa70e-100", source: .nfpa70E, citation: "NFPA 70E Article 100",
              summary: "Definitions specific to electrical safety-related work, including \"qualified person\" as used within 70E's own scope (distinct from, but aligned with, the NEC's Article 100 definition) and the incident energy/arc-flash boundary terms used throughout Article 130.",
              domains: [.electrical, .instrumentation, .rotatingEquipment], keywords: ["definitions", "qualified person", "arc flash boundary", "incident energy"]),
        .init(id: "nfpa70e-110", source: .nfpa70E, citation: "NFPA 70E Article 110",
              summary: "General electrical safety program requirements: the elements an employer's electrical safety program must contain, job briefings before work, and the general principle that de-energized is the default work condition unless an exception applies.",
              domains: [.electrical, .instrumentation, .rotatingEquipment, .processSafety], keywords: ["safety program", "job briefing", "de-energized default", "training"]),
        .init(id: "nfpa70e-130.5", source: .nfpa70E, citation: "NFPA 70E 130.5",
              summary: "The arc-flash risk assessment procedure itself: the two permitted methods (incident energy analysis vs. the PPE category tables), when each applies, and that the assessment must be updated when major system changes occur — not treated as a one-time label.",
              domains: [.electrical, .instrumentation, .rotatingEquipment], keywords: ["risk assessment", "incident energy analysis", "arc flash label", "ppe category table"]),
        .init(id: "nfpa70e-205", source: .nfpa70E, citation: "NFPA 70E Article 205",
              summary: "Safety-related maintenance requirements: the expectation that overcurrent protective devices, enclosures, and other electrical equipment are maintained in a condition that does not increase the hazard, with maintenance intervals and documentation.",
              domains: [.electrical, .rotatingEquipment, .processSafety], keywords: ["maintenance", "overcurrent device maintenance", "condition of maintenance"]),

        // MSHA — underground coal mining federal regulation (public
        // regulatory text; summarized in original wording here, same
        // edition-verification caveat since regulations are amended)
        .init(id: "msha-75.323", source: .msha, citation: "30 CFR 75.323",
              summary: "Methane and oxygen monitoring requirements for underground coal mine atmospheres, including the general concept of automatic power de-energization on a methane concentration exceeding the regulatory action level at monitored points — the exact percentage thresholds and monitored locations must be read from the current regulation text, not assumed.",
              domains: [.coalMining], keywords: ["methane monitoring", "methane percent", "de-energization", "atmosphere monitoring"]),
        .init(id: "msha-75.1714", source: .msha, citation: "30 CFR 75.1700 / 75.1714",
              summary: "Self-contained self-rescuer (SCSR) availability and mine-emergency evacuation-equipment requirements for persons underground.",
              domains: [.coalMining], keywords: ["scsr", "self rescuer", "evacuation", "emergency equipment"]),
        .init(id: "msha-75-subpart-l", source: .msha, citation: "30 CFR 75 Subpart L",
              summary: "Ventilation requirements for underground coal mines: approved ventilation plans, minimum air-quantity concepts, and requirements for maintaining a mine's ventilation system as installed rather than as originally designed only.",
              domains: [.coalMining], keywords: ["ventilation plan", "air quantity", "fan", "airway"]),

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
              domains: [.instrumentation], keywords: ["loop power", "4-20ma", "barrier", "isolator", "dropout"]),
        .init(id: "field-ohms-law-power-triangle", source: .fieldReferenceGuide, citation: "Ohm's law / power triangle",
              summary: "V = I x R, and P = V x I for DC/resistive loads; for AC, real power P = V x I x cos(theta), where cos(theta) is power factor — a measured current far above what P/V alone predicts is a power-factor or harmonic clue, not necessarily a wiring fault.",
              domains: [.electrical, .rotatingEquipment], keywords: ["ohms law", "power factor", "power triangle", "reactive power"]),
        .init(id: "field-three-phase-power", source: .fieldReferenceGuide, citation: "Three-phase power formula",
              summary: "Three-phase real power P = sqrt(3) x V(line-line) x I(line) x cos(theta) — using the single-phase P=VI formula on a three-phase measurement is a common estimating error worth checking for when a calculated load doesn't match a nameplate or measured value.",
              domains: [.electrical, .rotatingEquipment], keywords: ["three phase power", "kw calculation", "sqrt3", "line current"]),
        .init(id: "field-transformer-turns-ratio", source: .fieldReferenceGuide, citation: "Transformer turns ratio",
              summary: "Primary/secondary voltage ratio equals the turns ratio; current ratio is the inverse. A transformer reading the wrong secondary voltage under load (but correct at no-load) points at loading/regulation or a tap-changer position, not necessarily a winding fault.",
              domains: [.electrical], keywords: ["turns ratio", "transformer tap", "no load voltage", "regulation"]),
        .init(id: "field-vibration-severity-zones", source: .fieldReferenceGuide, citation: "ISO 10816/20816 vibration severity zone concept",
              summary: "Rotating-machine vibration standards define severity zones (from \"newly commissioned\" through \"damage likely\") that depend on machine class and mounting — the exact velocity/displacement thresholds must be read from the applicable ISO 10816/20816 part for the specific machine class, never assumed from a different machine class's table.",
              domains: [.rotatingEquipment], keywords: ["vibration", "iso 10816", "iso 20816", "severity zone", "mils", "in/s"]),
        .init(id: "field-insulation-resistance-test", source: .fieldReferenceGuide, citation: "Insulation resistance (megger) test concept",
              summary: "A megohmmeter test result is only meaningful relative to a baseline for that specific machine/cable at a known temperature and humidity — a single absolute reading without history or a polarization-index trend is a weaker signal than a comparison against the equipment's own prior readings.",
              domains: [.electrical, .rotatingEquipment], keywords: ["megger", "insulation resistance", "polarization index", "megohm"]),
        .init(id: "field-full-load-amps-nameplate", source: .fieldReferenceGuide, citation: "Nameplate vs. table current values",
              summary: "A motor nameplate's FLA reflects the specific tested unit; NEC Table 430 values are standardized figures used for circuit sizing. The two are expected to differ somewhat — treat a large gap between measured current and BOTH values (not just one) as the real anomaly.",
              domains: [.rotatingEquipment, .electrical], keywords: ["nameplate current", "fla", "flc", "sizing basis"])
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

    /// The full bundled library scoped to one domain, independent of any
    /// query — lets the player browse everything Vera knows about a domain
    /// rather than only what a specific symptom's keywords happened to
    /// match, grouped by source so NEC/NFPA 70E/MSHA/field-reference read as
    /// separate shelves.
    public static func library(for domain: EEVeraMentorDomain) -> [EEVeraReferenceSource: [EEVeraCitation]] {
        Dictionary(grouping: entries.filter { $0.domains.contains(domain) }, by: \.source)
    }
}
