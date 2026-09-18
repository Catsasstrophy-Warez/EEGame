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
}

/// Minimal RealityKit host view establishing the architecture for future
/// telemetry-driven 3D scenes. Presents a single procedural placeholder
/// entity; no real content yet.
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct RealitySceneView: View {
    public init() {}

    public var body: some View {
        RealityView { content in
            let panel = RealitySceneContent.buildPlaceholderPanel()
            content.add(panel)

            var pointLight = PointLightComponent()
            pointLight.intensity = 2000
            let light = Entity()
            light.components.set(pointLight)
            light.position = [0, 0.5, 0.5]
            content.add(light)
        }
        .accessibilityIdentifier("realityScene.root")
    }
}
#endif
