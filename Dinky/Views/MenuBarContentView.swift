import SwiftUI
import UniformTypeIdentifiers

struct MenuBarContentView: View {
    @ObservedObject var vm: ContentViewModel
    @EnvironmentObject var prefs: DinkyPreferences
    @State private var isDropTargeted = false
    @State private var idleLoop = 0

    var body: some View {
        VStack(spacing: 0) {
            if vm.isEmpty {
                dropZone
            } else {
                recentResults
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Drop zone

    private var dropZone: some View {
        VStack(spacing: 0) {
            // Animation + labels — animation centered, labels below
            ZStack {
                // Labels render first (lower z) so animation cards float over them
                if !isDropTargeted {
                    VStack(spacing: 5) {
                        Text("Drop images here")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Button(action: { vm.pasteClipboard() }) {
                            Text("or paste (⌘⇧V)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .offset(y: 40)
                }

                // Animation on top so cards pass over the label text
                Group {
                    if prefs.reduceMotion {
                        StaticCardStack()
                    } else {
                        IdleAnimation(onLoop: { idleLoop += 1 }, landingOffset: CGSize(width: 0, height: -30))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                // Drop-hover overlay
                if isDropTargeted {
                    ZStack {
                        Color.accentColor.opacity(0.08)
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(Color.accentColor)
                            Text("Release to compress")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .contentShape(Rectangle())
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
            .animation(.easeInOut(duration: 0.15), value: isDropTargeted)

            // Footer — matches main app bottom bar style
            Text(S.dropIdle(loop: idleLoop))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .animation(.easeInOut, value: idleLoop)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            .adaptiveGlass(in: RoundedRectangle(cornerRadius: 0, style: .continuous))
        }
    }

    // MARK: - Results list

    private var recentResults: some View {
        VStack(spacing: 0) {
            List(vm.items.prefix(8), id: \.id) { item in
                ResultsRowView(item: item, selectedFormat: vm.selectedFormat)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.visible)
                    .listRowSeparatorTint(.primary.opacity(0.08))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            Divider()
            HStack {
                if !vm.isEmpty {
                    Button("Clear") { vm.clear() }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .buttonStyle(.plain)
                }
                Spacer()
                if vm.isProcessing {
                    ProgressView().scaleEffect(0.65)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .adaptiveGlass(in: RoundedRectangle(cornerRadius: 0, style: .continuous))
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
    }

    // MARK: - Drop handling

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        let lock = NSLock()
        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else { continue }
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                var resolved: URL?
                if let url = item as? URL { resolved = url }
                else if let url = item as? NSURL as URL? { resolved = url }
                else if let data = item as? Data { resolved = URL(dataRepresentation: data, relativeTo: nil) }
                guard let url = resolved else { return }
                let filtered = expandAndFilter(url)
                lock.lock(); urls.append(contentsOf: filtered); lock.unlock()
            }
        }
        group.notify(queue: .main) {
            guard !urls.isEmpty else { return }
            vm.addAndCompress(urls)
        }
        return true
    }

    private func expandAndFilter(_ url: URL) -> [URL] {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return [] }
        let urls: [URL] = isDir.boolValue
            ? (FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil)?
                .compactMap { $0 as? URL } ?? [])
            : [url]
        return urls.filter { ["jpg","jpeg","png","webp","avif","tiff","bmp"].contains($0.pathExtension.lowercased()) }
    }
}
