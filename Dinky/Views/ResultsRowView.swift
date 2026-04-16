import SwiftUI

struct ResultsRowView: View {
    @ObservedObject var item: ImageItem
    @State private var showingError = false

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.sourceURL.path))
                .resizable()
                .frame(width: 24, height: 24)

            Text(item.filename)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            sizeInfo
            statusChip
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .sheet(isPresented: $showingError) {
            if case .failed(let error) = item.status {
                ErrorDetailView(filename: item.filename, error: error)
            }
        }
    }

    // MARK: Size diff

    @ViewBuilder
    private var sizeInfo: some View {
        switch item.status {
        case .done(_, let orig, let out):
            HStack(spacing: 5) {
                Text(bytes(orig))
                Image(systemName: "arrow.right")
                    .imageScale(.small)
                Text(bytes(out))
                    .fontWeight(.medium)
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)

        default:
            Text(bytes(item.originalSize))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: Status chip

    @ViewBuilder
    private var statusChip: some View {
        switch item.status {
        case .pending:
            chip("Queued", color: .secondary.opacity(0.35), fg: .primary)

        case .processing:
            HStack(spacing: 5) {
                ProgressView().scaleEffect(0.65)
                Text("Working")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: 90, alignment: .trailing)

        case .done:
            let pct = item.savedPercent
            if pct >= 5 {
                savingsChip(String(format: "−%.1f%%", pct))
            } else {
                chip(String(format: "−%.1f%%", pct), color: .orange.opacity(0.85), fg: .white)
            }

        case .skipped:
            chip("Skipped", color: .secondary.opacity(0.35), fg: .primary)

        case .zeroGain:
            chip("No gain", color: .secondary.opacity(0.35), fg: .primary)

        case .failed:
            Button { showingError = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .imageScale(.small)
                    Text("Error")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.red.opacity(0.75)))
                .frame(width: 90, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Chip styles

    private func chip(_ label: String, color: Color, fg: Color) -> some View {
        Text(label)
            .font(.caption.weight(.medium))
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(color))
            .frame(width: 90, alignment: .trailing)
    }

    private func savingsChip(_ label: String) -> some View {
        Text(label)
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.25, green: 0.55, blue: 1.0),
                                 Color(red: 0.45, green: 0.30, blue: 0.95)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
            .frame(width: 90, alignment: .trailing)
    }

    private func bytes(_ n: Int64) -> String {
        let kb = Double(n) / 1024
        return kb < 1024 ? String(format: "%.1f KB", kb) : String(format: "%.2f MB", kb / 1024)
    }
}

// MARK: - Error detail sheet

private struct ErrorDetailView: View {
    let filename: String
    let error: Error
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.red)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Compression Failed")
                        .font(.headline)
                    Text(filename)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            // Error message
            ScrollView {
                Text(error.localizedDescription)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 220)

            Divider()

            // Footer
            HStack {
                Text("Tip: check that cwebp / avifenc are present in the app bundle.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Dismiss") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 420)
        .background(.ultraThinMaterial)
    }
}
