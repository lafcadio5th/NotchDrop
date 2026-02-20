//
//  QuickInputView.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import SwiftUI

/// A text input field for quick capture of todos and notes.
///
/// - Press `Enter` to add the text as a todo.
/// - Press `Cmd+Enter` to add the text as a note.
///
/// Uses an `NSViewRepresentable` wrapper around `NSTextField` to
/// intercept key events and distinguish between plain Enter and
/// Cmd+Enter, since SwiftUI's `.onSubmit` does not expose modifier
/// flags.
struct QuickInputView: View {
    @Binding var selectedTab: NotchTab
    @State private var inputText = ""
    @State private var errorMessage: String?
    @State private var errorOpacity: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            QuickInputTextField(
                text: $inputText,
                placeholder: "Type here... \u{21B5} Todo  \u{2318}\u{21B5} Note",
                onEnter: { handleAddTodo() },
                onCmdEnter: { handleAddNote() }
            )
            .frame(height: 36)

            ZStack {
                // Keyboard hint row
                HStack {
                    Text("\u{21B5} Todo")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.25))
                    Spacer()
                    Text("\u{2318}\u{21B5} Note")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.25))
                }
                .opacity(errorMessage == nil ? 1 : 0)

                // Error message overlay
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.red.opacity(0.7))
                        .opacity(errorOpacity)
                }
            }
            .frame(height: 14)
            .padding(.horizontal, 2)
        }
    }

    private func handleAddTodo() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if TodoManager.shared.addTodo(text) {
            inputText = ""
            selectedTab = .todos
        } else {
            showError("Todo limit reached (10/10)")
        }
    }

    private func handleAddNote() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if NoteManager.shared.addNote(text) {
            inputText = ""
            selectedTab = .notes
        } else {
            showError("Note limit reached (10/10)")
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        withAnimation(.easeIn(duration: 0.15)) {
            errorOpacity = 1
        }
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) {
                errorOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                errorMessage = nil
            }
        }
    }
}

// MARK: - NSTextField wrapper for key event interception

/// A custom `NSViewRepresentable` that wraps `NSTextField` and
/// intercepts keyboard events to distinguish Enter from Cmd+Enter.
struct QuickInputTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onEnter: () -> Void
    var onCmdEnter: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = InputInterceptingTextField()
        textField.delegate = context.coordinator
        textField.onEnter = onEnter
        textField.onCmdEnter = onCmdEnter

        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = .systemFont(ofSize: 13)
        textField.textColor = .white
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.stringValue = text

        // Style the placeholder
        textField.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor.white.withAlphaComponent(0.3),
                .font: NSFont.systemFont(ofSize: 13),
            ]
        )

        // Wrap in a visual effect view for the background
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 10
        textField.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.06).cgColor
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = NSColor.white.withAlphaComponent(0.1).cgColor

        // Add padding via cell insets
        if let cell = textField.cell as? NSTextFieldCell {
            cell.lineBreakMode = .byTruncatingTail
        }

        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        if textField.stringValue != text {
            textField.stringValue = text
        }
        // Update closures
        if let intercepting = textField as? InputInterceptingTextField {
            intercepting.onEnter = onEnter
            intercepting.onCmdEnter = onCmdEnter
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            text = textField.stringValue
        }
    }
}

// MARK: - Padded Text Field Cell

/// Custom `NSTextFieldCell` that adds horizontal padding to the text
/// editing and drawing areas.
class PaddedTextFieldCell: NSTextFieldCell {
    private let horizontalPadding: CGFloat = 14

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        let insetFrame = cellFrame.insetBy(dx: horizontalPadding, dy: 0)
        super.drawInterior(withFrame: insetFrame, in: controlView)
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        let insetRect = rect.insetBy(dx: horizontalPadding, dy: 0)
        super.edit(withFrame: insetRect, in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        let insetRect = rect.insetBy(dx: horizontalPadding, dy: 0)
        super.select(withFrame: insetRect, in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
}

/// NSTextField subclass that intercepts Enter and Cmd+Enter key events
/// before the default text field handling, and uses a padded cell for
/// internal horizontal padding.
class InputInterceptingTextField: NSTextField {
    var onEnter: (() -> Void)?
    var onCmdEnter: (() -> Void)?

    override class var cellClass: AnyClass? {
        get { PaddedTextFieldCell.self }
        set { super.cellClass = newValue }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Cmd+Enter (Return = keyCode 36, Enter = keyCode 76)
        if (event.keyCode == 36 || event.keyCode == 76),
           event.modifierFlags.contains(.command)
        {
            onCmdEnter?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func textDidEndEditing(_ notification: Notification) {
        // Check if editing ended because of Return key
        if let movement = notification.userInfo?["NSTextMovement"] as? Int,
           movement == NSReturnTextMovement
        {
            onEnter?()
            // Keep focus on the text field
            DispatchQueue.main.async {
                self.window?.makeFirstResponder(self)
            }
            return
        }
        super.textDidEndEditing(notification)
    }
}
