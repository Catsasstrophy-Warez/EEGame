# Rev32 — Live Simulation Binding

Rev32 replaces the static visual prototype as the default `ElectricEngineerGameView` with a shared mutable `Rev32LivePlant`. Station, cabinet, Golden Thread, DMM, HART, DVC, burner, and construction screens read and mutate the same simulation state.

Key executable flows:
- PIT-401 process/loop/I/O/HMI propagation with a modeled DISC-401 divergence.
- Open/close test-disconnect boundary and source a known current on the system side.
- DMM evidence recording at physical signal stages.
- HART range changes propagate into loop current and downstream indication.
- Termination torque/repair clears or preserves the same Golden Thread fault.
- DVC relay replacement invalidates calibration; calibration and tracking proof gate readiness.
- Burner event acknowledgement persists in the shared evidence ledger.
- Golden Thread surfaces remain bound to one signal identity.

`project.yml` and a SwiftUI `@main` app entry were added for XcodeGen/iOS handoff. Portable validation is Swift 6.2.1/Linux. Xcode generation, iOS compilation, signing, simulator/device execution, and Mac Catalyst remain to be validated on Apple tooling.
