# Rev64 Physical Instrument Qualification

Rev64 converts the Rev63 I&E/Controls truth chain into an interactive qualification runtime.

## Added
- Probe-placement-aware virtual instrument modes.
- Loop current/voltage, process, smart-device, scope, network and CAN readings backed by simulation state.
- DP manifold manipulation and impulse restriction consequences.
- Separate as-found/as-left calibration records.
- PLC scan microscope.
- First-divergence analysis across process → impulse → transmitter → loop → I/O → scaling → network → HMI.
- Evidence capture with simulation provenance.
- Codable data-driven scenario definitions and loader foundation.
- SwiftUI qualification surface.

## Architecture policy
GameUI displays and commands state. It does not calculate electrical truth. Electrical truth remains in CircuitMNA/ScenarioEngine.

## Safety/authenticity
Models are educational/generic. They are not manufacturer acceptance criteria, site procedures, or regulatory thresholds.
