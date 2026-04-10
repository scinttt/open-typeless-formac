import SwiftUI

enum SessionStatus: String {
    case idle = "Idle"
    case recording = "Recording"
    case processing = "Processing"
    case error = "Error"
}

@MainActor
final class AppState: ObservableObject {
    @Published var status: SessionStatus = .idle
    private var errorResetTask: Task<Void, Never>?

    var menuBarTitle: String {
        status.rawValue
    }

    var menuBarIcon: String {
        switch status {
        case .idle: return "mic"
        case .recording: return "mic.fill"
        case .processing: return "ellipsis.circle"
        case .error: return "exclamationmark.triangle"
        }
    }

    /// Briefly show error status, then return to idle.
    func flashError() {
        errorResetTask?.cancel()
        status = .error
        errorResetTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled {
                status = .idle
            }
        }
    }
}
