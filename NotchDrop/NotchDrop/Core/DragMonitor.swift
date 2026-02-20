//
//  DragMonitor.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import AppKit
import Combine

/// Shared observable state for drag-and-drop activity.
///
/// Views observe ``isDragActive`` to show or hide the drop zone overlay.
/// ``DragMonitor`` and ``DropTargetView`` update this state as drags
/// enter and exit the panel.
class DragState: ObservableObject {
    static let shared = DragState()
    @Published var isDragActive: Bool = false
}

/// A custom `NSView` that acts as a dragging destination for file URLs.
///
/// When files are dragged over the view, it notifies the controller via
/// closures so the panel can expand and show a drop overlay. When files
/// are dropped, they are forwarded to ``FileShelfManager``.
class DropTargetView: NSView {
    var onFilesDropped: (([URL]) -> Void)?
    var onDragEntered: (() -> Void)?
    var onDragExited: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        onDragEntered?()
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onDragExited?()
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let items = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] else {
            return false
        }
        guard !items.isEmpty else { return false }
        onFilesDropped?(items)
        return true
    }
}

/// Monitors system-wide drag events to expand the notch panel when a
/// file drag is detected near the notch area.
///
/// This uses `NSEvent.addGlobalMonitorForEvents` for `leftMouseDragged`
/// events, checking the drag pasteboard for file URLs. Because macOS
/// does not always populate the drag pasteboard during global monitoring,
/// the primary mechanism for drag detection is the ``DropTargetView``
/// registered on the panel itself. This monitor serves as a supplementary
/// signal to expand the panel early when the cursor is near the notch
/// during a drag.
class DragMonitor {
    private var monitor: Any?
    private let onDragBegan: () -> Void
    private let onDragEnded: () -> Void

    private var isDragging = false
    private var dragEndTimer: Timer?

    init(onDragBegan: @escaping () -> Void, onDragEnded: @escaping () -> Void) {
        self.onDragBegan = onDragBegan
        self.onDragEnded = onDragEnded
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            guard let self else { return }

            if event.type == .leftMouseUp {
                self.handleDragEnd()
                return
            }

            // Check if the drag pasteboard contains file URLs
            let pasteboard = NSPasteboard(name: .drag)
            if pasteboard.types?.contains(.fileURL) == true {
                if !self.isDragging {
                    self.isDragging = true
                    self.onDragBegan()
                }
                // Reset the end timer on each drag event
                self.dragEndTimer?.invalidate()
                self.dragEndTimer = Timer.scheduledTimer(
                    withTimeInterval: 0.5,
                    repeats: false
                ) { [weak self] _ in
                    self?.handleDragEnd()
                }
            }
        }
    }

    private func handleDragEnd() {
        dragEndTimer?.invalidate()
        dragEndTimer = nil
        if isDragging {
            isDragging = false
            onDragEnded()
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        dragEndTimer?.invalidate()
        dragEndTimer = nil
        isDragging = false
    }

    deinit {
        stop()
    }
}
