import AppKit
import SwiftUI

struct HistoryTabView: View {
    let l: L
    let store: HistoryStore

    @State private var entries: [HistoryEntry] = []
    @State private var retentionPolicy: HistoryRetentionPolicy = .keepForever
    @State private var copiedEntryID: UUID?

    init(l: L, store: HistoryStore = .shared) {
        self.l = l
        self.store = store
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(historyTitle) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(historyDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker(retentionTitle, selection: $retentionPolicy) {
                        ForEach(HistoryRetentionPolicy.allCases, id: \.self) { policy in
                            Text(retentionLabel(for: policy)).tag(policy)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: retentionPolicy) { _, newValue in
                        store.setRetentionPolicy(newValue)
                        reload()
                    }

                    if entries.isEmpty {
                        Text(emptyState)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        List(entries) { entry in
                            row(for: entry)
                        }
                        .frame(minHeight: 260)
                    }
                }
                .padding(8)
            }

            Spacer()
        }
        .padding(20)
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: HistoryStore.didChangeNotification)) { _ in
            reload()
        }
    }

    @ViewBuilder
    private func row(for entry: HistoryEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.text)
                    .textSelection(.enabled)
                Text(Self.dateFormatter.string(from: entry.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(copiedEntryID == entry.id ? copiedLabel : copyLabel) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.text, forType: .string)
                copiedEntryID = entry.id
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }

    private func reload() {
        retentionPolicy = store.retentionPolicy()
        entries = store.loadAll()
        if let copiedEntryID, !entries.contains(where: { $0.id == copiedEntryID }) {
            self.copiedEntryID = nil
        }
    }

    private func retentionLabel(for policy: HistoryRetentionPolicy) -> String {
        switch policy {
        case .keepForever:
            return l.lang == .zh ? "永久保留" : "Keep forever"
        case .keepMonth:
            return l.lang == .zh ? "保留一个月" : "Keep a month"
        case .keepWeek:
            return l.lang == .zh ? "保留一周" : "Keep a week"
        case .keep24Hours:
            return l.lang == .zh ? "保留 24 小时" : "Keep 24 hours"
        }
    }

    private var historyTitle: String { l.lang == .zh ? "历史记录" : "History" }
    private var historyDescription: String {
        l.lang == .zh
            ? "每次完成转写后，最终插入或展示给用户的文本都会自动保存在本地。"
            : "After each transcription completes, the final text shown or inserted for the user is saved locally."
    }
    private var retentionTitle: String { l.lang == .zh ? "保留策略" : "Retention" }
    private var emptyState: String {
        l.lang == .zh
            ? "还没有历史记录。完成一次转写后，这里会自动出现对应文本。"
            : "No history yet. Completed transcriptions will appear here automatically."
    }
    private var copyLabel: String { l.lang == .zh ? "复制" : "Copy" }
    private var copiedLabel: String { l.lang == .zh ? "已复制" : "Copied" }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}
