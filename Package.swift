// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ElectricEngineerGame",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "ElectricalCore", targets: ["ElectricalCore"]),
        .library(name: "CircuitMNA", targets: ["CircuitMNA"]),
        .library(name: "ScenarioEngine", targets: ["ScenarioEngine"]),
        .library(name: "RealityScene", targets: ["RealityScene"]),
        .library(name: "MetalTelemetry", targets: ["MetalTelemetry"]),
        .library(name: "GameUI", targets: ["GameUI"])
    ],
    targets: [
        .target(name: "ElectricalCore"),
        .target(name: "CircuitMNA", dependencies: ["ElectricalCore"]),
        .target(name: "ScenarioEngine", dependencies: ["ElectricalCore", "CircuitMNA"]),
        .target(name: "RealityScene"),
        .target(name: "MetalTelemetry"),
        .target(name: "GameUI", dependencies: ["ScenarioEngine", "RealityScene", "MetalTelemetry"]),
        .testTarget(name: "ElectricalCoreTests", dependencies: ["ElectricalCore", "CircuitMNA", "ScenarioEngine"])
    ]
)
