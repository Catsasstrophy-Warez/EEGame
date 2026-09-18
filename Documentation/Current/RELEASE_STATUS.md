# Rev86 Causal Depth Release Status

## Scope
Rev86 is the current organized causal-depth handoff baseline. It does not claim physical-device release readiness until an Apple build is verified on macOS/Xcode and, where required, on physical hardware.

## Current implementation status
- Rev85 continuous causal-machine architecture retained.
- Rev86 breaker/fuse TCC, thermal memory and magnetic pickup implemented.
- Contact heating/degradation and contactor pull-in/dropout/bounce implemented.
- Three-phase motor start/inrush/slip/torque/heating/sag approximation implemented.
- PLC DI electronics, MNA-backed 4–20 mA burden/compliance, DMM/LoZ loading implemented.
- Real simulation-channel scope buffer, SOE transitions and first-divergence reconstruction implemented.
- Rev86 state persistence implemented.
- Production SwiftUI remains under `Sources/GameUI` and must consume shared truth.

## Release gates
| Gate | Status |
|---|---|
| Rev86 static causal validator | Re-run during organized-package validation |
| Unified static validators | Re-run during organized-package validation |
| SwiftPM `ScenarioEngine` build | Re-run during organized-package validation |
| SwiftPM `GameUI` build | Re-run during organized-package validation |
| Full SwiftPM tests | Re-run during organized-package validation; do not claim pass if execution does not complete |
| Xcode project regeneration | Requires XcodeGen on Mac for final Apple handoff |
| Xcode iPhone/iPad/Mac build | Requires Mac/Xcode |
| Codesign / embedded frameworks | Requires built Apple `.app` inspection |
| Simulator/device navigation smoke test | Requires Xcode runtime |
| Physical iPhone journey | Requires Apple hardware |

No unrun gate is represented as passed.

## Validation result for organized handoff
Static validation completed after the tidying pass:
- Rev86 causal-depth validator: PASS (12/12 checks).
- Rev85 continuous causal-machine validator: PASS.
- Unified electrical-truth validator: PASS.
- Static Xcode-project validator: PASS.

Portable Swift compilation was attempted repeatedly. In this execution environment, `swift build --target ScenarioEngine` progressed into ScenarioEngine compilation but did not complete before the execution timeout. A focused `Rev86CausalDepthTests` attempt likewise could not be completed. These gates remain **unverified here**, not failed and not claimed as passing.
