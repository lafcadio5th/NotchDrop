//
//  NotchWindowController.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import AppKit
import SwiftUI

class NotchWindowController {
    private var panel: NSPanel?
    private let notchInfo: NotchInfo
    private var dropTargetView: DropTargetView?

    // Metal animation layer
    private var metalAnimationView: MetalAnimationView?
    private var contentHostingView: NSHostingView<AnyView>?

    // Collapsed = original notch size, Expanded = scaled up
    private let expandedWidth: CGFloat = 320
    private let expandedHeight: CGFloat = 340
    private(set) var isExpanded = false

    /// When true, the panel stays expanded because a drag is hovering
    /// over it, even if the mouse cursor has left the hover zone.
    private(set) var isDragHovering = false

    init(notchInfo: NotchInfo) {
        self.notchInfo = notchInfo
        setupPanel()
    }

    private func setupPanel() {
        // The panel is always at expanded size. The Metal shader
        // controls the visible shape via a signed-distance function,
        // starting as the notch shape and animating to the full panel.
        let screenMidX = notchInfo.screenFrame.midX
        let panelX = screenMidX - expandedWidth / 2
        let panelY = notchInfo.screenFrame.maxY - expandedHeight

        let panelFrame = NSRect(
            x: panelX,
            y: panelY,
            width: expandedWidth,
            height: expandedHeight
        )

        // Create non-activating panel -- critical: doesn't steal focus
        let panel = NSPanel(
            contentRect: panelFrame,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.level = .statusBar + 1  // Above menu bar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovable = false
        panel.hidesOnDeactivate = false

        // Panel is always visible at full size; Metal shader controls
        // what is rendered.
        panel.alphaValue = 1

        // Start ignoring mouse events so the collapsed panel does not
        // block clicks on the menu bar or other windows.
        panel.ignoresMouseEvents = true

        self.panel = panel

        // Set up the Metal animation view as the background layer
        setupMetalBackground(in: panel, frame: panelFrame)

        panel.orderFront(nil)
    }

    private func setupMetalBackground(in panel: NSPanel, frame: NSRect) {
        let containerView = NSView(frame: NSRect(origin: .zero, size: frame.size))
        containerView.wantsLayer = true
        containerView.autoresizingMask = [.width, .height]

        // Metal animation view fills the entire panel
        let metalView = MetalAnimationView(frame: NSRect(origin: .zero, size: frame.size))
        metalView.autoresizingMask = [.width, .height]
        metalView.notchWidth = Float(notchInfo.notchRect.width)
        metalView.notchHeight = Float(notchInfo.notchRect.height)
        metalView.expandedWidth = Float(expandedWidth)
        metalView.expandedHeight = Float(expandedHeight)
        metalView.cornerRadius = 20

        // Start in collapsed state
        metalView.progress = 0
        metalView.targetProgress = 0

        // When the collapse animation finishes, stop intercepting mouse
        // events so the panel does not block the menu bar or other windows.
        metalView.onCollapseComplete = { [weak self] in
            self?.panel?.ignoresMouseEvents = true
        }

        self.metalAnimationView = metalView
        containerView.addSubview(metalView)

        panel.contentView = containerView
    }

    func expand() {
        guard !isExpanded else { return }
        isExpanded = true

        // Allow mouse events so the user can interact with the panel
        panel?.ignoresMouseEvents = false

        // Drive the Metal shader to expand
        metalAnimationView?.expand()

        // Fade in the SwiftUI content with a slight delay so the
        // liquid shape is visible first
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.contentHostingView?.animator().alphaValue = 1
        }
    }

    func collapse() {
        // Don't collapse while a drag is hovering over the panel
        guard !isDragHovering else { return }
        guard isExpanded else { return }
        isExpanded = false

        DragState.shared.isDragActive = false

        // Fade out the SwiftUI content first
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.contentHostingView?.animator().alphaValue = 0
        }

        // Drive the Metal shader to collapse
        metalAnimationView?.collapse()
    }

    func setContent(_ view: some View) {
        guard let panel = panel,
              let containerView = panel.contentView else { return }

        // Create the DropTargetView as a container that sits on top of
        // the Metal background, intercepting drag events.
        let hostingView = NSHostingView(rootView: AnyView(view))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        // Start transparent; expand() fades it in
        hostingView.alphaValue = 0
        self.contentHostingView = hostingView

        let dropView = DropTargetView(frame: NSRect(origin: .zero, size: containerView.bounds.size))
        dropView.translatesAutoresizingMaskIntoConstraints = false
        dropView.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: dropView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: dropView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: dropView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: dropView.bottomAnchor),
        ])

        dropView.onDragEntered = { [weak self] in
            self?.handleDragEntered()
        }

        dropView.onDragExited = { [weak self] in
            self?.handleDragExited()
        }

        dropView.onFilesDropped = { [weak self] urls in
            self?.handleFilesDrop(urls)
        }

        self.dropTargetView = dropView

        // Add the drop/content view on top of the Metal view
        containerView.addSubview(dropView)

        NSLayoutConstraint.activate([
            dropView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            dropView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            dropView.topAnchor.constraint(equalTo: containerView.topAnchor),
            dropView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    var panelFrame: NSRect {
        panel?.frame ?? .zero
    }

    // MARK: - Drag Handling

    private func handleDragEntered() {
        isDragHovering = true
        DragState.shared.isDragActive = true

        if !isExpanded {
            expand()
        }
    }

    private func handleDragExited() {
        isDragHovering = false
        DragState.shared.isDragActive = false

        // Collapse after a brief delay to avoid flickering if the
        // user drags back in quickly.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, !self.isDragHovering else { return }
            self.collapse()
        }
    }

    private func handleFilesDrop(_ urls: [URL]) {
        isDragHovering = false
        DragState.shared.isDragActive = false

        for url in urls {
            _ = FileShelfManager.shared.addFile(from: url)
        }

        NSLog("Dropped \(urls.count) file(s) onto NotchDrop")

        // Keep panel expanded briefly so the user sees the result,
        // then collapse.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.collapse()
        }
    }
}
