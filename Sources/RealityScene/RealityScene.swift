#if canImport(RealityKit) && canImport(SwiftUI)
import RealityKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Generic, ScenarioEngine-agnostic fault presentation for the circuit
/// scene. The caller (GameUI, which already depends on ScenarioEngine) maps
/// its real fault model onto this — RealityScene stays decoupled.
public enum CircuitFaultVisual: Sendable, Equatable {
    case none
    /// A phase/leg of the circuit is open — upstream nodes go dark
    /// regardless of `energized`.
    case openCircuit
    /// A line-to-ground fault — the load pulses red/orange.
    case groundFault
    /// A line-to-line or three-phase fault — the wires pulse hot red.
    case shortCircuit
    /// A non-destructive but abnormal condition (e.g. reversed sequence) —
    /// the breaker shows amber.
    case warning
}

/// Procedural scaffold for the RealityKit rendering pipeline. No authored
/// assets — every entity is built in code so this target stays fully
/// scriptable and testable without a content pipeline.
@MainActor
public enum RealitySceneContent {
    public static let sourceName = "CircuitSource"
    public static let breakerName = "CircuitBreaker"
    public static let junctionName = "CircuitJunction"
    public static let loadAName = "CircuitLoadA"
    public static let loadBName = "CircuitLoadB"
    public static let wireSourceToBreakerName = "WireSourceToBreaker"
    public static let wireBreakerToJunctionName = "WireBreakerToJunction"
    public static let wireJunctionToLoadAName = "WireJunctionToLoadA"
    public static let wireJunctionToLoadBName = "WireJunctionToLoadB"

    private enum NodeShape { case supply, switchBody, load }

