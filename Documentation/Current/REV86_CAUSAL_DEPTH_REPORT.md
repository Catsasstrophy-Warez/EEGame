# Rev86 Causal Depth Report

Rev86 extends the Rev85 Continuous Causal Machine without introducing a parallel simulation truth.

## Implemented
- Log/log interpolated breaker/fuse time-current curve infrastructure.
- Stateful breaker thermal memory plus instantaneous magnetic pickup.
- Temperature-dependent contact resistance, I²R heating, cooling and degradation.
- RL contactor coil, armature dynamics, pull-in/dropout, contact touch/bounce and welded-state foundation.
- Three-phase motor starting approximation with slip, inrush, torque, inertia, load, winding heat and feeder voltage sag.
- PLC discrete-input threshold, hysteresis and input filtering.
- CircuitMNA-backed 4–20 mA analog input burden with transmitter compliance limitation.
- DMM/LoZ loading model for high-impedance/ghost-voltage experiments.
- Real simulation-channel scope ring buffer. Rev86 does not synthesize diagnostic waveforms.
- Sequence-of-events transitions generated from state changes.
- First-divergence comparison over observed scope histories.
- Codable persistence for breaker memory, contact heat/degradation, contactor, motor, PLC I/O and evidence.
- 10 Rev86 causal-depth tests plus a 12-point static validator.

## Validation observed in this environment
- `python3 Scripts/validate_causal_depth86.py`: 12/12 PASS.
- `swift build --target ScenarioEngine`: PASS under Swift 6 portable build.
- `swift test --filter Rev86CausalDepthTests`: test-target compilation progressed through Rev86 tests but the complete package test build did not finish within the execution window. This is not claimed as a passing test run.

## Apple/Xcode gate
This environment cannot perform an Apple SDK / RealityKit device build. On the Mac, regenerate the Xcode project from `project.yml` with XcodeGen before building so the new source/test files are included. Then run the full XCTest/Swift Testing suite and physical-iPhone journey.

## Next physical depth
Rev87 should fold these components into the authoritative facility topology rather than expanding breadth: per-phase MNA feeder representation, phase loss/unbalance, transformer/source equivalents, contact welding/erosion energy, motor equivalent-circuit calibration, overload classes, ground-fault paths, true analog-loop MNA topology with wire/barrier/transmitter nodes, instrument ADC error/quantization, and deterministic replay hashes.
