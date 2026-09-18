
## Rev85 source-membership requirement

This handoff adds `ContinuousCausalMachine85.swift` and Rev85 tests. **Run `xcodegen generate` before opening/building the project** so directory-discovered sources in `project.yml` become members of the Xcode targets. The checked-in `.xcodeproj` is retained for continuity but is not authoritative for late source membership.

# Electric Engineer Game Rev84 — Cross-Computer Xcode Handoff

## Authoritative baseline
Rev84 Unified Electrical Truth.

## Goal on destination Mac
Open the project, regenerate the Xcode project from `project.yml` with XcodeGen if available, select the Electric Engineer app target, choose the destination Apple device, configure the local Development Team/signing identity, build, install, and launch.

## Important architecture
Runtime dependency direction:
`ElectricalCore → CircuitMNA → ScenarioEngine → GameUI → Electric Engineer app`

The app must embed/sign:
- ElectricalCore.framework
- CircuitMNA.framework
- ScenarioEngine.framework
- GameUI.framework

Do not flatten these targets during bring-up.

## Bundle identifiers
- ElectricalCore: `com.electricengineer.training.ElectricalCore`
- CircuitMNA: `com.electricengineer.training.CircuitMNA`
- ScenarioEngine: `com.electricengineer.training.ScenarioEngine`
- GameUI: `com.electricengineer.training.GameUI`
- App: `com.electricengineer.training.game`

The destination Mac may need a locally unique app bundle identifier if signing reports that the app ID is unavailable. If changed, keep the framework identifiers coherent and record the change.

## Destination Mac checklist
1. Install/currently use a compatible Xcode and accept its license/components.
2. Extract this archive to a normal writable local folder. Do not build directly from inside the ZIP or iCloud placeholder storage.
3. In Terminal, `cd` to the project root.
4. Run `python3 Scripts/validate_xcode_project.py`.
5. Run `bash Scripts/xcode_readiness.sh`.
6. If XcodeGen is installed, run `xcodegen generate` so `project.yml` remains the source of truth.
7. Open the generated/bundled `.xcodeproj`.
8. Select the Electric Engineer app target.
9. Under Signing & Capabilities, choose the Development Team belonging to that Mac/user.
10. Connect and trust the iPhone, enable Developer Mode if iOS requests it, and choose it as the run destination.
11. Clean Build Folder if the project came from another machine.
12. Build.
13. If compilation fails, fix Swift/API errors without deleting simulation/game functionality.
14. Confirm all four runtime frameworks are present in the built app's Frameworks directory and set to Embed & Sign.
15. Run the app on-device.
16. Verify Bench, Engineering, Field, Facility Twin, Interactive DMM, Schematic Twin, Commissioning Console and Unified Electrical Truth are reachable.
17. Exercise DS-04/fuse/overload changes and confirm downstream solved voltages respond.
18. Test RealityKit surfaces on Apple hardware. They are guarded by `canImport(RealityKit)` and were not compiled in the Linux packaging environment.
19. Run available tests/validators after fixes.
20. Archive the working destination-machine revision before further feature development.

## Current verification boundary
Static project validation and shell-script syntax checks were green during Rev84 packaging. The packaging environment does not provide Xcode, codesigning, Apple SDK RealityKit compilation, or physical-iPhone launch validation. Those are destination-Mac release gates.

## Rev84 engineering truth
Protection/commissioning state is bridged into a CircuitMNA network:
`PS1 → DS-04 → fuses/overload → PLC DO4 → TB1:12 → W-1207/JB-14 → SOL-101 → 0V`.

The Unified Electrical Truth DMM reads solved node differences. Keep this path authoritative while converging older representative simulation paths.

## First things to inspect if build fails
- SwiftUI/RealityKit availability or API signatures in Rev81–Rev83 visual files.
- Test-target ownership: several recent integration-style tests live under `Tests/ElectricalCoreTests` while importing `ScenarioEngine`; if target dependencies reject this, move them into a ScenarioEngine/Integration test target rather than weakening production dependencies.
- Framework Embed & Sign settings.
- Signing/team/provisioning on the destination Mac.
