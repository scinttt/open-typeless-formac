import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

enum InsertionResult {
    case insertedViaAX
    case insertedViaClipboard
    case showPopup(String)
}

enum InsertionStrategy {
    /// Insert text using the best available method, falling back through layers.
    @MainActor
    static func insert(text: String, snapshot: OutputTargetSnapshot) async -> InsertionResult {
        // Check if there's a text input target
        if snapshot.focusedElement != nil && snapshot.hasTextInput {
            let pasted = await clipboardPaste(text: text)
            if pasted {
                return .insertedViaClipboard
            }
        }

        // No text input — show popup with copy button
        return .showPopup(text)
    }

    /// Paste via clipboard with original content preservation.
    private static func clipboardPaste(text: String) async -> Bool {
        let pasteboard = NSPasteboard.general
        // Save original clipboard
        let originalItems = pasteboard.pasteboardItems?.compactMap { item -> (String, Data)? in
            guard let type = item.types.first,
                  let data = item.data(forType: type) else { return nil }
            return (type.rawValue, data)
        }

        // Set new content
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V
        simulatePaste()

        // Wait for paste to complete (~300ms)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Restore original clipboard
        pasteboard.clearContents()
        if let items = originalItems {
            for (typeStr, data) in items {
                let type = NSPasteboard.PasteboardType(typeStr)
                pasteboard.setData(data, forType: type)
            }
        }

        return true
    }

    private static func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down: Cmd+V (keycode 9 = V)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        // Key up
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}
