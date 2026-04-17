import SwiftUI

struct HistorySheet: View {
    @EnvironmentObject var prefs: DinkyPreferences
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if prefs.sessionHistory.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .frame(minWidth: 420, minHeight: 300)
        .background(.ultraThinMaterial)
    }

    private var header: some View {
        HStack {
            Text("History")
                .font(.headline)
            Spacer()
            if !prefs.sessionHistory.isEmpty {
                Button("Clear") {
                    prefs.sessionHistory = []
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No sessions yet.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyList: some View {
        List(prefs.sessionHistory) { record in
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dateFormatter.string(from: record.timestamp))
                        .font(.caption.weight(.medium))
                    Text(record.formats.joined(separator: ", "))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(record.fileCount) \(record.fileCount == 1 ? "file" : "files")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formattedSize(record.totalBytesSaved) + " saved")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
            .listRowSeparatorTint(.primary.opacity(0.08))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func formattedSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb >= 1024 { return String(format: "%.1f GB", mb / 1024) }
        return String(format: "%.1f MB", mb)
    }
}
