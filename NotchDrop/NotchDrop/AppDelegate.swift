//
//  AppDelegate.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var notchWindowController: NotchWindowController?
    private var hoverMonitor: HoverMonitor?
    private var dragMonitor: DragMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create a minimal menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: "NotchDrop")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit NotchDrop", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu

        // Detect notch and set up overlay window
        let notchInfo = NotchDetector.detect()
        NSLog("Notch detected: \(notchInfo.hasNotch), rect: \(notchInfo.notchRect)")

        notchWindowController = NotchWindowController(notchInfo: notchInfo)

        // Set the main expanded UI as the panel content
        notchWindowController?.setContent(NotchExpandedView())

        // Set up hover monitoring for expand/collapse
        hoverMonitor = HoverMonitor(
            notchInfo: notchInfo,
            expandedFrameProvider: { [weak self] in
                self?.notchWindowController?.panelFrame ?? .zero
            },
            onHoverEnter: { [weak self] in
                self?.notchWindowController?.expand()
            },
            onHoverExit: { [weak self] in
                self?.notchWindowController?.collapse()
            }
        )
        hoverMonitor?.start()

        // Set up drag monitoring for file drops
        // The DragMonitor provides a supplementary signal: when a
        // system-wide file drag is detected, it expands the panel so
        // the DropTargetView can receive the drag. The primary drag
        // handling happens through DropTargetView's NSDraggingDestination.
        dragMonitor = DragMonitor(
            onDragBegan: { [weak self] in
                self?.notchWindowController?.expand()
                DragState.shared.isDragActive = true
            },
            onDragEnded: { [weak self] in
                guard let self else { return }
                DragState.shared.isDragActive = false
                // Only collapse if the drag is not hovering over
                // the panel (DropTargetView manages that state).
                if !(self.notchWindowController?.isDragHovering ?? false) {
                    self.notchWindowController?.collapse()
                }
            }
        )
        dragMonitor?.start()

        NSLog("NotchDrop launched successfully")
    }

    @objc func openSettings() {
        NSLog("Settings clicked")
        // Open the SwiftUI Settings scene window
        NSApp.activate()
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
