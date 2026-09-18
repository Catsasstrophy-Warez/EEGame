#if canImport(RealityKit) && canImport(SwiftUI)
import RealityKit
import SwiftUI

/// Procedural scaffold for the RealityKit rendering pipeline. No authored
/// assets — every entity is built in code so this target stays fully
/// scriptable and testable without a content pipeline.
@MainActor
public enum RealitySceneContent {
    /// Node names in the circuit row, left to right: supply, breaker, load.
    public static let sourceName = "CircuitSource"
    public static let breakerName = "CircuitBreaker"
    public static let loadName = "CircuitLoad"
    public static let wireSourceToBreakerName = "WireSourceToBreaker"
    public static let wireBreakerToLoadName = "WireBreakerToLoad"

    private static func node(name: String, size: SIMD3<Float>, position: SIMD3<Float>, color: NodeColor) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: size, cornerRadius: 0.01)
        var material = SimpleMaterial()
        material.color = .init(tint: .init(red: color.red, green: color.green, blue: color.blue, alpha: 1))
        material.roughness = .float(0.4)
        material.metallic = .float(0.2)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        entity.position = position
        entity.generateCollisionShapes(recursive: false)
        entity.components.set(InputTargetComponent())
        return entity
    }

    /// Human-readable label for a tapped node, shown in the inspector overlay.
    public static func displayName(for nodeName: String) -> String {
        switch nodeName {
        case sourceName: return "Supply"
        case breakerName: return "Breaker"
        case loadName: return "Load"
        case wireSourceToBreakerName: return "Supply → Breaker"
        case wireBreakerToLoadName: return "Breaker → Load"
        default: return nodeName
        }
    }

    /// Builds the source -> breaker -> load row with connecting wire
    /// segments, all procedural. Returns the parent entity containing every
    /// node so callers can add it in one call.
    public static func buildCircuitRow() -> Entity {
        let root = Entity()
        root.name = "CircuitRow"

        let source = node(name: sourceName, size: [0.16, 0.16, 0.16], position: [-0.4, 0, 0], color: .neutral)
        let breaker = node(name: breakerName, size: [0.14, 0.2, 0.14], position: [0, 0, 0], color: .neutral)
        let load = node(name: loadName, size: [0.16, 0.16, 0.16], position: [0.4, 0, 0], color: .neutral)
        let wireA = node(name: wireSourceToBreakerName, size: [0.24, 0.02, 0.02], position: [-0.2, 0, 0], color: .neutral)
        let wireB = node(name: wireBreakerToLoadName, size: [0.24, 0.02, 0.02], position: [0.2, 0, 0], color: .neutral)

        for entity in [source, wireA, breaker, wireB, load] { root.addChild(entity) }
        return root
    }

    private struct NodeColor {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat

        static let neutral = NodeColor(red: 0.35, green: 0.38, blue: 0.42)
        static let energized = NodeColor(red: 0.15, green: 0.55, blue: 0.85)

        static func heated(intensity: Float) -> NodeColor {
            .init(red: 0.95, green: 0.65 - 0.45 * CGFloat(intensity), blue: 0.12)
        }
    }

    /// Recolors every node in a circuit row to reflect live state:
    /// - source: energized tint whenever the circuit is energized.
    /// - breaker: same, but this is the node an open breaker would de-energize first.
    /// - wires + load: heated amber/red as voltage climbs toward `referenceVoltage`, neutral otherwise.
    public static func applyElectricalState(to root: Entity, energized: Bool, voltage: Double, referenceVoltage: Double = 30) {
        let intensity = Float(min(max(voltage / max(referenceVoltage, 1e-9), 0), 1))
        let sourceColor: NodeColor = energized ? .energized : .neutral
        let downstreamColor: NodeColor = energized ? .heated(intensity: intensity) : .neutral

        for name in [sourceName, breakerName] {
            guard let entity = root.findEntity(named: name) as? ModelEntity else { continue }
            recolor(entity, sourceColor)
        }
        for name in [wireSourceToBreakerName, wireBreakerToLoadName, loadName] {
            guard let entity = root.findEntity(named: name) as? ModelEntity else { continue }
            recolor(entity, downstreamColor)
        }
    }

    private static func recolor(_ entity: ModelEntity, _ color: NodeColor) {
        var material = SimpleMaterial()
        material.color = .init(tint: .init(red: color.red, green: color.green, blue: color.blue, alpha: 1))
        material.roughness = .float(0.4)
        material.metallic = .float(0.2)
        entity.model?.materials = [material]
    }
}

/// RealityKit host view for the Quick Bench panel, driven live by the MNA
/// solver's ElectricalSnapshot (via `energized`/`voltage`, passed in by the
/// caller — this target has no ScenarioEngine dependency of its own).
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct RealitySceneView: View {
    public var energized: Bool
    public var voltage: Double
    public var referenceVoltage: Double

    @State private var selectedNodeName: String?

    public init(energized: Bool = false, voltage: Double = 0, referenceVoltage: Double = 30) {
        self.energized = energized
        self.voltage = voltage
        self.referenceVoltage = referenceVoltage
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            RealityView { content in
                let row = RealitySceneContent.buildCircuitRow()
                RealitySceneContent.applyElectricalState(to: row, energized: energized, voltage: voltage, referenceVoltage: referenceVoltage)
                content.add(row)

                var pointLight = PointLightComponent()
                pointLight.intensity = 2000
                let light = Entity()
                light.components.set(pointLight)
                light.position = [0, 0.5, 0.5]
                content.add(light)
            } update: { content in
                guard let row = content.entities.first(where: { $0.name == "CircuitRow" }) else { return }
                RealitySceneContent.applyElectricalState(to: row, energized: energized, voltage: voltage, referenceVoltage: referenceVoltage)
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        selectedNodeName = value.entity.name
                    }
            )
            .realityViewCameraControls(.orbit)
            .accessibilityIdentifier("realityScene.root")

            if let selectedNodeName {
                inspector(for: selectedNodeName)
            }
        }
    }

    @ViewBuilder
    private func inspector(for nodeName: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(RealitySceneContent.displayName(for: nodeName))
                .font(.system(size: 13, weight: .bold, design: .rounded))
            if nodeName == RealitySceneContent.sourceName || nodeName == RealitySceneContent.breakerName {
                Text(energized ? "Energized" : "De-energized")
                    .font(.system(size: 11, design: .monospaced))
            } else {
                Text(String(format: "%.2f V", voltage))
                    .font(.system(size: 11, design: .monospaced))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
        .padding(12)
        .accessibilityIdentifier("realityScene.inspector")
    }
}
#endif
