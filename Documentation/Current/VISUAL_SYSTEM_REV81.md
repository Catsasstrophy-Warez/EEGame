# Rev81 Reality Spatial Twin Foundation

Rev81 begins the native RealityKit presentation layer without creating a second simulation.

Implemented:
- RealityKit spatial twin guarded by `canImport(RealityKit)`;
- 3D electrical room floor, MCC cabinet, PLC face, terminal row, field JB, transmitter and valve;
- RealityKit custom identity component carrying facility ID, electrical node, conductor ID and drawing reference;
- telemetry component carrying voltage, current, temperature, energized state and observed causal state;
- tap targeting/collision shapes to drive the same selected identity used by 2D cabinet, schematic, Golden Thread and diagnostics;
- cross-platform spatial manifest in ScenarioEngine so identity validation does not depend on RealityKit;
- tests for manifest integrity and terminal/valve cross-domain bindings.

Rule: RealityKit is presentation only. CircuitMNA/ScenarioEngine remain authoritative for electrical and causal truth.
