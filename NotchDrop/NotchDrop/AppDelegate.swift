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

        // Temporary: set a placeholder view
        let placeholderView = ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.95))
            Text("NotchDrop")
                .foregroundColor(.white)
                .font(.headline)
        }
        notchWindowController?.setContent(placeholderView)

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

        NSLog("NotchDrop launched successfully")
    }

    @objc func openSettings() {
        NSLog("Settings clicked")
    }
}
