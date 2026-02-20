//
//  HoverMonitor.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import AppKit

class HoverMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let notchInfo: NotchInfo
    private let onHoverEnter: () -> Void
    private let onHoverExit: () -> Void
    private let expandedFrameProvider: () -> NSRect

    private var isHovering = false
    private let hoverZonePadding: CGFloat = 20

    init(
        notchInfo: NotchInfo,
        expandedFrameProvider: @escaping () -> NSRect,
        onHoverEnter: @escaping () -> Void,
        onHoverExit: @escaping () -> Void
    ) {
        self.notchInfo = notchInfo
        self.expandedFrameProvider = expandedFrameProvider
        self.onHoverEnter = onHoverEnter
        self.onHoverExit = onHoverExit
    }

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.handleMouseMove()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMove()
            return event
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleMouseMove() {
        let mouseLocation = NSEvent.mouseLocation

        let triggerRect: NSRect
        if isHovering {
            // When expanded, use the expanded panel frame + padding
            triggerRect = expandedFrameProvider().insetBy(dx: -hoverZonePadding, dy: -hoverZonePadding)
        } else {
            // When collapsed, use the notch area + padding
            triggerRect = notchInfo.notchRect.insetBy(dx: -hoverZonePadding, dy: -hoverZonePadding)
        }

        let isInZone = triggerRect.contains(mouseLocation)

        if isInZone && !isHovering {
            isHovering = true
            onHoverEnter()
        } else if !isInZone && isHovering {
            isHovering = false
            onHoverExit()
        }
    }

    deinit {
        stop()
    }
}
