# Rev85 Continuous Causal Machine

Rev85 begins the conversion from parallel/synthetic truth paths to one deterministic causal machine loop.

## Implemented in this pass

- New `ContinuousCausalMachine85.swift` in ScenarioEngine.
- CircuitMNA-backed 24 V control path with source impedance, disconnect, fuse/overload state, PLC output, TB1:12, cable/JB and SOL-101 coil.
- Electrical I²R loss drives TB1:12 thermal state.
- Fuse I²t accumulation and overload thermal memory are persistent state and can open the electrical path.
- RL coil current, magnetic force, armature position and valve travel are stateful rather than instant Boolean consequences.
- Valve position drives a first-order process-pressure model.
- PIT-style transmitter maps process pressure to 4–20 mA with damping and loop-compliance limiting.
- PLC analog raw/scaled process value consumes realized loop current.
- Evidence frames observe electrical/thermal/actuator/process/instrument/PLC state and do not feed back into physics.
- Fault injection mutates physical/configuration parameters instead of assigning symptoms.
- Latent degradation/configuration state is Codable for save/reload and deterministic replay foundations.
- Added Rev85 Golden Causal tests for healthy propagation, degraded terminal, open disconnect, weak supply, valve binding, scaling separation, evidence non-authority and persistence.

## Compatibility repairs found during portable compile

- Fixed Swift 6 whitespace in `EEForensicWorkbench79.swift`: `offset: CGSize = .zero`.
- Added the missing public memberwise initializer to `EEForensicFrame79`, allowing the existing cross-module Rev79 tests/UI to construct forensic frames.

## Validation status

- ScenarioEngine Rev85 source compiled successfully during SwiftPM build stages in the available Linux Swift 6 environment.
- GameUI also progressed through compilation after the Rev79 whitespace repair.
- The complete `swift test` link/run did not finish inside the available execution window, so this report does **not** claim the Rev85 test suite passed.
- Apple RealityKit/Xcode/device validation remains an Apple-hardware gate.

## Xcode project membership

`project.yml` uses directory source discovery (`Sources/ScenarioEngine`, `Sources/GameUI`), so regenerating with XcodeGen includes Rev85 automatically. The bundled `.xcodeproj` predates some late source additions and should not be treated as authoritative source membership. On the Mac, run `xcodegen generate` before opening/building the project.

## Next causal depth

1. Replace simplified fuse I²t threshold with authored time-current curve packs.
2. Add contact-temperature-dependent resistance and degradation feedback.
3. Add contactor main-contact topology and pull-in/dropout/bounce.
4. Add three-phase motor/source model and start-voltage sag.
5. Add PLC discrete input threshold/hysteresis/filter electronics.
6. Move the 4–20 mA loop itself into CircuitMNA instead of the current compliance approximation.
7. Add measurement loading for DMM/LoZ.
8. Replace Rev79 synthetic scope samples with transient truth ring buffers.
9. Add SOE causal-parent graph and healthy-vs-observed first divergence.
10. Bind Rev85 machine truth into GameUI/RealityKit after the causal kernel is green headlessly.
