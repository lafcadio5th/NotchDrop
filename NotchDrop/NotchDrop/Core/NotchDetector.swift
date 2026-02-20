//
//  NotchDetector.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import AppKit

struct NotchInfo: Sendable {
    let screenFrame: NSRect      // Full screen frame
    let notchRect: NSRect        // Notch area in screen coordinates
    let hasNotch: Bool
}

class NotchDetector {
    static func detect() -> NotchInfo {
        guard let screen = NSScreen.main else {
            return NotchInfo(screenFrame: .zero, notchRect: .zero, hasNotch: false)
        }

        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame

        // On Notch MacBooks, the menu bar area above visibleFrame is taller (38pt vs 25pt)
        // The notch is approximately 180pt wide, centered at top
        let menuBarHeight = screenFrame.height - visibleFrame.height - visibleFrame.origin.y
        let hasNotch = menuBarHeight > 30 // Notch MacBooks have ~38pt menu bar

        let notchWidth: CGFloat = 180
        let notchHeight: CGFloat = hasNotch ? menuBarHeight : 25
        let notchX = screenFrame.midX - notchWidth / 2
        let notchY = screenFrame.maxY - notchHeight

        let notchRect = NSRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)

        return NotchInfo(
            screenFrame: screenFrame,
            notchRect: notchRect,
            hasNotch: hasNotch
        )
    }
}
