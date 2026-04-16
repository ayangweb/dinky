import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var prefs: DinkyPreferences
    @Binding var selectedFormat: CompressionFormat

    // Width presets: (label, px value)
    private let widthPresets: [(String, Int)] = [
        ("640 px", 640), ("1080 px", 1080), ("1280 px", 1280),
        ("1920 px", 1920), ("2560 px", 2560), ("3840 px", 3840)
    ]

    // File size presets: (label, KB value)
    private let sizePresets: [(String, Int)] = [
        ("0.5 MB", 512), ("1 MB", 1024), ("2 MB", 2048),
        ("5 MB", 5120), ("10 MB", 10240)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
        VStack(alignment: .leading, spacing: 10) {


            // ── Format ──────────────────────────────────────────
            sectionGroup(icon: "photo", title: "Format") {
                Picker("", selection: $selectedFormat) {
                    ForEach(CompressionFormat.allCases) { fmt in
                        Text(fmt.displayName).tag(fmt)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                helper("WebP works everywhere. AVIF is smaller but slower to encode.")
            }

            // ── Max Width ────────────────────────────────────────
            sectionGroup(icon: "arrow.left.and.right", title: "Max Width") {
                Toggle("Limit width", isOn: Binding(
                    get: { prefs.maxWidthEnabled },
                    set: { prefs.maxWidthEnabled = $0 }
                ))
                .toggleStyle(.switch)
                .font(.caption)

                if prefs.maxWidthEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        chipGrid(presets: widthPresets, current: prefs.maxWidth) {
                            prefs.maxWidth = $0
                        }

                        HStack(spacing: 6) {
                            TextField("1920", value: Binding(
                                get: { prefs.maxWidth },
                                set: { prefs.maxWidth = max(1, $0) }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            Text("px")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        helper("Common for web (1920), social (1280), and email (640).")
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // ── Max File Size ─────────────────────────────────────
            sectionGroup(icon: "gauge.medium", title: "Max File Size") {
                Toggle("Limit file size", isOn: Binding(
                    get: { prefs.maxFileSizeEnabled },
                    set: { prefs.maxFileSizeEnabled = $0 }
                ))
                .toggleStyle(.switch)
                .font(.caption)

                if prefs.maxFileSizeEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        chipGrid(presets: sizePresets, current: prefs.maxFileSizeKB) {
                            prefs.maxFileSizeKB = $0
                        }

                        HStack(spacing: 6) {
                            TextField("2", value: Binding(
                                get: { prefs.maxFileSizeMB },
                                set: { prefs.maxFileSizeMB = $0 }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            Text("MB")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        helper("Email typically caps at 1 MB. CMS and social platforms vary from 2–10 MB.")
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // ── Metadata ──────────────────────────────────────────
            sectionGroup(icon: "tag.slash", title: "Metadata") {
                Toggle("Strip metadata", isOn: Binding(
                    get: { prefs.stripMetadata },
                    set: { prefs.stripMetadata = $0 }
                ))
                .font(.caption)

                helper("Removes GPS, camera info, and copyright tags. Reduces file size slightly.")
            }
        }
        .padding(12)
        }
        .frame(width: 220)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: prefs.maxWidthEnabled)
        .animation(.easeInOut(duration: 0.2), value: prefs.maxFileSizeEnabled)
    }

    // MARK: - Chip grid (wraps automatically)

    private func chipGrid(
        presets: [(String, Int)],
        current: Int,
        onSelect: @escaping (Int) -> Void
    ) -> some View {
        let columns = [GridItem(.adaptive(minimum: 52), spacing: 4)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            ForEach(presets, id: \.1) { label, value in
                let active = current == value
                Button(label) { onSelect(value) }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: active ? .semibold : .regular))
                    .foregroundStyle(active ? .white : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(active
                                  ? AnyShapeStyle(LinearGradient(
                                        colors: [Color(red: 0.25, green: 0.55, blue: 1.0),
                                                 Color(red: 0.45, green: 0.30, blue: 0.95)],
                                        startPoint: .leading, endPoint: .trailing))
                                  : AnyShapeStyle(Color.primary.opacity(0.08)))
                    )
            }
        }
    }

    // MARK: - Helpers

    private func helper(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func sectionGroup<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.primary.opacity(0.05))
        )
    }
}
