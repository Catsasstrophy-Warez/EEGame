# Project
Native iOS game architecture and telemetry rendering. Built entirely on Apple native frameworks: Swift 6, RealityKit, and Metal.

# Non-Negotiables
- Concurrency: Strict Swift 6 concurrency only. All UI and RealityKit state mutations must be isolated to `@MainActor`.
- Memory: Avoid unmanaged memory structures (e.g., `UnsafeMutablePointer`) unless interfacing directly with raw C buffers for telemetry or Metal shaders.
- Ecosystem: Rely strictly on Swift Package Manager. Do NOT suggest cross-platform tools, Unity patterns, or C# logic.

# Commands
- Build: `xcodebuild -scheme ElectricEngineerGame -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -quiet`
  (the scheme is `ElectricEngineerGame` per `project.yml`/XcodeGen — "WrenchToRace" was never an actual target in this repo)
- Test: `swift test --quiet`
- Lint: `swiftlint lint --quiet`
- CI: `.github/workflows/ci.yml` runs `swift build`/`swift test` + the project's Python validators on Linux on every push, and a full `xcodebuild build`/`test` + SwiftLint on macOS.
*(Note: Always run commands with quiet flags to prevent console output from flooding the token context window).*

# Language & Style
- Omit explicit `return` in single-expression functions.
- Prefer `guard` over nested `if let` to prevent pyramid of doom.
- Use `os_log` for critical performance telemetry instead of standard print statements.
