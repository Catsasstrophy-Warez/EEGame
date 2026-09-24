import Foundation

// MARK: - Vera Mentor: field technique playbooks
//
// Ported from the I&E Trainer app's VeraFieldTechniquesKnowledge.swift.
// Distinct from every other Vera knowledge file so far: those describe
// equipment, citations, or authorities; this describes HOW to actually
// perform a specific diagnostic technique step by step (verify loop
// current, read HART diagnostics, stroke-test a valve, run an insulation-
// resistance test, trace PLC I/O read-only, and so on). Acceptance values
// and site-specific limits are deliberately never given — those remain
// the approved procedure/manufacturer data's job — only the sequence,
// what evidence to capture, and when to stop.

public struct EEVeraFieldTechnique: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let category: String
    public let title: String
    public let useWhen: String
    public let prerequisites: [String]
    public let sequence: [String]
    public let expectedEvidence: [String]
    public let fieldTips: [String]
    public let stopConditions: [String]

    public init(id: String, category: String, title: String, useWhen: String, prerequisites: [String], sequence: [String], expectedEvidence: [String], fieldTips: [String], stopConditions: [String]) {
        self.id = id; self.category = category; self.title = title; self.useWhen = useWhen
        self.prerequisites = prerequisites; self.sequence = sequence
        self.expectedEvidence = expectedEvidence; self.fieldTips = fieldTips; self.stopConditions = stopConditions
    }
}

