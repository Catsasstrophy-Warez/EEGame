# Test Matrix — Rev86

## Portable gates
- Rev86 causal-depth static validator.
- Rev85 continuous causal-machine validator.
- unified electrical-truth/static architecture validators retained from prior baselines.
- SwiftPM build of `ScenarioEngine`.
- SwiftPM build of `GameUI` where SwiftUI availability permits the target to compile in the current environment.
- full SwiftPM test suite when execution completes within the environment.

## Rev86 causal-depth coverage
The Rev86 handoff adds 10 causal-depth tests covering the new protection/contact/contactor/motor/PLC/loop/meter/scope/SOE/persistence layers plus a 12-point static validator.

## Apple-only gates
Portable validation is not evidence of iPhone/iPad/Mac Catalyst correctness. The following require macOS/Xcode:
- regenerate/update the Xcode project with XcodeGen,
- iOS/iPadOS/macOS or Catalyst compile as configured,
- signing/codesign verification,
- simulator navigation smoke tests,
- XCUI journeys/accessibility identifiers,
- physical-device launch and gameplay verification.

No incomplete or unrun gate is recorded as passing.
