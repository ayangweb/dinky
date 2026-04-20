import SwiftUI

struct HistorySheet: View {
    @EnvironmentObject var prefs: DinkyPreferences
    @Environment(\.dismiss) private var dismiss
    /// When set, rows with stored batch summary data show “Open Summary…”.
    var onOpenSessionSummary: ((SessionRecord) -> Void)?

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
            if prefs.lifetimeSavedBytes > 0 {
                lifetimeTotalBanner
                Divider()
            }
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
            Text(String(localized: "History", comment: "History window title."))
                .font(.headline)
            Spacer()
            if !prefs.sessionHistory.isEmpty {
                Button(String(localized: "Clear", comment: "Clear session history list.")) {
                    prefs.sessionHistory = []
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
            Button(String(localized: "Done", comment: "Dismiss sheet.")) { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var lifetimeTotalBanner: some View {
        HStack {
            Text(String(localized: "Total saved", comment: "History: lifetime bytes saved label."))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(lifetimeSavedFormatted + String(localized: " saved", comment: "Suffix after size in history banner."))
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var lifetimeSavedFormatted: String {
        let mb = Double(prefs.lifetimeSavedBytes) / 1_048_576
        if mb >= 1024 { return String(format: "%.1f GB", mb / 1024) }
        return String(format: "%.0f MB", mb)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(String(localized: "No sessions yet.", comment: "History empty state."))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyList: some View {
        List(prefs.sessionHistory) { record in
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dateFormatter.string(from: record.timestamp))
                        .font(.caption.weight(.medium))
                    Text(record.formats.joined(separator: ", "))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    if let onOpenSessionSummary, record.batchSummaryData != nil {
                        Button(String(localized: "Open Summary…", comment: "History row: reopen stored batch completion dialog.")) {
                            onOpenSessionSummary(record)
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                        .help(String(localized: "Show the file list and stats from this compression run.", comment: "History Open Summary tooltip."))
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(historySessionFileCountLabel(record.fileCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formattedSize(record.totalBytesSaved) + String(localized: " saved", comment: "Suffix after size in history row."))
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

    private func historySessionFileCountLabel(_ count: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString("history_session_file_count", bundle: .main, comment: "History row; plural by file count."),
            count
        )
    }

    private func formattedSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb >= 1024 { return String(format: "%.1f GB", mb / 1024) }
        return String(format: "%.1f MB", mb)
    }
}
