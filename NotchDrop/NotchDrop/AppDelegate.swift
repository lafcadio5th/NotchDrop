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

        NSLog("NotchDrop launched successfully")
    }

    @objc func openSettings() {
        NSLog("Settings clicked")
    }
}
