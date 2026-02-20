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

    // Collapsed = original notch size, Expanded = scaled up
    private let expandedWidth: CGFloat = 320
    private let expandedHeight: CGFloat = 340
    private(set) var isExpanded = false

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
        guard isExpanded, let panel = panel else { return }
        isExpanded = false

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(notchInfo.notchRect, display: true)
            panel.animator().alphaValue = 0
        }
    }

    func setContent(_ view: some View) {
        panel?.contentView = NSHostingView(rootView: view)
    }

    var panelFrame: NSRect {
        panel?.frame ?? .zero
    }
}
