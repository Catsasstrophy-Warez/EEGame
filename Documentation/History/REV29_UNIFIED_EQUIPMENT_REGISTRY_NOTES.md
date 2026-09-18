# Rev29 — Unified Equipment Registry & Golden Thread Tooling

Rev29 unifies equipment metadata so one definition can carry physical footprint/mounting, terminal maps, electrical/pneumatic/process/network interfaces, diagnostics, commissioning, maintenance/calibration effects, degradation primitives, drawing identity, and future RealityKit asset identity.

It adds conceptual definitions for PIT/TIT/FIT/LIT, DVC, I/P, MX5-style remote I/O, and PF2100-aware burner management. Vendor-specific entries remain educational abstractions unless exact public documentation has been verified.

A synchronized Golden Thread binds one identity across cabinet, loop sheet, wiring diagram, terminal plan, I/O list, PLC tag, and HMI. Reverse lookup supports tracing from any surface back to the common identity.

Physical test points and field tools now support DMM voltage/current evidence, loop-calibrator source/simulate behavior, pressure and temperature points, plus extensible HART/scope/thermal/network modes. Test-disconnect boundaries create explicit field-side/system-side diagnostic partitions.

Safety: this simulator is not a substitute for manufacturer instructions, electrical safe-work procedures, hazardous-location requirements, burner-management commissioning procedures, or applicable codes/standards.
