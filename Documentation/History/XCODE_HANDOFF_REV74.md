# Rev74 Xcode-Ready Framework Embedding Fix

## Confirmed device failure
The user's actual Debug-iphoneos app contained only `GameUI.framework`.
`GameUI.framework` dynamically links `@rpath/ScenarioEngine.framework/ScenarioEngine`, so dyld can abort before SwiftUI reaches its first frame.

## Rev74 correction
`project.yml` now makes all four dynamic frameworks direct application dependencies with `embed: true`:

- ElectricalCore
- CircuitMNA
- ScenarioEngine
- GameUI

The bundled `.xcodeproj` already contains all four in the ElectricEngineerGame target's Frameworks and Embed Frameworks phases with CodeSignOnCopy. Rev74 makes the XcodeGen source of truth match that required runtime behavior.

## On the Mac
Delete the old app from the iPhone and clear this project's DerivedData before opening/building Rev74.

After building, the final app must contain:
- Frameworks/GameUI.framework
- Frameworks/ScenarioEngine.framework
- Frameworks/CircuitMNA.framework
- Frameworks/ElectricalCore.framework

Do not proceed to SwiftUI/simulation debugging if any is absent.
