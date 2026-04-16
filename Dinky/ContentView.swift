import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var items: [ImageItem] = []
    @Published var isProcessing = false
    @Published var phase: DropZonePhase = .idle

    var selectedFormat: CompressionFormat
    let prefs: DinkyPreferences

    init(prefs: DinkyPreferences) {
        self.prefs = prefs
        self.selectedFormat = prefs.defaultFormat
    }

    var isEmpty: Bool { items.isEmpty }

    func addAndCompress(_ urls: [URL]) {
        let new = urls.map { ImageItem(sourceURL: $0) }
        items.append(contentsOf: new)
        compress()
    }

    func clear() {
        items = []
        phase = .idle
    }

    // MARK: - Compress

    func compress() {
        guard !isProcessing else { return }
        isProcessing = true
        phase = .processing

        let pending = items.filter { if case .pending = $0.status { return true }; return false }
        let goals   = CompressionGoals(
            maxWidth:      prefs.maxWidthEnabled     ? prefs.maxWidth      : nil,
            maxFileSizeKB: prefs.maxFileSizeEnabled  ? prefs.maxFileSizeKB : nil
        )

        Task {
            await withTaskGroup(of: Void.self) { group in
                let sem = AsyncSemaphore(limit: prefs.concurrentTasks)
                for item in pending {
                    await sem.wait()
                    group.addTask { [weak self] in
                        defer { Task { await sem.signal() } }
                        await self?.compressItem(item, goals: goals)
                    }
                }
            }
            await MainActor.run {
                self.isProcessing = false
                self.phase = .done
                if self.prefs.playSoundEffects { self.playCompletionSound() }
            }
        }
    }

    private func compressItem(_ item: ImageItem, goals: CompressionGoals) async {
        await MainActor.run { item.status = .processing }
        let outputURL = prefs.outputURL(for: item.sourceURL, format: selectedFormat)
        do {
            let result = try await CompressionService.shared.compress(
                source: item.sourceURL,
                format: selectedFormat,
                goals: goals,
                stripMetadata: prefs.stripMetadata,
                outputURL: outputURL
            )
            let savings = result.originalSize > 0
                ? Double(result.originalSize - result.outputSize) / Double(result.originalSize) : 0
            await MainActor.run {
                if result.outputSize >= result.originalSize {
                    item.status = .zeroGain(original: item.sourceURL)
                    try? FileManager.default.removeItem(at: result.outputURL)
                } else if self.prefs.skipAlreadyOptimized && savings < 0.02 {
                    item.status = .skipped
                    try? FileManager.default.removeItem(at: result.outputURL)
                } else {
                    item.status = .done(outputURL: result.outputURL,
                                        originalSize: result.originalSize,
                                        outputSize: result.outputSize)
                    if self.prefs.filenameHandling == .replaceOrigin {
                        try? FileManager.default.trashItem(at: item.sourceURL, resultingItemURL: nil)
                    }
                    if self.prefs.preserveTimestamps {
                        copyTimestamp(from: item.sourceURL, to: result.outputURL)
                    }
                }
            }
        } catch {
            await MainActor.run { item.status = .failed(error) }
        }
    }

    private func copyTimestamp(from source: URL, to dest: URL) {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: source.path),
              let date = attrs[.modificationDate] as? Date else { return }
        try? FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: dest.path)
    }

    private func playCompletionSound() {
        let sr = 44100.0, dur = 0.35
        let fc = AVAudioFrameCount(sr * dur)
        let engine = AVAudioEngine(); let player = AVAudioPlayerNode()
        engine.attach(player)
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
        guard let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: fc) else { return }
        buf.frameLength = fc
        let d = buf.floatChannelData![0]
        for i in 0..<Int(fc) {
            let t = Double(i) / sr
            d[i] = Float(max(0, 1 - t/dur)) * 0.22 * Float(sin(2 * .pi * (600 - 300*(t/dur)) * t))
        }
        engine.connect(player, to: engine.mainMixerNode, format: fmt)
        try? engine.start(); player.scheduleBuffer(buf); player.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + dur + 0.1) { engine.stop() }
    }
}

// MARK: - AsyncSemaphore

