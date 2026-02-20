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

        // For testing: expand after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.notchWindowController?.expand()
        }

        NSLog("NotchDrop launched successfully")
    }

    @objc func openSettings() {
        NSLog("Settings clicked")
    }
}
