import Carbon
import CoreGraphics
import Foundation

struct StoredShortcut: Equatable {
    var keyCode: CGKeyCode
    var modifiers: CGEventFlags

    var isValid: Bool {
        return true // single key and combo keys both allowed
    }

    var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.maskControl) { parts.append("⌃") }
        if modifiers.contains(.maskAlternate) { parts.append("⌥") }
        if modifiers.contains(.maskShift) { parts.append("⇧") }
        if modifiers.contains(.maskCommand) { parts.append("⌘") }
        parts.append(keyCodeName(keyCode))
        return parts.joined()
    }
}

enum HotkeyStore {
    private static let transcribeKeyCodeKey = "hotkeyTranscribeKeyCode"
    private static let transcribeModifiersKey = "hotkeyTranscribeModifiers"
    private static let translateKeyCodeKey = "hotkeyTranslateKeyCode"
    private static let translateModifiersKey = "hotkeyTranslateModifiers"
    private static let setupCompletedKey = "setupCompleted"

    static var isSetupCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: setupCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: setupCompletedKey) }
    }

    static func loadTranscribe() -> StoredShortcut? {
        load(keyCodeKey: transcribeKeyCodeKey, modifiersKey: transcribeModifiersKey)
    }

    static func loadTranslate() -> StoredShortcut? {
        load(keyCodeKey: translateKeyCodeKey, modifiersKey: translateModifiersKey)
    }

    static func saveTranscribe(_ shortcut: StoredShortcut) {
        save(shortcut, keyCodeKey: transcribeKeyCodeKey, modifiersKey: transcribeModifiersKey)
    }

    static func saveTranslate(_ shortcut: StoredShortcut) {
        save(shortcut, keyCodeKey: translateKeyCodeKey, modifiersKey: translateModifiersKey)
    }

    static func loadConfig() -> HotkeyManager.HotkeyConfig? {
        guard let t = loadTranscribe() else { return nil }
        let tr = loadTranslate()
        return HotkeyManager.HotkeyConfig(
            transcribeKeyCode: t.keyCode,
            transcribeModifiers: t.modifiers,
            translateKeyCode: tr?.keyCode ?? CGKeyCode(kVK_ANSI_D),
            translateModifiers: tr?.modifiers ?? .maskControl
        )
    }

    // MARK: - Private

    private static func load(keyCodeKey: String, modifiersKey: String) -> StoredShortcut? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: keyCodeKey) != nil else { return nil }
        let keyCode = CGKeyCode(defaults.integer(forKey: keyCodeKey))
        // Store modifiers as string to preserve full UInt64 range
        let modRaw = defaults.object(forKey: modifiersKey) as? String ?? "0"
        let modifiers = CGEventFlags(rawValue: UInt64(modRaw) ?? 0)
        let shortcut = StoredShortcut(keyCode: keyCode, modifiers: modifiers)
        return shortcut.isValid ? shortcut : nil
    }

    private static func save(_ shortcut: StoredShortcut, keyCodeKey: String, modifiersKey: String) {
        let defaults = UserDefaults.standard
        defaults.set(Int(shortcut.keyCode), forKey: keyCodeKey)
        defaults.set(String(shortcut.modifiers.rawValue), forKey: modifiersKey)
    }
}

// MARK: - Key code to name mapping

private func keyCodeName(_ keyCode: CGKeyCode) -> String {
    let map: [CGKeyCode: String] = [
        CGKeyCode(kVK_ANSI_A): "A", CGKeyCode(kVK_ANSI_B): "B",
        CGKeyCode(kVK_ANSI_C): "C", CGKeyCode(kVK_ANSI_D): "D",
        CGKeyCode(kVK_ANSI_E): "E", CGKeyCode(kVK_ANSI_F): "F",
        CGKeyCode(kVK_ANSI_G): "G", CGKeyCode(kVK_ANSI_H): "H",
        CGKeyCode(kVK_ANSI_I): "I", CGKeyCode(kVK_ANSI_J): "J",
        CGKeyCode(kVK_ANSI_K): "K", CGKeyCode(kVK_ANSI_L): "L",
        CGKeyCode(kVK_ANSI_M): "M", CGKeyCode(kVK_ANSI_N): "N",
        CGKeyCode(kVK_ANSI_O): "O", CGKeyCode(kVK_ANSI_P): "P",
        CGKeyCode(kVK_ANSI_Q): "Q", CGKeyCode(kVK_ANSI_R): "R",
        CGKeyCode(kVK_ANSI_S): "S", CGKeyCode(kVK_ANSI_T): "T",
        CGKeyCode(kVK_ANSI_U): "U", CGKeyCode(kVK_ANSI_V): "V",
        CGKeyCode(kVK_ANSI_W): "W", CGKeyCode(kVK_ANSI_X): "X",
        CGKeyCode(kVK_ANSI_Y): "Y", CGKeyCode(kVK_ANSI_Z): "Z",
        CGKeyCode(kVK_ANSI_0): "0", CGKeyCode(kVK_ANSI_1): "1",
        CGKeyCode(kVK_ANSI_2): "2", CGKeyCode(kVK_ANSI_3): "3",
        CGKeyCode(kVK_ANSI_4): "4", CGKeyCode(kVK_ANSI_5): "5",
        CGKeyCode(kVK_ANSI_6): "6", CGKeyCode(kVK_ANSI_7): "7",
        CGKeyCode(kVK_ANSI_8): "8", CGKeyCode(kVK_ANSI_9): "9",
        CGKeyCode(kVK_F1): "F1", CGKeyCode(kVK_F2): "F2",
        CGKeyCode(kVK_F3): "F3", CGKeyCode(kVK_F4): "F4",
        CGKeyCode(kVK_F5): "F5", CGKeyCode(kVK_F6): "F6",
        CGKeyCode(kVK_F7): "F7", CGKeyCode(kVK_F8): "F8",
        CGKeyCode(kVK_F9): "F9", CGKeyCode(kVK_F10): "F10",
        CGKeyCode(kVK_F11): "F11", CGKeyCode(kVK_F12): "F12",
        CGKeyCode(kVK_Space): "Space", CGKeyCode(kVK_Return): "Return",
        CGKeyCode(kVK_Tab): "Tab", CGKeyCode(kVK_Escape): "Esc",
        CGKeyCode(kVK_Delete): "Delete",
        CGKeyCode(kVK_ANSI_Minus): "-", CGKeyCode(kVK_ANSI_Equal): "=",
        CGKeyCode(kVK_ANSI_LeftBracket): "[", CGKeyCode(kVK_ANSI_RightBracket): "]",
        CGKeyCode(kVK_ANSI_Backslash): "\\", CGKeyCode(kVK_ANSI_Semicolon): ";",
        CGKeyCode(kVK_ANSI_Quote): "'", CGKeyCode(kVK_ANSI_Comma): ",",
        CGKeyCode(kVK_ANSI_Period): ".", CGKeyCode(kVK_ANSI_Slash): "/",
        CGKeyCode(kVK_ANSI_Grave): "`",
    ]
    return map[keyCode] ?? "Key\(keyCode)"
}
