# Rev72 Xcode Readiness

Production entry point now launches Rev72IntegratedLabView. XcodeGen project.yml targets iOS 18, iPhone+iPad, automatic signing, and Mac Catalyst. Package.swift remains the portable Swift validation path.

## Xcode checklist
1. Install XcodeGen if project generation is desired, then run `xcodegen generate` at repository root.
2. Open `ElectricEngineerGame.xcodeproj`.
3. Select the ElectricEngineerGame target and your Development Team.
4. Build first for an iOS Simulator, then iPhone/iPad, then My Mac (Designed for iPad) or Mac Catalyst as applicable.
5. Run ElectricalCoreTests.
6. Exercise Quick Bench, Engineering, and Field tabs and all simulation controls.
7. Perform accessibility, Dynamic Type, rotation, split-view, memory, and performance passes.

Linux validation does not prove Apple SDK availability, signing, SF Symbols, device install, or Catalyst behavior. Those remain Xcode validation items.
