#if canImport(MetalKit) && canImport(SwiftUI)
import MetalKit
import SwiftUI

/// Fixed-capacity, oldest-first sample ring for scrolling telemetry traces.
/// Value: struct, no shared mutable reference state.
public struct TelemetryRingBuffer: Sendable {
    public private(set) var values: [Float]
    public let capacity: Int

    public init(capacity: Int, fill: Float = 0) {
        self.capacity = max(capacity, 2)
        self.values = Array(repeating: fill, count: self.capacity)
    }

    public mutating func append(_ value: Float) {
        values.removeFirst()
        values.append(value)
    }
}

private let telemetryShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut telemetry_vertex(constant float2 *vertices [[buffer(0)]], uint vid [[vertex_id]]) {
    VertexOut out;
    out.position = float4(vertices[vid], 0.0, 1.0);
    return out;
}

fragment float4 telemetry_fragment(constant float4 &color [[buffer(0)]]) {
    return color;
}
"""

/// One scrolling channel: normalized samples (-1...1, oldest first) plus the
/// color it draws in.
public struct TelemetryTrace: Sendable {
    public var samples: [Float]
    public var color: SIMD4<Float>

    public init(samples: [Float], color: SIMD4<Float>) {
        self.samples = samples
        self.color = color
    }
}

/// Minimal Metal render pipeline for one or more scrolling telemetry
/// channels drawn into the same view (e.g. CH1 voltage, CH2 current). All
/// GPU state lives here; the shader is compiled from an embedded MSL source
/// string so no .metal build-phase wiring is required.
@MainActor
public final class TelemetryWaveformRenderer: NSObject, MTKViewDelegate {
    public let device: MTLDevice
    public var traces: [TelemetryTrace] = []
    public var showGrid = true
    public var gridColor: SIMD4<Float> = [1, 1, 1, 0.08]
    public var gridDivisions: (horizontal: Int, vertical: Int) = (8, 4)

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState

    public init?(device: MTLDevice) {
        guard
            let commandQueue = device.makeCommandQueue(),
            let library = try? device.makeLibrary(source: telemetryShaderSource, options: nil),
            let vertexFunction = library.makeFunction(name: "telemetry_vertex"),
            let fragmentFunction = library.makeFunction(name: "telemetry_fragment")
        else { return nil }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }

        self.device = device
        self.commandQueue = commandQueue
        self.pipelineState = pipelineState
        super.init()
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    public func draw(in view: MTKView) {
        guard
            let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }

        encoder.setRenderPipelineState(pipelineState)

        if showGrid {
            drawGrid(with: encoder)
        }

        for trace in traces where trace.samples.count > 1 {
            let count = trace.samples.count
            var vertices = [Float](repeating: 0, count: count * 2)
            for i in 0..<count {
                vertices[i * 2] = Float(i) / Float(count - 1) * 2 - 1
                vertices[i * 2 + 1] = trace.samples[i]
            }

            guard let vertexBuffer = device.makeBuffer(
                bytes: vertices,
                length: vertices.count * MemoryLayout<Float>.stride,
                options: [.storageModeShared]
            ) else { continue }

            var color = trace.color
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
            encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: count)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    /// Draws a scope-style reticle as disconnected line segments (a `.line`
    /// primitive list, not the traces' `.lineStrip`).
    private func drawGrid(with encoder: MTLRenderCommandEncoder) {
        var vertices: [Float] = []
        let (h, v) = gridDivisions

        for i in 0...h {
            let x = Float(i) / Float(h) * 2 - 1
            vertices.append(contentsOf: [x, -1, x, 1])
        }
        for i in 0...v {
            let y = Float(i) / Float(v) * 2 - 1
            vertices.append(contentsOf: [-1, y, 1, y])
        }

        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<Float>.stride,
            options: [.storageModeShared]
        ) else { return }

        var color = gridColor
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertices.count / 2)
    }
}

#if canImport(UIKit)
import UIKit

/// SwiftUI host for one or more live Metal-rendered telemetry traces
/// (voltage/current scrolling graph). Normalized samples are expected in
/// -1...1.
@available(iOS 18.0, *)
public struct TelemetryWaveformView: UIViewRepresentable {
    public var traces: [TelemetryTrace]

    public init(traces: [TelemetryTrace]) {
        self.traces = traces
    }

    public init(samples: [Float], lineColor: SIMD4<Float> = [0.2, 0.85, 1.0, 1.0]) {
        self.traces = [TelemetryTrace(samples: samples, color: lineColor)]
    }

    public final class Coordinator {
        var renderer: TelemetryWaveformRenderer?
    }

    public func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        if let device = MTLCreateSystemDefaultDevice() {
            coordinator.renderer = TelemetryWaveformRenderer(device: device)
        }
        return coordinator
    }

    public func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.renderer?.device)
        view.delegate = context.coordinator.renderer
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.preferredFramesPerSecond = 30
        view.framebufferOnly = true
        view.isOpaque = false
        view.backgroundColor = .clear
        return view
    }

    public func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer?.traces = traces
    }
}
#endif
#endif
