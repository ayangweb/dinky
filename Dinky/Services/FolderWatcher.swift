import Foundation

final class FolderWatcher: ObservableObject {
    var onNewFiles: (([URL]) -> Void)?
    private var stream: FSEventStreamRef?
    private let imageExtensions = Set(["jpg", "jpeg", "png", "webp", "avif", "tiff", "bmp"])

    func start(at path: String) {
        stop()
        let retained = Unmanaged.passRetained(self).toOpaque()
        var ctx = FSEventStreamContext(version: 0, info: retained,
                                       retain: nil, release: nil, copyDescription: nil)
        let callback: FSEventStreamCallback = { _, info, numEvents, eventPaths, eventFlags, _ in
            let watcher = Unmanaged<FolderWatcher>.fromOpaque(info!).takeUnretainedValue()
            guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }
            let imageExts = watcher.imageExtensions
            let now = Date()
            let urls = paths
                .map { URL(fileURLWithPath: $0) }
                .filter { imageExts.contains($0.pathExtension.lowercased()) }
                .filter { url in
                    // Only pick up files written in the last 10 seconds to avoid re-processing existing files on start
                    guard let created = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate else { return false }
                    return now.timeIntervalSince(created) < 10
                }
            guard !urls.isEmpty else { return }
            DispatchQueue.main.async { watcher.onNewFiles?(urls) }
        }

        stream = FSEventStreamCreate(
            nil, callback, &ctx,
            [path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.5,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)
        )
        guard let stream else { Unmanaged<FolderWatcher>.fromOpaque(retained).release(); return }
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    deinit { stop() }
}
