# NotchDrop V1 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a macOS Notch-based quick-capture app (Todo + Note + File Shelf + AI Assistant) with Metal shader animations and Freemium monetization.

**Architecture:** macOS app using SwiftUI for UI + AppKit for window management + Metal for animations. Data stored locally in SQLite via GRDB. Non-activating NSPanel overlays the Notch area. AI integration via BYOK (user's own API keys) stored in Keychain.

**Tech Stack:** Swift 5, SwiftUI, AppKit, Metal, GRDB (SQLite), StoreKit 2, URLSession (AI APIs), Keychain Services

**Design Reference:** `docs/plans/2025-02-20-notchdrop-product-design.md`
**UI Mockup:** `docs/mockups/notchdrop-v1-mockup.html`

---

## Phase 1: Project Skeleton & Notch Window (Foundation)

### Task 1: Create Xcode Project

**Files:**
- Create: `NotchDrop.xcodeproj` (via Xcode)
- Create: `NotchDrop/NotchDropApp.swift`
- Create: `NotchDrop/AppDelegate.swift`
- Create: `NotchDrop/Info.plist`

**Step 1: Create new macOS App project in Xcode**

- Open Xcode → New Project → macOS → App
- Product Name: `NotchDrop`
- Team: Your Apple Developer account
- Organization Identifier: your bundle ID prefix
- Interface: SwiftUI
- Language: Swift
- Uncheck: Include Tests (we'll add manually)
- Save to: `/Users/kelvintan/Desktop/Claude Sandbox/NotchDrop/`

**Step 2: Configure project settings**

- Deployment Target: macOS 14.0 (Sonoma) — Notch exists on M1+ MacBooks
- App Sandbox: ON (for App Store)
- Signing: Automatic, your team
- Add capability: App Sandbox
- In Info.plist: Set `LSUIElement = YES` (menu bar app, no Dock icon)

**Step 3: Replace SwiftUI App entry with AppDelegate lifecycle**

```swift
// NotchDropApp.swift
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
```

```swift
// AppDelegate.swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create a minimal menu bar icon (gear icon for settings)
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
        // TODO: Open settings window
        NSLog("Settings clicked")
    }
}
```

**Step 4: Build and run**

Run: `⌘+R` in Xcode
Expected: App launches with a menu bar icon (tray icon), no Dock icon, no main window. Clicking icon shows menu with "Settings..." and "Quit".

**Step 5: Initialize git and commit**

```bash
cd "/Users/kelvintan/Desktop/Claude Sandbox/NotchDrop"
git init
echo ".DS_Store\n*.xcuserstate\nbuild/\nDerivedData/\n*.xcworkspace/xcuserdata/" > .gitignore
git add .
git commit -m "feat: initial Xcode project setup with menu bar app lifecycle"
```

---

### Task 2: Notch Detection & Overlay Window

**Files:**
- Create: `NotchDrop/Core/NotchDetector.swift`
- Create: `NotchDrop/Core/NotchWindowController.swift`
- Modify: `NotchDrop/AppDelegate.swift`

**Step 1: Create NotchDetector**

```swift
// NotchDrop/Core/NotchDetector.swift
import AppKit

struct NotchInfo {
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
```

**Step 2: Create NotchWindowController with non-activating panel**

```swift
// NotchDrop/Core/NotchWindowController.swift
import AppKit
import SwiftUI

class NotchWindowController {
    private var panel: NSPanel?
    private let notchInfo: NotchInfo

    // Collapsed = original notch size, Expanded = scaled up
    private let expandedWidth: CGFloat = 320
    private let expandedHeight: CGFloat = 340
    private var isExpanded = false

    init(notchInfo: NotchInfo) {
        self.notchInfo = notchInfo
        setupPanel()
    }

    private func setupPanel() {
        // Create non-activating panel — critical: doesn't steal focus
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

    var expanded: Bool { isExpanded }
}
```

**Step 3: Wire up in AppDelegate**

Add to `AppDelegate.swift`:

```swift
// Add properties
private var notchWindowController: NotchWindowController?

// In applicationDidFinishLaunching, add:
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
```

**Step 4: Build and run**

Run: `⌘+R`
Expected: App launches, after 2 seconds a dark rounded rectangle appears at the Notch position expanding from the notch area. Text "NotchDrop" visible.

**Step 5: Commit**

```bash
git add NotchDrop/Core/
git add NotchDrop/AppDelegate.swift
git commit -m "feat: notch detection and non-activating overlay panel"
```

---

### Task 3: Hover Monitor (expand/collapse on mouse hover)

**Files:**
- Create: `NotchDrop/Core/HoverMonitor.swift`
- Modify: `NotchDrop/AppDelegate.swift`

**Step 1: Create HoverMonitor**

```swift
// NotchDrop/Core/HoverMonitor.swift
import AppKit

class HoverMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let notchDetector: NotchInfo
    private let onHoverEnter: () -> Void
    private let onHoverExit: () -> Void
    private let expandedFrameProvider: () -> NSRect

    private var isHovering = false
    private let hoverZonePadding: CGFloat = 20 // Extra area around notch to trigger

    init(
        notchInfo: NotchInfo,
        expandedFrameProvider: @escaping () -> NSRect,
        onHoverEnter: @escaping () -> Void,
        onHoverExit: @escaping () -> Void
    ) {
        self.notchDetector = notchInfo
        self.expandedFrameProvider = expandedFrameProvider
        self.onHoverEnter = onHoverEnter
        self.onHoverExit = onHoverExit
    }

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMove(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMove(event)
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

    private func handleMouseMove(_ event: NSEvent) {
        let mouseLocation = NSEvent.mouseLocation

        // Check if mouse is in the trigger zone
        let triggerRect: NSRect
        if isHovering {
            // When expanded, use the expanded panel frame + padding
            triggerRect = expandedFrameProvider().insetBy(dx: -hoverZonePadding, dy: -hoverZonePadding)
        } else {
            // When collapsed, use the notch area + padding
            triggerRect = notchDetector.notchRect.insetBy(dx: -hoverZonePadding, dy: -hoverZonePadding)
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
```

**Step 2: Wire up in AppDelegate**

Replace the temporary expand code with HoverMonitor:

```swift
// Add property
private var hoverMonitor: HoverMonitor?

// In applicationDidFinishLaunching, replace the DispatchQueue test code with:
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
```

**Step 3: Build and run**

Run: `⌘+R`
Expected: Moving mouse to the Notch area causes the panel to expand. Moving mouse away collapses it. No focus stealing from current app.

**Step 4: Commit**

```bash
git add NotchDrop/Core/HoverMonitor.swift NotchDrop/AppDelegate.swift
git commit -m "feat: hover monitor for notch expand/collapse"
```

---

## Phase 2: Data Layer

### Task 4: Add GRDB dependency and Database setup

**Files:**
- Modify: `NotchDrop.xcodeproj` (add SPM dependency)
- Create: `NotchDrop/Data/DatabaseManager.swift`
- Create: `NotchDrop/Data/Models/TodoItem.swift`
- Create: `NotchDrop/Data/Models/NoteItem.swift`
- Create: `NotchDrop/Data/Models/FileItem.swift`

**Step 1: Add GRDB via Swift Package Manager**

In Xcode: File → Add Package Dependencies
- URL: `https://github.com/groue/GRDB.swift`
- Version: Up to Next Major (latest 6.x)

**Step 2: Create data models**

```swift
// NotchDrop/Data/Models/TodoItem.swift
import Foundation
import GRDB

struct TodoItem: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var content: String
    var isDone: Bool
    var createdAt: Date
    var updatedAt: Date

    static let databaseTableName = "todos"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
```

```swift
// NotchDrop/Data/Models/NoteItem.swift
import Foundation
import GRDB

struct NoteItem: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var content: String
    var createdAt: Date
    var updatedAt: Date

    static let databaseTableName = "notes"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
```

```swift
// NotchDrop/Data/Models/FileItem.swift
import Foundation
import GRDB

struct FileItem: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var originalName: String
    var storedPath: String
    var fileSize: Int64
    var thumbnailPath: String?
    var createdAt: Date

    static let databaseTableName = "files"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
```

**Step 3: Create DatabaseManager**

```swift
// NotchDrop/Data/DatabaseManager.swift
import Foundation
import GRDB

class DatabaseManager {
    static let shared = DatabaseManager()

    private var dbPool: DatabasePool?

    private init() {
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dbDir = appSupport.appendingPathComponent("NotchDrop", isDirectory: true)
            try FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)

            let dbPath = dbDir.appendingPathComponent("notchdrop.sqlite").path
            dbPool = try DatabasePool(path: dbPath)

            try migrate()
            NSLog("Database initialized at: \(dbPath)")
        } catch {
            NSLog("Database init error: \(error)")
        }
    }

    private func migrate() throws {
        guard let dbPool = dbPool else { return }

        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_tables") { db in
            try db.create(table: "todos") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("content", .text).notNull()
                t.column("isDone", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: "notes") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("content", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: "files") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("originalName", .text).notNull()
                t.column("storedPath", .text).notNull()
                t.column("fileSize", .integer).notNull()
                t.column("thumbnailPath", .text)
                t.column("createdAt", .datetime).notNull()
            }
        }

        try migrator.migrate(dbPool)
    }

    // MARK: - Todos

    func addTodo(_ content: String) throws -> TodoItem {
        guard let dbPool = dbPool else { throw DatabaseError(message: "DB not initialized") }
        return try dbPool.write { db in
            var todo = TodoItem(content: content, isDone: false, createdAt: Date(), updatedAt: Date())
            try todo.insert(db)
            return todo
        }
    }

    func fetchActiveTodos() throws -> [TodoItem] {
        guard let dbPool = dbPool else { return [] }
        return try dbPool.read { db in
            try TodoItem
                .filter(Column("isDone") == false)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }

    func fetchAllTodos() throws -> [TodoItem] {
        guard let dbPool = dbPool else { return [] }
        return try dbPool.read { db in
            try TodoItem.order(Column("createdAt").desc).fetchAll(db)
        }
    }

    func toggleTodo(_ id: Int64) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            if var todo = try TodoItem.fetchOne(db, key: id) {
                todo.isDone.toggle()
                todo.updatedAt = Date()
                try todo.update(db)
            }
        }
    }

    func deleteTodo(_ id: Int64) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            _ = try TodoItem.deleteOne(db, key: id)
        }
    }

    func activeTodoCount() throws -> Int {
        guard let dbPool = dbPool else { return 0 }
        return try dbPool.read { db in
            try TodoItem.filter(Column("isDone") == false).fetchCount(db)
        }
    }

    // MARK: - Notes

    func addNote(_ content: String) throws -> NoteItem {
        guard let dbPool = dbPool else { throw DatabaseError(message: "DB not initialized") }
        return try dbPool.write { db in
            var note = NoteItem(content: content, createdAt: Date(), updatedAt: Date())
            try note.insert(db)
            return note
        }
    }

    func fetchNotes() throws -> [NoteItem] {
        guard let dbPool = dbPool else { return [] }
        return try dbPool.read { db in
            try NoteItem.order(Column("createdAt").desc).fetchAll(db)
        }
    }

    func deleteNote(_ id: Int64) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            _ = try NoteItem.deleteOne(db, key: id)
        }
    }

    func noteCount() throws -> Int {
        guard let dbPool = dbPool else { return 0 }
        return try dbPool.read { db in
            try NoteItem.fetchCount(db)
        }
    }

    // MARK: - Files

    func addFile(originalName: String, storedPath: String, fileSize: Int64, thumbnailPath: String?) throws -> FileItem {
        guard let dbPool = dbPool else { throw DatabaseError(message: "DB not initialized") }
        return try dbPool.write { db in
            var file = FileItem(originalName: originalName, storedPath: storedPath, fileSize: fileSize, thumbnailPath: thumbnailPath, createdAt: Date())
            try file.insert(db)
            return file
        }
    }

    func fetchFiles() throws -> [FileItem] {
        guard let dbPool = dbPool else { return [] }
        return try dbPool.read { db in
            try FileItem.order(Column("createdAt").desc).fetchAll(db)
        }
    }

    func deleteFile(_ id: Int64) throws -> FileItem? {
        guard let dbPool = dbPool else { return nil }
        return try dbPool.write { db in
            let file = try FileItem.fetchOne(db, key: id)
            _ = try FileItem.deleteOne(db, key: id)
            return file
        }
    }

    func fileCount() throws -> Int {
        guard let dbPool = dbPool else { return 0 }
        return try dbPool.read { db in
            try FileItem.fetchCount(db)
        }
    }
}
```

**Step 4: Build and verify**

Run: `⌘+R`
Expected: App launches, console shows "Database initialized at: ..." No crashes.

**Step 5: Commit**

```bash
git add NotchDrop/Data/ NotchDrop.xcodeproj/
git commit -m "feat: GRDB database layer with Todo, Note, File models"
```

---

### Task 5: Feature Managers (Todo, Note, File, Pro quota)

**Files:**
- Create: `NotchDrop/Features/TodoManager.swift`
- Create: `NotchDrop/Features/NoteManager.swift`
- Create: `NotchDrop/Features/FileShelfManager.swift`
- Create: `NotchDrop/Features/ProManager.swift`

**Step 1: Create managers with quota logic**

```swift
// NotchDrop/Features/ProManager.swift
import Foundation

class ProManager: ObservableObject {
    static let shared = ProManager()

    @Published var isPro: Bool = false // StoreKit 2 will update this

    // Free tier limits
    let freeTodoLimit = 10
    let freeNoteLimit = 10
    let freeFileLimit = 15

    func canAddTodo() -> Bool {
        if isPro { return true }
        return (try? DatabaseManager.shared.activeTodoCount()) ?? 0 < freeTodoLimit
    }

    func canAddNote() -> Bool {
        if isPro { return true }
        return (try? DatabaseManager.shared.noteCount()) ?? 0 < freeNoteLimit
    }

    func canAddFile() -> Bool {
        if isPro { return true }
        return (try? DatabaseManager.shared.fileCount()) ?? 0 < freeFileLimit
    }
}
```

```swift
// NotchDrop/Features/TodoManager.swift
import Foundation
import Combine

class TodoManager: ObservableObject {
    static let shared = TodoManager()

    @Published var todos: [TodoItem] = []

    func refresh() {
        todos = (try? DatabaseManager.shared.fetchAllTodos()) ?? []
    }

    func addTodo(_ content: String) -> Bool {
        guard ProManager.shared.canAddTodo() else { return false }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        _ = try? DatabaseManager.shared.addTodo(content)
        refresh()
        return true
    }

    func toggleTodo(_ id: Int64) {
        try? DatabaseManager.shared.toggleTodo(id)
        refresh()
    }

    func deleteTodo(_ id: Int64) {
        try? DatabaseManager.shared.deleteTodo(id)
        refresh()
    }
}
```

```swift
// NotchDrop/Features/NoteManager.swift
import Foundation
import Combine

class NoteManager: ObservableObject {
    static let shared = NoteManager()

    @Published var notes: [NoteItem] = []

    func refresh() {
        notes = (try? DatabaseManager.shared.fetchNotes()) ?? []
    }

    func addNote(_ content: String) -> Bool {
        guard ProManager.shared.canAddNote() else { return false }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        _ = try? DatabaseManager.shared.addNote(content)
        refresh()
        return true
    }

    func deleteNote(_ id: Int64) {
        try? DatabaseManager.shared.deleteNote(id)
        refresh()
    }
}
```

```swift
// NotchDrop/Features/FileShelfManager.swift
import Foundation
import AppKit
import Combine

class FileShelfManager: ObservableObject {
    static let shared = FileShelfManager()

    @Published var files: [FileItem] = []

    private var storageURL: URL {
        // Check user custom path first, fallback to default
        if let custom = UserDefaults.standard.string(forKey: "fileStoragePath") {
            return URL(fileURLWithPath: custom)
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("NotchDrop/files", isDirectory: true)
    }

    func refresh() {
        files = (try? DatabaseManager.shared.fetchFiles()) ?? []
    }

    func addFile(from sourceURL: URL) -> Bool {
        guard ProManager.shared.canAddFile() else { return false }

        do {
            try FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)

            let fileName = sourceURL.lastPathComponent
            let uniqueName = "\(UUID().uuidString)_\(fileName)"
            let destURL = storageURL.appendingPathComponent(uniqueName)

            try FileManager.default.copyItem(at: sourceURL, to: destURL)

            let attrs = try FileManager.default.attributesOfItem(atPath: destURL.path)
            let fileSize = (attrs[.size] as? Int64) ?? 0

            _ = try DatabaseManager.shared.addFile(
                originalName: fileName,
                storedPath: destURL.path,
                fileSize: fileSize,
                thumbnailPath: nil
            )

            refresh()
            return true
        } catch {
            NSLog("File add error: \(error)")
            return false
        }
    }

    func deleteFile(_ id: Int64) {
        if let file = try? DatabaseManager.shared.deleteFile(id) {
            try? FileManager.default.removeItem(atPath: file.storedPath)
        }
        refresh()
    }

    func openFile(_ file: FileItem) {
        NSWorkspace.shared.open(URL(fileURLWithPath: file.storedPath))
    }
}
```

**Step 2: Build**

Run: `⌘+R`
Expected: Compiles without errors.

**Step 3: Commit**

```bash
git add NotchDrop/Features/
git commit -m "feat: Todo, Note, FileShelf, Pro managers with quota logic"
```

---

## Phase 3: Main UI

### Task 6: NotchExpandedView — Main UI with Tabs

**Files:**
- Create: `NotchDrop/Views/NotchExpandedView.swift`
- Create: `NotchDrop/Views/QuickInputView.swift`
- Create: `NotchDrop/Views/TodoListView.swift`
- Create: `NotchDrop/Views/NoteListView.swift`
- Create: `NotchDrop/Views/FileShelfView.swift`
- Modify: `NotchDrop/AppDelegate.swift`

**Step 1: Build each SwiftUI view**

Each view should follow the mockup V1.2 design:
- Dark glassmorphic background (already handled by panel)
- `NotchExpandedView`: Contains input field at top + tab bar + content area
- `QuickInputView`: Text field with Enter=Todo, ⌘+Enter=Note hints
- `TodoListView`: List of todos with checkboxes
- `NoteListView`: List of notes with timestamps
- `FileShelfView`: Grid of file thumbnails

The exact SwiftUI code should match the mockup's dark theme, spacing, and typography.

**Step 2: Wire NotchExpandedView into NotchWindowController**

Replace the placeholder view in AppDelegate with NotchExpandedView.

**Step 3: Build and run**

Expected: Hovering over Notch shows the full UI with input box, tabs, and content area.

**Step 4: Commit**

```bash
git add NotchDrop/Views/
git commit -m "feat: main NotchExpandedView UI with tabs (Todo, Notes, Files)"
```

---

### Task 7: Quick Input Logic (Enter = Todo, ⌘+Enter = Note)

**Files:**
- Modify: `NotchDrop/Views/QuickInputView.swift`

**Step 1: Implement key handling**

The input field needs to intercept Enter and ⌘+Enter:
- `Enter` alone → call `TodoManager.shared.addTodo(text)`, clear input
- `⌘+Enter` → call `NoteManager.shared.addNote(text)`, clear input
- Show limit reached message if add returns false

**Step 2: Build and test manually**

Expected: Type text → Enter saves as Todo (appears in Todo tab). Type text → ⌘+Enter saves as Note (appears in Notes tab).

**Step 3: Commit**

```bash
git add NotchDrop/Views/QuickInputView.swift
git commit -m "feat: quick input with Enter=Todo, Cmd+Enter=Note"
```

---

### Task 8: Drag-to-Notch File Drop

**Files:**
- Create: `NotchDrop/Core/DragMonitor.swift`
- Modify: `NotchDrop/Core/NotchWindowController.swift`
- Modify: `NotchDrop/AppDelegate.swift`

**Step 1: Create DragMonitor**

Monitor system-wide drag events. When a drag session starts, expand the Notch to show the drop zone. Implement `NSDraggingDestination` on the panel to accept file drops.

**Step 2: Handle file drop**

When files are dropped:
- Call `FileShelfManager.shared.addFile(from: fileURL)` for each dropped file
- Show success animation
- Collapse back to notch

**Step 3: Build and test**

Expected: Drag a file from Finder toward the Notch → Notch expands with blue drop zone. Drop file → file appears in Files tab.

**Step 4: Commit**

```bash
git add NotchDrop/Core/DragMonitor.swift
git commit -m "feat: drag-to-notch file drop with sensing"
```

---

## Phase 4: Settings & Monetization

### Task 9: Settings Window

**Files:**
- Create: `NotchDrop/Views/SettingsView.swift`
- Create: `NotchDrop/Core/SettingsWindowController.swift`
- Modify: `NotchDrop/AppDelegate.swift`

**Step 1: Build SettingsView**

Following mockup, sections:
- General: Launch at login, Hover sensitivity
- Storage: File storage path with "Change" button (NSOpenPanel)
- Appearance: Theme selector, Animation style
- Account: Plan (Free/Pro), Usage stats, Upgrade button

**Step 2: Wire settings to AppDelegate menu**

**Step 3: Commit**

```bash
git add NotchDrop/Views/SettingsView.swift NotchDrop/Core/SettingsWindowController.swift
git commit -m "feat: settings window with storage path, appearance, account"
```

---

### Task 10: StoreKit 2 Integration (Pro Unlock)

**Files:**
- Create: `NotchDrop/Features/StoreManager.swift`
- Modify: `NotchDrop/Features/ProManager.swift`
- Create: `NotchDrop/Configuration.storekit` (StoreKit config file)

**Step 1: Configure StoreKit**

- Create StoreKit configuration file for testing
- Product ID: `com.yourapp.notchdrop.pro` (non-consumable)
- Price: $4.99

**Step 2: Implement StoreManager**

Use StoreKit 2 async/await API:
- `Product.products(for:)` to fetch product
- `product.purchase()` to buy
- `Transaction.currentEntitlements` to check status

**Step 3: Connect to ProManager**

When purchase confirmed → `ProManager.shared.isPro = true`

**Step 4: Commit**

```bash
git add NotchDrop/Features/StoreManager.swift NotchDrop/Configuration.storekit
git commit -m "feat: StoreKit 2 Pro unlock ($4.99 one-time)"
```

---

## Phase 5: Metal Animation

### Task 11: Metal Shader for Liquid Expand/Collapse

**Files:**
- Create: `NotchDrop/Core/MetalAnimationView.swift`
- Modify: `NotchDrop/Core/NotchWindowController.swift`

**Step 1: Create Metal-rendered expand/collapse animation**

Leverage your MenuBarCalendar Metal experience:
- The notch shape scales up with organic, liquid-like interpolation
- Use SDF (Signed Distance Field) for the rounded rectangle shape
- Animate the width/height/cornerRadius with spring-like easing
- Optional: subtle surface shimmer / glass refraction effect

**Step 2: Replace NSAnimationContext with Metal-driven animation**

NotchWindowController should use MetalAnimationView as the background layer, with SwiftUI content overlaid.

**Step 3: Commit**

```bash
git add NotchDrop/Core/MetalAnimationView.swift
git commit -m "feat: Metal shader liquid expand/collapse animation"
```

---

## Phase 6: AI Assistant (Pro Feature)

### Task 12: AI Service Architecture (BYOK)

**Files:**
- Create: `NotchDrop/Features/AI/AIProviderProtocol.swift`
- Create: `NotchDrop/Features/AI/OpenAIProvider.swift`
- Create: `NotchDrop/Features/AI/AnthropicProvider.swift`
- Create: `NotchDrop/Features/AI/AIKeyManager.swift`
- Create: `NotchDrop/Features/AI/AIService.swift`

**Step 1: Define provider protocol**

```swift
// NotchDrop/Features/AI/AIProviderProtocol.swift
import Foundation

protocol AIProvider {
    var name: String { get }
    func summarizeNotes(_ notes: [String]) async throws -> String
    func extractTodos(from notes: [String]) async throws -> [String]
    func quickSummary(_ text: String) async throws -> String
}
```

**Step 2: Implement OpenAI and Anthropic providers**

Each provider:
- Takes API key in init
- Uses URLSession to call respective API
- Parses response and returns result

**Step 3: Create AIKeyManager (Keychain storage)**

Store and retrieve API keys securely via Keychain Services.

**Step 4: Create AIService (facade)**

```swift
class AIService: ObservableObject {
    static let shared = AIService()

    @Published var isProcessing = false
    @Published var selectedProvider: String = "openai" // or "anthropic"

    func getProvider() -> AIProvider? {
        guard ProManager.shared.isPro else { return nil }
        guard let key = AIKeyManager.shared.getKey(for: selectedProvider) else { return nil }

        switch selectedProvider {
        case "openai": return OpenAIProvider(apiKey: key)
        case "anthropic": return AnthropicProvider(apiKey: key)
        default: return nil
        }
    }
}
```

**Step 5: Commit**

```bash
git add NotchDrop/Features/AI/
git commit -m "feat: AI service with OpenAI and Anthropic providers (BYOK)"
```

---

### Task 13: AI UI Integration

**Files:**
- Modify: `NotchDrop/Views/NoteListView.swift`
- Modify: `NotchDrop/Views/TodoListView.swift`
- Modify: `NotchDrop/Views/SettingsView.swift`

**Step 1: Add AI buttons to Notes tab**

- "✦ Summarize" button — sends all notes to AI, shows result
- "✦ Extract Todos" button — AI suggests todos from notes

**Step 2: Add AI settings**

In Settings → new "AI" section:
- Provider selector (OpenAI / Anthropic)
- API Key input (secure field, stored to Keychain)
- "Test Connection" button

**Step 3: Commit**

```bash
git add NotchDrop/Views/
git commit -m "feat: AI UI integration (summarize, extract todos, settings)"
```

---

## Phase 7: Polish & Ship

### Task 14: Launch at Login

**Files:**
- Modify: `NotchDrop/Views/SettingsView.swift`

Add `SMAppService.mainApp.register()` / `unregister()` for launch at login toggle.

**Step: Commit**

```bash
git commit -m "feat: launch at login via SMAppService"
```

---

### Task 15: App Icon & Branding

**Files:**
- Create: `NotchDrop/Assets.xcassets/AppIcon.appiconset/`

Design and add app icon. Should convey "notch + capture/drop" concept.

**Step: Commit**

```bash
git commit -m "feat: app icon"
```

---

### Task 16: Final Testing & App Store Prep

**Steps:**
1. Test on multiple MacBook models (with and without notch)
2. Test free tier limits (10 todo, 10 note, 15 files)
3. Test Pro purchase flow (using StoreKit sandbox)
4. Test AI with real OpenAI and Anthropic keys
5. Archive and upload to App Store Connect
6. Write App Store description, keywords, screenshots
7. Submit for review

**Step: Commit**

```bash
git commit -m "chore: final testing and App Store prep"
```

---

## Summary: Task Dependency Graph

```
Phase 1: Foundation
  Task 1 (Xcode project) → Task 2 (Notch window) → Task 3 (Hover monitor)

Phase 2: Data
  Task 4 (GRDB + models) → Task 5 (Managers + quota)

Phase 3: UI (depends on Phase 1 + 2)
  Task 6 (Main UI) → Task 7 (Input logic) → Task 8 (File drag)

Phase 4: Settings & Money (depends on Phase 3)
  Task 9 (Settings) → Task 10 (StoreKit)

Phase 5: Animation (can parallel with Phase 3-4)
  Task 11 (Metal shader)

Phase 6: AI (depends on Phase 4 for Pro gate)
  Task 12 (AI service) → Task 13 (AI UI)

Phase 7: Polish (depends on all above)
  Task 14 (Launch at login) → Task 15 (Icon) → Task 16 (Ship)
```

## Estimated Timeline

| Phase | Tasks | Estimate |
|-------|-------|----------|
| Phase 1: Foundation | Task 1-3 | 1-2 days |
| Phase 2: Data | Task 4-5 | 1 day |
| Phase 3: UI | Task 6-8 | 2-3 days |
| Phase 4: Settings & Money | Task 9-10 | 1-2 days |
| Phase 5: Metal Animation | Task 11 | 2-3 days |
| Phase 6: AI | Task 12-13 | 1-2 days |
| Phase 7: Polish | Task 14-16 | 2-3 days |
| **Total** | **16 tasks** | **~10-16 days** |
