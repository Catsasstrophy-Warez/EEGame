import Foundation

// MARK: - Vera Mentor: gas-facility equipment expertise
//
// Ten equipment families a compressor-station E&I mentor is expected to be
// fluent in for setup and troubleshooting: gas compressor packages; ESD/
// shutdown/blowdown; LEL/toxic-gas detection; instrument-air compressors/
// dryers/distribution; MCCs/starters/VFDs/filters/control power; TEG
// dehydration skids; compressor drivers; process instrumentation (pressure/
// flow/temperature/vibration/level); safety PLCs/PLC-RTU/cause-and-effect
// logic; and field devices (solenoids, actuators, valves, barriers, AI
// channels, feedback devices).
//
// Same discipline as the rest of Vera's knowledge base: firstChecks and
// commonFailureModes are original field guidance, not copied standards
// text, and every citationIDs entry must resolve against a real citation
// in VeraMentorReferenceIndex.swift (enforced by a test) rather than
// inventing a reference here.

public struct EEVeraEquipmentFamily: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let domains: [EEVeraMentorDomain]
    public let firstChecks: [String]
    public let commonFailureModes: [String]
    public let keyParameters: [String]
    public let citationIDs: [String]
    public let keywords: [String]

    public init(id: String, title: String, domains: [EEVeraMentorDomain], firstChecks: [String], commonFailureModes: [String], keyParameters: [String], citationIDs: [String], keywords: [String]) {
        self.id = id; self.title = title; self.domains = domains
        self.firstChecks = firstChecks; self.commonFailureModes = commonFailureModes
        self.keyParameters = keyParameters; self.citationIDs = citationIDs; self.keywords = keywords
    }
}

