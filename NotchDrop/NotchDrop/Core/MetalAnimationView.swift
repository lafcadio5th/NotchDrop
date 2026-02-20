//
//  MetalAnimationView.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import AppKit
import MetalKit

/// A uniform buffer matching the layout in LiquidShader.metal.
struct LiquidUniforms {
    var progress: Float
    var time: Float
    var viewSize: SIMD2<Float>
    var notchSize: SIMD2<Float>
    var expandedSize: SIMD2<Float>
    var cornerRadius: Float
}

/// An NSView that uses Metal (via MTKView) to render a liquid-metal
/// expand/collapse animation driven by a signed-distance-function shader.
///
/// The view renders a full-screen quad and uses the fragment shader to
/// draw an organically animated rounded-rectangle shape that morphs
/// between notch size and expanded panel size.
///
/// Usage:
/// ```swift
/// metalView.expand()   // animate to expanded state
/// metalView.collapse() // animate back to notch state
/// ```
class MetalAnimationView: NSView, MTKViewDelegate {

    private var metalView: MTKView!
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!

    // Animation state
    var progress: Float = 0.0      // 0 = collapsed, 1 = expanded
    var targetProgress: Float = 0.0
    private var animationSpeed: Float = 4.0  // Controls animation speed

    /// Called when the Metal animation finishes expanding (progress reaches 1).
    var onExpandComplete: (() -> Void)?

    /// Called when the Metal animation finishes collapsing (progress reaches 0).
    var onCollapseComplete: (() -> Void)?

    // Shape parameters passed to shader
    var notchWidth: Float = 180
    var notchHeight: Float = 38
    var expandedWidth: Float = 320
    var expandedHeight: Float = 340
    var cornerRadius: Float = 20

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupMetal()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMetal()
    }

    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            NSLog("MetalAnimationView: Metal is not supported on this device")
            return
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()

        let mtkView = MTKView(frame: bounds, device: device)
        mtkView.delegate = self
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.layer?.isOpaque = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.autoresizingMask = [.width, .height]
        // Start paused -- we only render during animations
        mtkView.isPaused = true
        addSubview(mtkView)
        self.metalView = mtkView

        setupPipeline()
    }

    private func setupPipeline() {
        guard let device = device,
              let library = device.makeDefaultLibrary() else {
            NSLog("MetalAnimationView: Failed to create Metal library")
            return
        }

        guard let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "liquidFragment") else {
            NSLog("MetalAnimationView: Failed to find shader functions")
            return
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

        // Enable alpha blending for transparent background
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            NSLog("MetalAnimationView: Failed to create pipeline state: \(error)")
        }
    }

    // MARK: - Public API

    /// Animate from collapsed (notch) to expanded (panel).
    func expand() {
        targetProgress = 1.0
        metalView?.isPaused = false
    }

    /// Animate from expanded (panel) to collapsed (notch).
    func collapse() {
        targetProgress = 0.0
        metalView?.isPaused = false
    }

    /// Immediately set the progress without animation.
    func setProgress(_ value: Float) {
        progress = value
        targetProgress = value
        metalView?.isPaused = false
        // Draw one frame then pause
        metalView?.draw()
    }

    // MARK: - MTKViewDelegate

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // No-op: the shader reads size from uniforms
    }

    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated {
            self.performDraw(in: view)
        }
    }

    private func performDraw(in view: MTKView) {
        // Animate progress toward target with spring-like easing
        let diff = targetProgress - progress
        if abs(diff) < 0.001 {
            progress = targetProgress
            if targetProgress == 0 {
                view.isPaused = true
                onCollapseComplete?()
            } else if targetProgress == 1 {
                view.isPaused = true
                onExpandComplete?()
            }
        } else {
            // Smooth interpolation toward target
            progress += diff * animationSpeed * Float(1.0 / 60.0) * 4.0
        }

        guard let pipelineState = pipelineState,
              let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)

        // Pass uniforms to shader
        var uniforms = LiquidUniforms(
            progress: progress,
            time: Float(CACurrentMediaTime()),
            viewSize: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            notchSize: SIMD2<Float>(notchWidth, notchHeight),
            expandedSize: SIMD2<Float>(expandedWidth, expandedHeight),
            cornerRadius: cornerRadius
        )
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<LiquidUniforms>.size, index: 0)

        // Draw full-screen quad (triangle strip, 4 vertices)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
