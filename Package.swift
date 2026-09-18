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
        .library(name: "GameUI", targets: ["GameUI"])
    ],
    targets: [
        .target(name: "ElectricalCore"),
        .target(name: "CircuitMNA", dependencies: ["ElectricalCore"]),
        .target(name: "ScenarioEngine", dependencies: ["ElectricalCore", "CircuitMNA"]),
        .target(name: "RealityScene"),
        .target(name: "GameUI", dependencies: ["ScenarioEngine", "RealityScene"]),
        .testTarget(name: "ElectricalCoreTests", dependencies: ["ElectricalCore", "CircuitMNA", "ScenarioEngine"])
    ]
)
