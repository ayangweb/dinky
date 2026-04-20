import AppIntents

/// Surfaces Dinky’s Shortcuts actions in the Shortcuts app’s suggestions.
struct DinkyAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CompressImagesIntent(),
            phrases: [
                "Compress images with \(.applicationName)",
                "Optimize images in \(.applicationName)",
            ],
            shortTitle: LocalizedStringResource("Compress Images", comment: "Shortcuts: suggested action short title."),
            systemImageName: "photo.on.rectangle.angled"
        )
        AppShortcut(
            intent: CompressPDFIntent(),
            phrases: [
                "Compress PDFs with \(.applicationName)",
                "Shrink PDFs in \(.applicationName)",
            ],
            shortTitle: LocalizedStringResource("Compress PDFs", comment: "Shortcuts: suggested action short title."),
            systemImageName: "doc.richtext"
        )
        AppShortcut(
            intent: CompressVideoIntent(),
            phrases: [
                "Compress videos with \(.applicationName)",
                "Encode videos in \(.applicationName)",
            ],
            shortTitle: LocalizedStringResource("Compress Videos", comment: "Shortcuts: suggested action short title."),
            systemImageName: "film"
        )
    }
}
