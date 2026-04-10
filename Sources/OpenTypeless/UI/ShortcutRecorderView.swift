import AppKit
import Carbon
import SwiftUI

struct ShortcutRecorderView: View {
    let label: String
    @Binding var shortcut: StoredShortcut?
    var onRecordStart: (() -> Void)?
    var onRecordEnd: (() -> Void)?

    @State private var isRecording = false
    @State private var errorMessage: String?
    @State private var monitor: Any?

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)

            Button(action: toggleRecording) {
                Text(buttonText)
                    .frame(minWidth: 140)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    private var buttonText: String {
        if isRecording {
            return "Press a key combo..."
        }
        if let shortcut = shortcut {
            return shortcut.displayString
        }
        return "Click to record"
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        errorMessage = nil
        onRecordStart?()

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            let keyCode = CGKeyCode(event.keyCode)
            let flags = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
            let relevantFlags: CGEventFlags = [.maskAlternate, .maskControl, .maskShift, .maskCommand]
            let pressed = flags.intersection(relevantFlags)

            shortcut = StoredShortcut(keyCode: keyCode, modifiers: pressed)
            errorMessage = nil
            stopRecording()
            return nil // swallow the event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        onRecordEnd?()
    }
}