private actor AsyncSemaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    init(limit: Int) { count = limit }
    func wait() async {
        if count > 0 { count -= 1; return }
        await withCheckedContinuation { waiters.append($0) }
    }
    func signal() {
        if waiters.isEmpty { count += 1 } else { waiters.removeFirst().resume() }
    }
}

// MARK: - Root view

struct ContentView: View {
    @EnvironmentObject var prefs: DinkyPreferences
    @StateObject private var vm: ContentViewModel
    @State private var sidebarVisible = false
    @State private var isDropTargeted  = false
    @State private var idleLoop        = 0

    init(prefs: DinkyPreferences) {
        _vm = StateObject(wrappedValue: ContentViewModel(prefs: prefs))
    }

    // Merge hover state with the vm phase so DropZoneView stays purely visual
    private var dropPhase: DropZonePhase {
        if isDropTargeted { return .hovering }
        return vm.phase
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // ── Main content (drop target covers the full surface) ──
            VStack(spacing: 0) {
                if vm.isEmpty {
                    DropZoneView(phase: dropPhase, onOpenPanel: openPanel, onLoop: { idleLoop += 1 })
                } else {
                    resultsList
                }
                bottomBar
            }
            // Drop handler lives here, above the sidebar, so the overlay can't block it
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)

            // ── Floating sidebar (top-aligned, height = content only) ──
            if sidebarVisible {
                GeometryReader { geo in
                    VStack {
                        SidebarView(selectedFormat: Binding(
                            get:  { vm.selectedFormat },
                            set:  { vm.selectedFormat = $0 }
                        ))
                        .environmentObject(prefs)
                        .frame(maxHeight: geo.size.height - 60)
                        Spacer()
                    }
                    .padding(12)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .frame(minWidth: 440, minHeight: 440)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(.spring(duration: 0.35)) { sidebarVisible.toggle() }
                } label: {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                        .symbolVariant(sidebarVisible ? .fill : .none)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dinkyOpenPanel)) { _ in openPanel() }
        .onReceive(NotificationCenter.default.publisher(for: .dinkyOpenFiles)) { note in
            guard let urls = note.object as? [URL] else { return }
            vm.addAndCompress(urls)
        }
    }

    // MARK: - Results list

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(vm.items) { item in
                    ResultsRowView(item: item)
                    if item.id != vm.items.last?.id {
                        Divider().padding(.horizontal, 14)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        ZStack {
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .animation(.easeInOut, value: vm.phase)

            if !vm.isEmpty {
                HStack {
                    Spacer()
                    Button("Clear") { vm.clear() }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(in: RoundedRectangle(cornerRadius: 0, style: .continuous))
    }

    private var statusText: String {
        switch vm.phase {
        case .idle:       return S.dropIdle(loop: idleLoop)
        case .hovering:   return S.dropHover
        case .processing: return vm.items.count >= 10 ? S.processBig : S.processBatch
        case .done:
            let skipped = vm.items.filter {
                if case .skipped  = $0.status { return true }
                if case .zeroGain = $0.status { return true }
                return false
            }.count
            let done = vm.items.filter { if case .done = $0.status { return true }; return false }.count
            return (skipped > 0 && done > 0) ? S.doneMixed : S.doneGood
        }
    }

    // MARK: - Drop handling (reliable macOS URL extraction)

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var collected: [URL] = []
        let group = DispatchGroup()
        let lock  = NSLock()

        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else { continue }
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                var resolved: URL?
                if let url  = item as? URL  { resolved = url }
                else if let url = item as? NSURL as URL? { resolved = url }
                else if let data = item as? Data { resolved = URL(dataRepresentation: data, relativeTo: nil) }
                guard let url = resolved else { return }
                let files = expandAndFilter(url)
                lock.lock(); collected.append(contentsOf: files); lock.unlock()
            }
        }

        group.notify(queue: .main) {
            guard !collected.isEmpty else { return }
            vm.addAndCompress(collected)
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

    // MARK: - Open panel

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories    = true
        panel.allowedContentTypes     = [.jpeg, .png, .webP, .image]
        if panel.runModal() == .OK {
            vm.addAndCompress(panel.urls)
        }
    }
}