    private static func node(name: String, shape: NodeShape, position: SIMD3<Float>, color: NodeColor) -> ModelEntity {
        let mesh: MeshResource
        switch shape {
        case .supply: mesh = .generateCylinder(height: 0.2, radius: 0.09)
        case .switchBody: mesh = .generateBox(size: [0.14, 0.22, 0.1], cornerRadius: 0.02)
        case .load: mesh = .generateSphere(radius: 0.09)
        }
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

    /// A thin cylinder oriented from `from` to `to`, standing in for a wire
    /// segment. `MeshResource.generateCylinder` runs along its local Y axis
    /// by default, so the entity is rotated to point along the segment.
    private static func wire(name: String, from: SIMD3<Float>, to: SIMD3<Float>, color: NodeColor) -> ModelEntity {
        let length = simd_distance(from, to)
        let mesh = MeshResource.generateCylinder(height: length, radius: 0.012)
        var material = SimpleMaterial()
        material.color = .init(tint: .init(red: color.red, green: color.green, blue: color.blue, alpha: 1))
        material.roughness = .float(0.3)
        material.metallic = .float(0.3)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        entity.position = (from + to) / 2
        let direction = normalize(to - from)
        entity.orientation = simd_quatf(from: [0, 1, 0], to: direction)
        entity.generateCollisionShapes(recursive: false)
        entity.components.set(InputTargetComponent())
        return entity
    }

    /// Human-readable label for a tapped node, shown in the inspector overlay.
    public static func displayName(for nodeName: String) -> String {
        switch nodeName {
        case sourceName: return "Supply"
        case breakerName: return "Breaker"
        case junctionName: return "Junction"
        case loadAName: return "Load A"
        case loadBName: return "Load B"
        case wireSourceToBreakerName: return "Supply → Breaker"
        case wireBreakerToJunctionName: return "Breaker → Junction"
        case wireJunctionToLoadAName: return "Junction → Load A"
        case wireJunctionToLoadBName: return "Junction → Load B"
        default: return nodeName
        }
    }

    /// Builds source -> breaker -> junction -> {load A, load B}: a small
    /// branching topology (5 nodes, 4 wire segments) rather than a single
    /// straight-line row, so a circuit with a real fork is representable.
    public static func buildCircuitRow() -> Entity {
        let root = Entity()
        root.name = "CircuitRow"

        let sourcePos: SIMD3<Float> = [-0.5, 0, 0]
        let breakerPos: SIMD3<Float> = [-0.2, 0, 0]
        let junctionPos: SIMD3<Float> = [0.1, 0, 0]
        let loadAPos: SIMD3<Float> = [0.4, 0.15, 0]
        let loadBPos: SIMD3<Float> = [0.4, -0.15, 0]

        let source = node(name: sourceName, shape: .supply, position: sourcePos, color: .neutral)
        let breaker = node(name: breakerName, shape: .switchBody, position: breakerPos, color: .neutral)
        let junction = node(name: junctionName, shape: .switchBody, position: junctionPos, color: .neutral)
        let loadA = node(name: loadAName, shape: .load, position: loadAPos, color: .neutral)
        let loadB = node(name: loadBName, shape: .load, position: loadBPos, color: .neutral)

        let wireA = wire(name: wireSourceToBreakerName, from: sourcePos, to: breakerPos, color: .neutral)
        let wireB = wire(name: wireBreakerToJunctionName, from: breakerPos, to: junctionPos, color: .neutral)
        let wireC = wire(name: wireJunctionToLoadAName, from: junctionPos, to: loadAPos, color: .neutral)
        let wireD = wire(name: wireJunctionToLoadBName, from: junctionPos, to: loadBPos, color: .neutral)

        for entity in [source, wireA, breaker, wireB, junction, wireC, loadA, wireD, loadB] {
            root.addChild(entity)
        }
        return root
    }

    private struct NodeColor {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat

        static let neutral = NodeColor(red: 0.35, green: 0.38, blue: 0.42)
        static let energized = NodeColor(red: 0.15, green: 0.55, blue: 0.85)
        static let warning = NodeColor(red: 0.95, green: 0.72, blue: 0.15)
        static let fault = NodeColor(red: 1.0, green: 0.18, blue: 0.12)

        static func heated(intensity: Float) -> NodeColor {
            .init(red: 0.95, green: 0.65 - 0.45 * CGFloat(intensity), blue: 0.12)
        }
    }

    /// Recolors every node in a circuit row to reflect live state:
    /// - `.none`: normal — source/breaker tint when energized, downstream
    ///   wires/loads heat up toward `referenceVoltage`.
    /// - `.openCircuit`: upstream (source/breaker) goes neutral regardless
    ///   of `energized` — an open leg means nothing gets there.
    /// - `.groundFault`: loads show fault-red instead of the normal heat
    ///   gradient.
    /// - `.shortCircuit`: the wires themselves show fault-red.
    /// - `.warning`: the breaker shows amber instead of its normal tint.
    public static func applyElectricalState(to root: Entity, energized: Bool, voltage: Double, referenceVoltage: Double = 30, fault: CircuitFaultVisual = .none) {
        let intensity = Float(min(max(voltage / max(referenceVoltage, 1e-9), 0), 1))
        let isOpen = fault == .openCircuit
        let sourceColor: NodeColor = (energized && !isOpen) ? .energized : .neutral
        let breakerColor: NodeColor = fault == .warning ? .warning : sourceColor
        let downstreamColor: NodeColor = (energized && !isOpen) ? .heated(intensity: intensity) : .neutral
        let wireColor: NodeColor = fault == .shortCircuit ? .fault : downstreamColor
        let loadColor: NodeColor = fault == .groundFault ? .fault : downstreamColor

        recolor(root, sourceName, sourceColor)
        recolor(root, breakerName, breakerColor)
        recolor(root, junctionName, downstreamColor)
        recolor(root, loadAName, loadColor)
        recolor(root, loadBName, loadColor)
        for name in [wireSourceToBreakerName, wireBreakerToJunctionName, wireJunctionToLoadAName, wireJunctionToLoadBName] {
            recolor(root, name, wireColor)
        }
    }

    private static func recolor(_ root: Entity, _ name: String, _ color: NodeColor) {
        guard let entity = root.findEntity(named: name) as? ModelEntity else { return }
        var material = SimpleMaterial()
        material.color = .init(tint: .init(red: color.red, green: color.green, blue: color.blue, alpha: 1))
        material.roughness = .float(0.4)
        material.metallic = .float(0.2)
        entity.model?.materials = [material]
    }
}

/// Spherical-coordinate camera pose, owned by the caller (not RealityScene)
/// so it survives the RealityKit view's own teardown/recreation — e.g. a
/// SwiftUI `.sheet` presenting this view tears down its content on dismiss,
/// but a `@State` the parent holds and passes in via `camera:` does not.
public struct RealitySceneCameraState: Sendable, Equatable {
    public var azimuth: Double
    public var elevation: Double
    public var distance: Double

