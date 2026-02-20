//
//  NotchDropApp.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import SwiftUI

@main
struct NotchDropApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
