# Electric Engineer Game — Rev73 Xcode-Ready Stabilization

This package is a stabilization handoff of Rev72. No simulation feature set was intentionally removed.

## Canonical bundle identifiers

- ElectricalCore: `com.electricengineer.training.ElectricalCore`
- CircuitMNA: `com.electricengineer.training.CircuitMNA`
- ScenarioEngine: `com.electricengineer.training.ScenarioEngine`
- GameUI: `com.electricengineer.training.GameUI`
- App: `com.electricengineer.training.game`
- Test bundle: `com.electricengineer.training.tests`

Both `project.yml` and the bundled `ElectricEngineerGame.xcodeproj` were aligned to these identifiers.

## First Xcode run

1. Open `ElectricEngineerGame.xcodeproj`.
2. Select the **ElectricEngineerGame** scheme.
3. Select your Apple Development Team under Signing & Capabilities.
4. Keep Automatically manage signing enabled.
5. Clean Build Folder.
6. Delete any older Electric Engineer build from the iPhone.
7. Build and run on the physical iPhone.

If XcodeGen is installed, `project.yml` remains the intended configuration source and can be used to regenerate the project.

## White-screen isolation

If the app still opens to white, do not rewrite the simulation engine first. Rev72 startup runtime initialization is lightweight.

Test the app entry with a static SwiftUI `Text`/`ZStack` first. If that renders, directly launch `Rev72IntegratedLabView()` and inspect the Xcode device console for the first runtime failure.

## Validation

Run:

```bash
python3 Scripts/validate_xcode_project.py
bash -n Scripts/xcode_readiness.sh
swift test
```

The static validator now checks both `project.yml` and the bundled `.xcodeproj` for the canonical bundle identifiers and rejects legacy `com.controlstechtrainer` identifiers.

A full physical-device first-frame/UI validation still must be performed in Xcode on macOS.