public enum EEVeraEquipmentExpertise {
    public static let families: [EEVeraEquipmentFamily] = [
        .init(id: "gas-compressor-packages", title: "Gas compressor packages",
              domains: [.naturalGas, .rotatingEquipment],
              firstChecks: ["Suction/discharge pressure and ratio against the package's rated operating envelope", "Recycle valve position and anti-surge control state", "Current permissive/interlock status before assuming a trip is a real process event"],
              commonFailureModes: ["A recycle valve stuck partially open reads as low efficiency, not a valve fault", "Suction scrubber high-level trip mistaken for a compressor fault when the real cause is upstream liquid carryover", "A pressure-ratio limit trip treated as a nuisance when it is actually protecting against surge"],
              keyParameters: ["Suction PSI", "Discharge PSI", "Compression ratio", "RPM/speed command vs. actual", "Recycle valve travel"],
              citationIDs: ["nfpa-79", "api-rp-500-505", "field-vibration-severity-zones"],
              keywords: ["compressor package", "recycle valve", "surge", "suction", "discharge", "compression ratio"]),

        .init(id: "esd-shutdown-blowdown", title: "ESD, shutdown, and blowdown systems",
              domains: [.naturalGas, .processSafety],
              firstChecks: ["Which specific initiator tripped: process, fire/gas, manual pull, or a voted logic solver fault", "Current safe/tripped state of every final element the cause-and-effect maps to this initiator", "Blowdown valve position and vent stack status if a blowdown was actually initiated"],
              commonFailureModes: ["A field pull-station tested during maintenance left in the tripped position", "A voted 2-out-of-3 transmitter disagreement treated as a single-sensor fault instead of a voting/logic issue", "Blowdown valve command confused with blowdown valve position — command does not confirm the vent actually opened"],
              keyParameters: ["Trip initiator identity and timestamp", "Voted logic state per channel", "Final element (ESD valve, blowdown valve) commanded vs. actual position"],
              citationIDs: ["iec-61511-isa-84", "nec-500", "nec-501"],
              keywords: ["esd", "shutdown", "blowdown", "trip", "emergency shutdown", "vent stack", "pull station"]),

        .init(id: "lel-toxic-gas-detection", title: "LEL and toxic-gas detection arrays",
              domains: [.naturalGas, .processSafety, .coalMining],
              firstChecks: ["Sensor type (catalytic bead, infrared, electrochemical) and its known failure mode for that type", "Current calibration/bump-test date and whether the sensor is in alarm, fault, or normal state", "Whether the alarm is a real release, a sensor drift, or a maintenance/wash-down false trigger"],
              commonFailureModes: ["A catalytic-bead sensor poisoned by a silicone or sulfur compound reading falsely low, not zero", "An infrared sensor blocked by condensation or dust reading a fault, not a real low reading", "A wash-down or steam event triggering a real physical response in a sensor that is not a gas release"],
              keyParameters: ["% LEL reading", "PPM toxic-gas reading", "Sensor fault/normal/alarm state", "Time since last calibration/bump test"],
              citationIDs: ["nec-500", "nec-501", "api-rp-500-505", "msha-75.323"],
              keywords: ["lel", "gas detection", "toxic gas", "catalytic bead", "gas clip", "h2s", "bump test", "calibration gas"]),

        .init(id: "instrument-air-system", title: "Instrument-air compressors, dryers, and distribution",
              domains: [.instrumentation, .naturalGas],
              firstChecks: ["Header pressure at the point of use, not just at the compressor discharge", "Dryer dew point and whether it's within the rated spec for the site's classified-area instruments", "Whether a low-air event is a compressor capacity problem, a dryer fault, or a distribution leak"],
              commonFailureModes: ["A failed desiccant dryer allowing moisture into IS barriers and pneumatic actuators, causing intermittent, hard-to-reproduce faults", "A slow leak in a long air header masquerading as intermittent low pressure at the farthest instrument", "A fail-safe pneumatic valve interpreted as 'stuck' when it actually lost air and is doing exactly what it's supposed to do"],
              keyParameters: ["Header pressure (PSI)", "Dew point (°F/°C)", "Compressor duty cycle", "Fail-safe action on loss of air (fail open/closed/last)"],
              citationIDs: ["field-loop-power-budget", "nec-504"],
              keywords: ["instrument air", "air dryer", "dew point", "pneumatic", "desiccant", "header pressure"]),

        .init(id: "mcc-starters-vfd-control-power", title: "MCCs, motor starters, VFDs, filters, and control power",
              domains: [.electrical, .rotatingEquipment, .plcAutomation],
              firstChecks: ["Control power source and voltage at the actual starter/VFD, not just at the MCC bus", "VFD fault code and whether it's a drive-side fault or a motor/load-side fault", "Whether an input or output filter is actually rated for the installed drive's switching frequency"],
              commonFailureModes: ["A shared 24VDC control power problem presenting as several unrelated starter faults at once", "VFD-induced harmonics or common-mode voltage damaging motor bearings over time, read as a random bearing failure", "An output dv/dt filter omitted or undersized on a long motor lead, causing insulation stress that looks like a random cable fault"],
              keyParameters: ["Control power voltage", "VFD fault code", "Output frequency vs. commanded frequency", "Motor current vs. nameplate/table FLC"],
              citationIDs: ["nec-430", "nec-409", "field-motor-flc-estimate", "field-three-phase-power", "field-insulation-resistance-test"],
              keywords: ["mcc", "motor starter", "vfd", "variable frequency drive", "control power", "harmonics", "dv/dt filter"]),

        .init(id: "teg-dehydration-skid", title: "TEG dehydration skids",
              domains: [.naturalGas, .instrumentation],
              firstChecks: ["Reboiler/still-column temperature against the glycol's degradation limit", "Lean/rich glycol circulation rate and whether the circulation pump is actually moving glycol, not just running", "Contactor differential pressure — high differential often means tray flooding or foaming, not a level-control fault"],
              commonFailureModes: ["Overheating the reboiler past the glycol's thermal degradation point, damaging the glycol itself rather than any single component", "Foaming from contamination read as a level-control malfunction", "A stuck or undersized glycol-to-gas heat exchanger causing carryover that looks like a downstream instrumentation problem"],
              keyParameters: ["Reboiler temperature", "Lean/rich glycol circulation rate", "Contactor differential pressure", "Outlet gas water dew point"],
              citationIDs: ["nec-500", "api-rp-500-505"],
              keywords: ["teg", "glycol", "dehydration", "reboiler", "contactor", "still column", "water dew point"]),

        .init(id: "compressor-drivers", title: "Compressor drivers",
              domains: [.rotatingEquipment, .naturalGas],
              firstChecks: ["Driver type (reciprocating engine, gas turbine, electric motor) and its specific protective interlock chain", "Engine/turbine control system fault log and whether the trip is a safety-system fault or a nuisance/sensor trip", "Fuel gas pressure and quality at the driver skid boundary, not just at the station inlet"],
              commonFailureModes: ["An engine control system (e.g. an ADEM-type ECU) overspeed or detonation trip mistaken for a simple sensor glitch", "A single vibration or knock sensor fault triggering a real protective trip that should not simply be reset", "Fuel gas quality/pressure swings at the driver read as an engine control fault"],
              keyParameters: ["Speed/RPM", "Exhaust/jacket-water temperature", "Vibration/knock sensor readings", "Fuel gas pressure at the skid"],
              citationIDs: ["field-vibration-severity-zones", "iec-61511-isa-84"],
              keywords: ["compressor driver", "engine", "turbine", "ecu", "adem", "overspeed", "knock sensor", "detonation"]),

        .init(id: "process-instrumentation", title: "Pressure, flow, temperature, vibration, and level instrumentation",
              domains: [.instrumentation, .rotatingEquipment],
              firstChecks: ["Transmitter range, units, damping, and last calibration date against the current reading", "Whether the signal disagreement starts at the sensor, the transmitter, the wiring/barrier, the I/O, or the logic/display layer", "For a smart (HART) device, the actual diagnostic/status register, not just the 4-20mA value"],
              commonFailureModes: ["Impulse-line freezing, plugging, or a lost heat trace read as a transmitter fault", "A configured range/scaling error producing a plausible-looking but wrong engineering value", "A vibration probe installation or mounting problem misread as real bearing/shaft damage"],
              keyParameters: ["4-20mA signal vs. configured range", "HART diagnostic/status bits", "Damping/response time setting", "Last calibration date and as-found/as-left values"],
              citationIDs: ["field-loop-power-budget", "field-vibration-severity-zones", "field-insulation-resistance-test", "nec-504"],
              keywords: ["transmitter", "pressure instrument", "flow instrument", "level instrument", "vibration probe", "hart", "rosemount", "fisher"]),

        .init(id: "safety-plc-rtu-cause-effect", title: "Safety PLCs, PLC/RTU systems, and cause-and-effect logic",
              domains: [.plcAutomation, .processSafety],
              firstChecks: ["Whether the running program matches the approved, revision-controlled cause-and-effect matrix", "Any forced, inhibited, or overridden I/O point on the safety PLC — these should almost never persist between shifts", "RTU/PLC communication health (comm fault counters, watchdog state) before assuming a process-side fault"],
              commonFailureModes: ["A forced I/O point left in place after maintenance, silently changing the actual protection logic", "A communication fault between PLC and RTU/SCADA read as a real field-device fault because the last-known value froze on the display", "An online edit that compiled and downloaded cleanly but was never reconciled with the approved cause-and-effect documentation"],
              keyParameters: ["Forced/inhibited I/O point count", "Comm fault/watchdog counters", "Program checksum/revision vs. approved copy", "Cause-and-effect matrix version"],
              citationIDs: ["iec-61511-isa-84", "nfpa-79", "osha-1910.147"],
              keywords: ["safety plc", "rtu", "cause and effect", "forced io", "inhibited", "scada", "watchdog", "plc program"]),

        .init(id: "field-devices-solenoids-actuators-valves", title: "Solenoids, actuators, valves, barriers, AI channels, and feedback devices",
              domains: [.instrumentation, .naturalGas, .plcAutomation],
              firstChecks: ["Solenoid coil resistance and voltage at the actual terminal, not just the command bit state", "Actuator supply pressure/torque and whether travel matches the commanded position, not just that it moved at all", "Barrier/isolator entity parameters if the circuit is in a classified area — a mismatched barrier is a real hazard, not just a nuisance fault"],
              commonFailureModes: ["A solenoid that energizes correctly but has a worn or gummed-up valve seat, so the valve doesn't actually move even though the coil is fine", "Actuator feedback (a potentiometer or limit switch) failing independently of the actuator itself, reading a false position", "An IS barrier swapped for a similar-looking but mismatched entity-parameter barrier during a repair"],
              keyParameters: ["Solenoid coil resistance/voltage", "Actuator supply pressure/torque", "Commanded vs. actual valve position", "Barrier entity parameters (Voc, Isc, Ca, La)"],
              citationIDs: ["nec-504", "field-loop-power-budget", "field-ohms-law-power-triangle"],
              keywords: ["solenoid", "actuator", "valve position", "barrier", "isolator", "ai channel", "feedback device", "limit switch"])
    ]

    /// Keyword-scored match over a free-text query, same discipline as
    /// `EEVeraReferenceIndex.retrieve`: simple, auditable substring scoring,
    /// no domain restriction (equipment families already carry their own
    /// domain tags and keywords), and never an empty result for a
    /// nonsensical query — it just returns the whole list unscored.
    public static func match(query: String, limit: Int = 3) -> [EEVeraEquipmentFamily] {
        let needles = query.lowercased().split(separator: " ").map(String.init).filter { $0.count > 2 }
        let scored: [(EEVeraEquipmentFamily, Int)] = families.map { family in
            let haystack = (family.keywords + [family.title]).joined(separator: " ").lowercased()
            let score = needles.reduce(0) { haystack.contains($1) ? $0 + 1 : $0 }
            return (family, score)
        }
        let sorted = scored.sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.id < $1.0.id }
        let withMatches = sorted.filter { $0.1 > 0 }.map(\.0)
        return Array((withMatches.isEmpty ? [] : withMatches).prefix(max(0, limit)))
    }
}
