# Rev87 Physical Network Convergence

Rev87 deepens Rev86's single causal electrical truth instead of creating a parallel gameplay model.

## Implemented
- Per-phase source/transformer/feeder equivalent with phase loss and impedance-driven sag.
- Coordinated breaker, fuse and overload thermal memory with explicit trip cause.
- Contact temperature, arc-energy wear, operation count and welding state.
- Three-phase induction-motor equivalent driven from per-phase terminal voltage.
- PLC discrete-input burden, LED drop, filtering, hysteresis and ADC quantization.
- CircuitMNA-native 4–20 mA burden solution including both conductors, barrier and transmitter compliance.
- Bounded high-rate transient ring buffer.
- First-divergence reconstruction carrying index/time/channel/expected/observed coordinates.
- Deterministic JSON/FNV-1a state fingerprint for replay comparison.
- Adversarial phase-loss replay test.

## Causal path
Source/transformer -> feeder impedance -> protection -> contactor/contact condition -> motor -> source sag -> PLC/instrument electronics -> scope/SOE evidence.

Observers do not mutate the physical plant.

## Validation note
The portable Linux Swift build compiled ElectricalCore and CircuitMNA successfully, then exceeded the execution window while compiling the very large ScenarioEngine target. Rev87 tests are present and compile/run should be completed in Xcode or a less constrained Swift build environment before release qualification.