public enum EEVeraFieldTechniquesKnowledge {
    public static let all: [EEVeraFieldTechnique] = [
        .init(id: "loop-current", category: "Loop diagnostics", title: "4-20 mA loop-current verification",
              useWhen: "Separating transmitter output, wiring/barrier, AI input, scaling, and display faults.",
              prerequisites: ["Confirm tag, range, units, loop drawing, area classification, gas-test status, and energized-test method", "Confirm whether interrupting the loop affects a control or protective function"],
              sequence: ["Capture process PV, local display, HART PV, controller raw value, engineering value, quality, and HMI value before disturbing anything", "Measure current only with the approved series/shunt/clamp method and correctly rated instrument", "Compare current to configured range and trace voltage budget/drop across each approved boundary", "Restore the loop and prove signal, alarm, control, and shutdown behavior"],
              expectedEvidence: ["Current in mA with units and test point", "Configured lower/upper range and fail direction", "Loop supply and burden evidence", "Independent process reference"],
              fieldTips: ["A credible HART PV with wrong loop current points downstream of the sensor", "Record the whole chain; one believable number is not a diagnosis"],
              stopConditions: ["Protective function affected", "Opening hazardous equipment without approved boundary", "Loop interruption could create an unsafe output"]),
        .init(id: "hart-diagnostics", category: "Smart instrumentation", title: "HART configuration and diagnostic review",
              useWhen: "Checking a smart transmitter without assuming the HMI or analog signal is truthful.",
              prerequisites: ["Use an approved communicator/modem and area method", "Preserve configuration before changing range, trim, damping, output mode, or burst settings"],
              sequence: ["Verify device identity, tag, manufacturer, model, revision, and device-description support", "Read PV, sensor temperature/status, range, units, damping, output mode, alarm direction, and diagnostics", "Compare HART PV with independent process truth and analog loop current", "Make changes only under an approved calibration/configuration procedure, then document as-left state"],
              expectedEvidence: ["Device identity and revision", "As-found/as-left configuration", "PV versus independent reference", "Analog output versus configured range"],
              fieldTips: ["Read configuration before touching trim — a wrong range can make a perfectly healthy transmitter lie with confidence"],
              stopConditions: ["Custody, SIS, ESD, emissions, or shutdown function affected", "Unknown device revision or unsupported DD", "Calibration would alter an operating limit"]),
        .init(id: "pressure-impulse", category: "Pressure measurement", title: "Impulse-line and pressure-transmitter diagnosis",
              useWhen: "Separating process pressure, plugged/leaking impulse tubing, manifold state, transmitter zero, and signal-path faults.",
              prerequisites: ["Confirm pressure boundary, isolation/equalization/vent configuration, temperature, hazardous area, and approved depressurization method"],
              sequence: ["Compare independent pressure and transmitter PV", "Inspect approved-access condition for leaks, frost, heat, corrosion, plugging, and support", "Verify manifold valve lineup and equalization state under procedure", "Check zero only at the documented reference condition; do not re-range to hide a process problem", "Prove response and restore valve lineup"],
              expectedEvidence: ["Upstream/downstream reference pressures", "Manifold state", "Ambient/process temperature", "Transmitter zero and response trend"],
              fieldTips: ["A slow transmitter is sometimes a fast transmitter connected to a very slow impulse line"],
              stopConditions: ["Pressure boundary or hydrocarbon release risk", "Opening/venting without permit and isolation", "Unknown manifold lineup"]),
        .init(id: "rtd-thermocouple", category: "Temperature", title: "RTD and thermocouple verification",
              useWhen: "Distinguishing sensor, extension wiring, polarity, compensation, transmitter, and scaling faults.",
              prerequisites: ["Confirm sensor type, wiring configuration, thermowell/process condition, temperature hazard, and approved simulator/dry-block method"],
              sequence: ["Verify sensor tag, type, lead count, polarity, extension/compensating cable, and transmitter configuration", "Compare local/independent temperature with controller PV", "Check resistance or millivolt behavior only with the sensor isolated as required", "Use a certified simulator or dry-block for transmitter input verification", "Restore wiring and prove engineering-unit scaling and alarm behavior"],
              expectedEvidence: ["Sensor type and wiring", "Reference temperature", "Resistance/mV or simulator input", "Raw and scaled AI values"],
              fieldTips: ["A thermocouple extension cable with the wrong alloy can create a very persuasive wrong answer"],
              stopConditions: ["Hot process or thermowell removal risk", "Protective temperature function affected", "Unapproved substitution of sensor type"]),
        .init(id: "valve-stroke", category: "Final elements", title: "Control-valve and actuator stroke test",
              useWhen: "Separating command, solenoid/positioner, air/hydraulic supply, mechanical travel, feedback, and process response.",
              prerequisites: ["Confirm process bypass/lineup, stored pressure, actuator energy, fail position, communications with operations, and approved stroke-test plan"],
              sequence: ["Record command, supply pressure, positioner output, travel feedback, and process response at defined points", "Check deadband, hysteresis, travel time, fail action, limit switches, and leakage indicators", "Compare indicated position with physical/mechanical reference where approved", "Return to normal lineup and prove the fail-safe/restoration state"],
              expectedEvidence: ["Command versus actual travel", "Supply pressure/current", "Feedback and limit state", "Process response"],
              fieldTips: ["A 100% command is a request, not a travel certificate"],
              stopConditions: ["Unexpected movement can expose personnel or process", "ESD/fail-safe function is involved without proof-test authorization", "Pressure boundary or hazardous release risk"]),
        .init(id: "insulation-resistance", category: "Electrical tests", title: "Insulation-resistance testing",
              useWhen: "Investigating cable, motor, or wiring insulation degradation, moisture, contamination, or intermittent ground faults.",
              prerequisites: ["Deenergize, lock out, verify zero energy, disconnect PLC/drive/transmitter/electronics, discharge capacitors, and use the approved test voltage"],
              sequence: ["Identify every connected device that could be damaged", "Test conductor-to-ground and conductor-to-conductor as specified", "Record test voltage, duration, temperature, humidity, and readings", "Compare time-dependent behavior and manufacturer/site acceptance criteria", "Discharge and reconnect under procedure"],
              expectedEvidence: ["Test voltage and duration", "Temperature/humidity", "Insulation readings by conductor", "As-found/as-left connection map"],
              fieldTips: ["A megger is wonderfully honest and spectacularly rude to electronics left connected to the circuit"],
              stopConditions: ["Any connected solid-state device", "Unknown stored energy or cable source", "Test voltage/acceptance criterion not specified"]),
        .init(id: "plc-io-trace", category: "PLC and control", title: "Read-only PLC I/O and logic trace",
              useWhen: "Separating field input, I/O module, tag mapping, logic permissive, output ownership, and HMI faults.",
              prerequisites: ["Confirm controller identity, running-project revision, controls authority, change-control boundary, and read-only access"],
              sequence: ["Capture controller mode, task health, faults, module status, and timestamps", "Compare raw input, alias/UDT/tag value, logic condition, output command, output module state, and feedback", "Check produced/consumed or EtherNet/IP connection state and RPI where applicable", "Trace first-out and sequence-of-events without forcing or toggling values", "Document evidence and obtain authorization before any change"],
              expectedEvidence: ["Controller/project revision", "Raw I/O and tag values", "Permissive/interlock states", "Module health and network status", "SOE timestamps"],
              fieldTips: ["If the HMI says 'running,' ask the PLC, the output module, and the feedback device separately"],
              stopConditions: ["Force, inhibit, online edit, download, mode change, safety task, or live interlock", "Unknown running project", "No rollback or controls authority"]),
        .init(id: "grounding-emi", category: "Signal integrity", title: "Grounding, shielding, and EMI/RFI diagnosis",
              useWhen: "Investigating noisy analog signals, intermittent communications, VFD coupling, ground loops, and unexplained resets.",
              prerequisites: ["Confirm energized-work boundary, system grounding design, shield termination convention, VFD routing, and approved test method"],
              sequence: ["Correlate the symptom with switching, drive speed, load, weather, or cable movement", "Compare signal at field, marshalling/barrier, I/O, and display boundaries", "Inspect routing, separation, bonding, shield/drain termination, conduit continuity, and unexpected parallel paths", "Use approved differential/common-mode and power-quality measurements; do not create a new ground path casually", "Verify noise reduction under the same operating conditions"],
              expectedEvidence: ["Noise amplitude/frequency and timing", "Signal values at multiple boundaries", "Cable routing and shield/bonding record", "VFD/load correlation"],
              fieldTips: ["A shield is not a magic blanket — its termination and reference are part of the design"],
              stopConditions: ["Grounding change affects fault-current path or hazardous-area IS system", "Unknown bonding design", "Energized cabinet access without approved method"]),
        .init(id: "calibration-documentation", category: "Calibration management", title: "As-found/as-left calibration and restoration proof",
              useWhen: "Any calibration, trim, range, alarm, trip, or configuration change that must be defensible later.",
              prerequisites: ["Approved procedure, instrument identity, traceable standard, range/units, tolerances, environmental conditions, and operations notification"],
              sequence: ["Record as-found condition before adjustment", "Verify test equipment calibration and connection method", "Apply test points across the required range and record actual/expected/error", "Adjust only within authorization; repeat as-left test", "Restore bypasses, alarms, trips, scaling, and normal lineup; obtain sign-off"],
              expectedEvidence: ["As-found/as-left values", "Standard ID and calibration status", "Error/tolerance calculation", "Configuration snapshot", "Restoration and acceptance sign-off"],
              fieldTips: ["If the as-found record disappears, the most valuable clue in the job just went missing"],
              stopConditions: ["SIS/ESD/custody/emissions function without specialized procedure", "No traceable standard", "Acceptance tolerance or restoration owner unknown"])
    ]

    public static func search(_ query: String, limit: Int = 8) -> [EEVeraFieldTechnique] {
        let terms = query.lowercased().split(whereSeparator: { $0 == " " || $0 == "," }).map(String.init)
        let scored = all.map { technique -> (EEVeraFieldTechnique, Int) in
            let text = ([technique.category, technique.title, technique.useWhen] + technique.sequence + technique.fieldTips + technique.expectedEvidence).joined(separator: " ").lowercased()
            let score = terms.reduce(0) { $0 + (text.contains($1) ? 1 : 0) }
            return (technique, score)
        }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
        return Array(scored.prefix(max(0, limit)).map { $0.0 })
    }
}
