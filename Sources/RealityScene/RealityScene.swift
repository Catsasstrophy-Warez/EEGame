#if canImport(RealityKit) && canImport(SwiftUI)
import RealityKit
import SwiftUI

/// Procedural scaffold for the RealityKit rendering pipeline. No authored
/// assets — every entity is built in code so this target stays fully
/// scriptable and testable without a content pipeline.
@MainActor
public enum RealitySceneContent {
    public static func buildPlaceholderPanel() -> ModelEntity {
        let mesh = MeshResource.generateBox(size: 0.3, cornerRadius: 0.01)
        var material = SimpleMaterial()
        material.color = .init(tint: .init(red: 0.15, green: 0.55, blue: 0.85, alpha: 1))
        material.roughness = .float(0.4)
        material.metallic = .float(0.2)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "PlaceholderPanel"
        return entity
    }

    /// Recolors the placeholder to reflect live circuit state. De-energized
    /// panels stay a neutral blue; energized ones shift toward amber/red as
    /// voltage climbs toward `referenceVoltage`.
    public static func applyElectricalState(to entity: ModelEntity, energized: Bool, voltage: Double, referenceVoltage: Double = 30) {
        var material = SimpleMaterial()
        let intensity = Float(min(max(voltage / max(referenceVoltage, 1e-9), 0), 1))
        material.color = energized
            ? .init(tint: .init(red: 0.95, green: CGFloat(0.65 - 0.45 * Double(intensity)), blue: 0.12, alpha: 1))
            : .init(tint: .init(red: 0.15, green: 0.55, blue: 0.85, alpha: 1))
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

    public init(energized: Bool = false, voltage: Double = 0, referenceVoltage: Double = 30) {
        self.energized = energized
        self.voltage = voltage
        self.referenceVoltage = referenceVoltage
    }

    public var body: some View {
        RealityView { content in
            let panel = RealitySceneContent.buildPlaceholderPanel()
            RealitySceneContent.applyElectricalState(to: panel, energized: energized, voltage: voltage, referenceVoltage: referenceVoltage)
            content.add(panel)

            var pointLight = PointLightComponent()
            pointLight.intensity = 2000
            let light = Entity()
            light.components.set(pointLight)
            light.position = [0, 0.5, 0.5]
            content.add(light)
        } update: { content, _ in
            guard let panel = content.entities.first(where: { $0.name == "PlaceholderPanel" }) as? ModelEntity else { return }
            RealitySceneContent.applyElectricalState(to: panel, energized: energized, voltage: voltage, referenceVoltage: referenceVoltage)
        }
        .accessibilityIdentifier("realityScene.root")
    }
}
#endif
