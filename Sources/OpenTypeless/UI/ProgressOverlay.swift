import AppKit
import SwiftUI

enum OverlayState {
    case recording
    case transcribing
    case error
}

@MainActor
final class ProgressOverlayController {
    static let shared = ProgressOverlayController()

    private var window: NSPanel?
    private var viewModel = OverlayViewModel()
    private var dismissTask: Task<Void, Never>?
    private var meteringTimer: Timer?

    /// Set this to poll audio level during recording
    var audioLevelProvider: (() -> Float)?

    func show(state: OverlayState) {
        dismissTask?.cancel()
        viewModel.state = state
        viewModel.audioLevel = 0

        if state == .recording {
            startMetering()
        } else {
            stopMetering()
        }

        if window != nil {
            window?.orderFrontRegardless()
            return
        }

        let view = ProgressOverlayView(viewModel: viewModel)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 220, height: 48)

        let panel = NSPanel(
            contentRect: hosting.frame,
            styleMask: [.nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hosting
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        positionAtBottomCenter(panel)
        panel.orderFrontRegardless()

        self.window = panel
    }

    func update(state: OverlayState) {
        viewModel.state = state
        if state == .recording {
            startMetering()
        } else {
            stopMetering()
        }
    }

    func dismiss() {
        stopMetering()
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            await NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                self.window?.animator().alphaValue = 0
            }

            self.window?.close()
            self.window = nil
        }
    }

    func flashError() {
        update(state: .error)
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    private func startMetering() {
        meteringTimer?.invalidate()
        let timer = Timer(timeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let level = self.audioLevelProvider?() ?? 0
            DispatchQueue.main.async {
                self.viewModel.audioLevel = level
            }
        }
        // Run on common modes so it doesn't block the main run loop's event processing
        RunLoop.main.add(timer, forMode: .common)
        meteringTimer = timer
    }

    private func stopMetering() {
        meteringTimer?.invalidate()
        meteringTimer = nil
        viewModel.audioLevel = 0
    }

    private func positionAtBottomCenter(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - panel.frame.width / 2
        let y = screenFrame.origin.y + 80
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.alphaValue = 1
    }
}

@MainActor
final class OverlayViewModel: ObservableObject {
    @Published var state: OverlayState = .recording
    @Published var audioLevel: Float = 0
}

struct ProgressOverlayView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        HStack(spacing: 10) {
            stateIcon
            Text(stateText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
            if viewModel.state == .recording {
                AudioLevelBar(level: CGFloat(viewModel.audioLevel))
                    .frame(width: 40, height: 16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(stateColor.opacity(0.3))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(stateColor.opacity(0.5), lineWidth: 1))
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch viewModel.state {
        case .recording:
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .modifier(PulseModifier())
        case .transcribing:
            ProgressView()
                .controlSize(.small)
                .tint(.white)
        case .error:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    private var stateText: String {
        switch viewModel.state {
        case .recording: return "Recording..."
        case .transcribing: return "Transcribing..."
        case .error: return "Error"
        }
    }

    private var stateColor: Color {
        switch viewModel.state {
        case .recording: return .red
        case .transcribing: return .blue
        case .error: return .red
        }
    }
}

struct AudioLevelBar: View {
    let level: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.2))
                Capsule()
                    .fill(.green)
                    .frame(width: max(geo.size.width * level, 2))
                    .animation(.linear(duration: 0.05), value: level)
            }
        }
    }
}

private struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