    public init(azimuth: Double = .pi / 4, elevation: Double = 0.35, distance: Double = 1.6) {
        self.azimuth = azimuth
        self.elevation = elevation
        self.distance = distance
    }

    fileprivate var position: SIMD3<Float> {
        let clampedElevation = min(max(elevation, -1.4), 1.4)
        let clampedDistance = min(max(distance, 0.5), 4.0)
        return SIMD3<Float>(
            Float(clampedDistance * cos(clampedElevation) * sin(azimuth)),
            Float(clampedDistance * sin(clampedElevation)),
            Float(clampedDistance * cos(clampedElevation) * cos(azimuth))
        )
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
    public var fault: CircuitFaultVisual
    @Binding public var camera: RealitySceneCameraState

    @State private var selectedNodeName: String?
    @State private var dragBase: RealitySceneCameraState?
    @State private var zoomBase: RealitySceneCameraState?

    public init(energized: Bool = false, voltage: Double = 0, referenceVoltage: Double = 30, fault: CircuitFaultVisual = .none, camera: Binding<RealitySceneCameraState>) {
        self.energized = energized
        self.voltage = voltage
        self.referenceVoltage = referenceVoltage
        self.fault = fault
        self._camera = camera
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            RealityView { content in
                let row = RealitySceneContent.buildCircuitRow()
                RealitySceneContent.applyElectricalState(to: row, energized: energized, voltage: voltage, referenceVoltage: referenceVoltage, fault: fault)
                content.add(row)

                let cameraEntity = PerspectiveCamera()
                cameraEntity.name = "Camera"
                cameraEntity.look(at: .zero, from: camera.position, relativeTo: nil)
                content.add(cameraEntity)

                var pointLight = PointLightComponent()
                pointLight.intensity = 2000
                let light = Entity()
                light.components.set(pointLight)
                light.position = [0, 0.5, 0.5]
                content.add(light)
            } update: { content in
                guard let row = content.entities.first(where: { $0.name == "CircuitRow" }) else { return }
                RealitySceneContent.applyElectricalState(to: row, energized: energized, voltage: voltage, referenceVoltage: referenceVoltage, fault: fault)
                if let cameraEntity = content.entities.first(where: { $0.name == "Camera" }) {
                    cameraEntity.look(at: .zero, from: camera.position, relativeTo: nil)
                }
            }
            .gesture(tapGesture)
            .simultaneousGesture(dragGesture)
            .simultaneousGesture(zoomGesture)
            .accessibilityIdentifier("realityScene.root")

            if let selectedNodeName {
                inspector(for: selectedNodeName)
            }
        }
    }

    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                selectedNodeName = value.entity.name
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            }
    }

    /// One-finger drag orbits the camera: horizontal motion changes azimuth,
    /// vertical motion changes elevation, relative to wherever the drag
    /// started (not an absolute mapping), so short repeated drags compose
    /// naturally instead of jumping.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let base = dragBase ?? camera
                if dragBase == nil { dragBase = camera }
                camera.azimuth = base.azimuth - Double(value.translation.width) * 0.01
                camera.elevation = min(1.4, max(-1.4, base.elevation + Double(value.translation.height) * 0.01))
            }
            .onEnded { _ in dragBase = nil }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let base = zoomBase ?? camera
                if zoomBase == nil { zoomBase = camera }
                camera.distance = min(4.0, max(0.5, base.distance / Double(value)))
            }
            .onEnded { _ in zoomBase = nil }
    }

    @ViewBuilder
    private func inspector(for nodeName: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(RealitySceneContent.displayName(for: nodeName))
                .font(.system(size: 13, weight: .bold, design: .rounded))
            if nodeName == RealitySceneContent.sourceName || nodeName == RealitySceneContent.breakerName {
                Text(energized && fault != .openCircuit ? "Energized" : "De-energized")
                    .font(.system(size: 11, design: .monospaced))
            } else {
                Text(String(format: "%.2f V", voltage))
                    .font(.system(size: 11, design: .monospaced))
            }
            if fault != .none {
                Text("FAULT: \(faultLabel)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.red)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
        .padding(12)
        .accessibilityIdentifier("realityScene.inspector")
    }

    private var faultLabel: String {
        switch fault {
        case .none: return ""
        case .openCircuit: return "OPEN CIRCUIT"
        case .groundFault: return "GROUND FAULT"
        case .shortCircuit: return "SHORT CIRCUIT"
        case .warning: return "WARNING"
        }
    }
}
#endif
