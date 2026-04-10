import ServiceManagement
import SwiftUI

enum SettingsTab: String, CaseIterable {
    case hotkeys = "Hotkeys"
    case api = "API"
    case test = "Test"
}

struct MainWindowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: DictationSessionCoordinator
    @EnvironmentObject var permissionManager: PermissionManager

    let hotkeyManager: HotkeyManager

    @State private var selectedTab: SettingsTab = .hotkeys

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tabIcon(tab))
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 140, ideal: 160)
        } detail: {
            switch selectedTab {
            case .hotkeys:
                HotkeysTabView(hotkeyManager: hotkeyManager)
                    .environmentObject(permissionManager)
            case .api:
                APITabView()
            case .test:
                TestTabView()
                    .environmentObject(appState)
                    .environmentObject(coordinator)
            }
        }
        .frame(width: 560, height: 400)
        .onAppear {
            permissionManager.checkAll()
        }
    }

    private func tabIcon(_ tab: SettingsTab) -> String {
        switch tab {
        case .hotkeys: return "keyboard"
        case .api: return "key"
        case .test: return "mic"
        }
    }
}

// MARK: - Hotkeys Tab

struct HotkeysTabView: View {
    let hotkeyManager: HotkeyManager
    @EnvironmentObject var permissionManager: PermissionManager

    @State private var transcribeShortcut: StoredShortcut?
    @State private var launchAtLogin: Bool = false
    @State private var saveStatus: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Permissions
            GroupBox("Permissions") {
                VStack(alignment: .leading, spacing: 8) {
                    permissionRow(
                        name: "Microphone",
                        granted: permissionManager.microphoneGranted,
                        action: { Task { await permissionManager.requestMicrophone() } }
                    )
                    permissionRow(
                        name: "Accessibility",
                        granted: permissionManager.accessibilityGranted,
                        action: {
                            permissionManager.requestAccessibility()
                            permissionManager.openAccessibilitySettings()
                        }
                    )
                    if !permissionManager.accessibilityGranted {
                        Text("After granting, remove the old entry and re-add via Grant Access.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
            }

            // Hotkey
            GroupBox("Hotkey") {
                VStack(alignment: .leading, spacing: 8) {
                    ShortcutRecorderView(
                        label: "Transcribe:",
                        shortcut: $transcribeShortcut,
                        onRecordStart: { hotkeyManager.pause() },
                        onRecordEnd: { hotkeyManager.resume() }
                    )
                    Text("Default: Right Option (Alt). Press once to start, press again to stop. Double-press to cancel.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            }

            // General
            GroupBox("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
                    .padding(8)
            }

            // Save
            HStack {
                Spacer()
                if let status = saveStatus {
                    Text(status).foregroundStyle(.green).font(.caption)
                }
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding(20)
        .onAppear { load() }
    }

    private func load() {
        transcribeShortcut = HotkeyStore.loadTranscribe()
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func save() {
        if let t = transcribeShortcut {
            HotkeyStore.saveTranscribe(t)
        }
        if let config = HotkeyStore.loadConfig() {
            hotkeyManager.config = config
        }
        HotkeyStore.isSetupCompleted = true
        saveStatus = "Saved!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saveStatus = nil }
    }

    private func permissionRow(name: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(granted ? .green : .red)
            Text(name)
            Spacer()
            if !granted {
                Button("Grant Access") { action() }
                    .buttonStyle(.bordered)
            } else {
                Text("Granted").foregroundStyle(.secondary).font(.caption)
            }
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

// MARK: - API Tab

struct APITabView: View {
    @State private var apiKey: String = ""
    @State private var provider: APIProvider = .openAI
    @State private var customHost: String = ""
    @State private var customBasePath: String = ""
    @State private var selectedModel: String = "gpt-4o-mini-transcribe"
    @State private var saveStatus: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox("Provider") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Provider", selection: $provider) {
                        ForEach(APIProvider.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)

                    if provider == .custom {
                        TextField("Host (e.g. space.ai-builders.com)", text: $customHost)
                            .textFieldStyle(.roundedBorder)
                        TextField("Base Path (e.g. /backend/v1)", text: $customBasePath)
                            .textFieldStyle(.roundedBorder)
                        Text("Must be an OpenAI-compatible API endpoint")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
            }

            GroupBox("API Key") {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: apiKey) { _, newValue in
                        TranscriptionService.apiKey = newValue
                    }
                    .padding(8)
            }

            GroupBox("Model") {
                Picker("Model", selection: $selectedModel) {
                    Text("gpt-4o-mini-transcribe ($0.003/min)").tag("gpt-4o-mini-transcribe")
                    Text("gpt-4o-transcribe ($0.006/min)").tag("gpt-4o-transcribe")
                    Text("whisper-1 ($0.006/min)").tag("whisper-1")
                }
                .pickerStyle(.menu)
                .padding(8)
            }

            HStack {
                Spacer()
                if let status = saveStatus {
                    Text(status).foregroundStyle(.green).font(.caption)
                }
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding(20)
        .onAppear { load() }
    }

    private func load() {
        apiKey = TranscriptionService.apiKey
        provider = TranscriptionService.provider
        customHost = TranscriptionService.customHost
        customBasePath = TranscriptionService.customBasePath
        selectedModel = UserDefaults.standard.string(forKey: "transcriptionModel") ?? TranscriptionService.model

        if let stored = UserDefaults.standard.string(forKey: "apiProvider"),
           let p = APIProvider(rawValue: stored) { provider = p }
        if let h = UserDefaults.standard.string(forKey: "customHost") { customHost = h }
        if let bp = UserDefaults.standard.string(forKey: "customBasePath") { customBasePath = bp }
    }

    private func save() {
        if !apiKey.isEmpty { TranscriptionService.apiKey = apiKey }
        TranscriptionService.provider = provider
        if provider == .custom {
            if !customHost.isEmpty { TranscriptionService.customHost = customHost }
            if !customBasePath.isEmpty { TranscriptionService.customBasePath = customBasePath }
        }
        TranscriptionService.model = selectedModel
        UserDefaults.standard.set(provider.rawValue, forKey: "apiProvider")
        UserDefaults.standard.set(customHost, forKey: "customHost")
        UserDefaults.standard.set(customBasePath, forKey: "customBasePath")
        UserDefaults.standard.set(selectedModel, forKey: "transcriptionModel")

        saveStatus = "Saved!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saveStatus = nil }
    }
}

// MARK: - Test Tab

struct TestTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: DictationSessionCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox("Recording") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Status:")
                        Text(appState.status.rawValue)
                            .foregroundStyle(appState.status == .recording ? .red : .secondary)
                            .fontWeight(appState.status == .recording ? .bold : .regular)
                    }

                    Text("Press your hotkey to start recording, press again to stop.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            }

            GroupBox("Result") {
                TextEditor(text: $coordinator.lastTestResult)
                    .frame(minHeight: 100)
                    .border(Color.gray.opacity(0.3))
                    .font(.body)
                    .padding(8)
            }

            Spacer()
        }
        .padding(20)
    }
}
