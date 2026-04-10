import ApplicationServices
import Foundation

struct OutputTargetSnapshot {
    let focusedElement: AXUIElement?
    let appPID: pid_t?
    private let createdAt = Date()

    static func capture() -> OutputTargetSnapshot {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: AnyObject?
        let appResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)

        guard appResult == .success, let app = focusedApp else {
            return OutputTargetSnapshot(focusedElement: nil, appPID: nil)
        }

        var focusedElement: AnyObject?
        let elementResult = AXUIElementCopyAttributeValue(
            app as! AXUIElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        var pid: pid_t = 0
        AXUIElementGetPid(app as! AXUIElement, &pid)

        if elementResult == .success {
            return OutputTargetSnapshot(focusedElement: focusedElement as! AXUIElement?, appPID: pid)
        }
        return OutputTargetSnapshot(focusedElement: nil, appPID: pid)
    }

    /// Check if the snapshot target is still valid for text insertion.
    func isValid() -> Bool {
        guard let element = focusedElement else { return false }

        // Check if the element's role is a text input
        var role: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        guard result == .success, let roleStr = role as? String else { return false }

        let textRoles = [
            kAXTextFieldRole, kAXTextAreaRole, kAXComboBoxRole,
            "AXWebArea", "AXSearchField",
        ]
        return textRoles.contains(roleStr)
    }

    var hasTarget: Bool {
        focusedElement != nil
    }

    /// Broader check: is the focused element any kind of text-accepting area?
    var hasTextInput: Bool {
        guard let element = focusedElement else { return false }

        var role: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        guard result == .success, let roleStr = role as? String else { return false }

        let textRoles = [
            kAXTextFieldRole, kAXTextAreaRole, kAXComboBoxRole,
            "AXWebArea", "AXSearchField",
            "AXStaticText", "AXScrollArea", "AXGroup",
        ]

        // Also check if the element is editable (has AXValue settable or accepts key input)
        if textRoles.contains(roleStr) { return true }

        // Check if parent or the element itself has an editable trait
        var settable: DarwinBoolean = false
        let isSettable = AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &settable)
        if isSettable == .success && settable.boolValue { return true }

        return false
    }
}
