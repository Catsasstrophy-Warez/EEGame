# Roadmap — Rev86 → Rev87

1. Fold Rev86 protection, contacts, motors, PLC I/O and analog instrumentation into authoritative facility topology.
2. Add per-phase feeder MNA representation with conductor/source impedance.
3. Add transformer/source equivalents, phase loss, voltage unbalance and neutral/ground paths.
4. Extend protection with overload classes, calibrated TCC data structures and ground-fault behavior.
5. Extend contactors with arc energy, erosion, welding and temperature-dependent mechanical/electrical consequences.
6. Calibrate motor starting against equivalent-circuit behavior, acceleration and voltage sag.
7. Promote 4–20 mA loops to native node-by-node MNA topology: supply, wire, barrier, transmitter, AI burden and return.
8. Add PLC/AI ADC quantization, tolerances, filtering and explicit invalid/fault states.
9. Add deterministic replay hashes and adversarial causal reconstruction tests.
10. Run XcodeGen, full Apple builds, UI reachability/XCUI journeys and device validation on macOS/Xcode.

## Organization rule
Do not add new top-level `Rev87Something.swift` files by default. Prefer capability-oriented folders/facades described in `SOURCE_DOMAIN_MAP_REV86.md` while keeping legacy RevXX symbols intact where compatibility requires them.
