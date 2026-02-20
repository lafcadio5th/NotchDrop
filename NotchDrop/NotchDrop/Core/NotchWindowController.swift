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
        // Create non-activating panel -- critical: doesn't steal focus
        let panel = NSPanel(
            contentRect: notchInfo.notchRect,
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

        // Start invisible (notch handles its own appearance)
        panel.alphaValue = 0

        self.panel = panel
        panel.orderFront(nil)
    }

    func expand() {
        guard !isExpanded, let panel = panel else { return }
        isExpanded = true

        let screenMidX = notchInfo.screenFrame.midX
        let newX = screenMidX - expandedWidth / 2
        let newY = notchInfo.screenFrame.maxY - expandedHeight

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(
                NSRect(x: newX, y: newY, width: expandedWidth, height: expandedHeight),
                display: true
            )
            panel.animator().alphaValue = 1
        }
    }

    func collapse() {
        // Don't collapse while a drag is hovering over the panel
        guard !isDragHovering else { return }
        guard isExpanded, let panel = panel else { return }
        isExpanded = false

        DragState.shared.isDragActive = false

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(notchInfo.notchRect, display: true)
            panel.animator().alphaValue = 0
        }
    }

    func setContent(_ view: some View) {
        // Create the DropTargetView as a container that sits behind
        // the SwiftUI hosting view, intercepting drag events.
        let hostingView = NSHostingView(rootView: view)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let dropView = DropTargetView(frame: .zero)
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
        panel?.contentView = dropView
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
