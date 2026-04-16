import SwiftUI
import AppKit

struct PreferencesView: View {
    @EnvironmentObject var prefs: DinkyPreferences

    var body: some View {
        TabView {
            OutputTab()
                .tabItem { Label("Output", systemImage: "folder") }
            CompressionTab()
                .tabItem { Label("Compression", systemImage: "slider.horizontal.3") }
            BehaviorTab()
                .tabItem { Label("Behavior", systemImage: "gearshape") }
        }
        .environmentObject(prefs)
        .padding()
        .frame(width: 460, height: 320)
    }
}

// MARK: - Output tab

private struct OutputTab: View {
    @EnvironmentObject var prefs: DinkyPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                group("Save Location") {
                    Picker("", selection: Binding(
                        get: { prefs.saveLocation },
                        set: { prefs.saveLocation = $0 }
                    )) {
                        ForEach(SaveLocation.allCases) { loc in
                            Text(loc.displayName).tag(loc)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()

                    if prefs.saveLocation == .custom {
                        HStack {
                            Text(prefs.customFolderDisplayPath.isEmpty
                                 ? "No folder selected" : prefs.customFolderDisplayPath)
                                .foregroundStyle(.secondary)
                                .lineLimit(1).truncationMode(.middle)
                            Spacer()
                            Button("Choose…") { pickCustomFolder() }
                        }
                    }
                }

                group("Filename Handling") {
                    Picker("", selection: Binding(
                        get: { prefs.filenameHandling },
                        set: { prefs.filenameHandling = $0 }
                    )) {
                        ForEach(FilenameHandling.allCases) { h in
                            Text(h.displayName).tag(h)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()

                    if prefs.filenameHandling == .customSuffix {
                        HStack {
                            Text("Suffix:")
                            TextField("-dinky", text: Binding(
                                get: { prefs.customSuffix },
                                set: { prefs.customSuffix = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func pickCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            prefs.customFolderDisplayPath = url.path
            if let bookmark = try? url.bookmarkData(options: .withSecurityScope) {
                prefs.customFolderBookmark = bookmark
            }
        }
    }
}

// MARK: - Compression tab

private struct CompressionTab: View {
    @EnvironmentObject var prefs: DinkyPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                group("Metadata") {
                    Toggle("Strip metadata (Exif, GPS, XMP)", isOn: Binding(
                        get: { prefs.stripMetadata },
                        set: { prefs.stripMetadata = $0 }
                    ))
                    Toggle("Preserve file timestamps", isOn: Binding(
                        get: { prefs.preserveTimestamps },
                        set: { prefs.preserveTimestamps = $0 }
                    ))
                }
            }
            .padding()
        }
    }
}

// MARK: - Behavior tab

private struct BehaviorTab: View {
    @EnvironmentObject var prefs: DinkyPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                group("Processing") {
                    Toggle("Skip already-optimized files (< 2% savings)", isOn: Binding(
                        get: { prefs.skipAlreadyOptimized },
                        set: { prefs.skipAlreadyOptimized = $0 }
                    ))
                    Stepper(
                        "Concurrent tasks: \(prefs.concurrentTasks)",
                        value: Binding(
                            get: { prefs.concurrentTasks },
                            set: { prefs.concurrentTasks = $0 }
                        ),
                        in: 1...8
                    )
                }
                group("Feedback") {
                    Toggle("Play sound effects", isOn: Binding(
                        get: { prefs.playSoundEffects },
                        set: { prefs.playSoundEffects = $0 }
                    ))
                }
            }
            .padding()
        }
    }
}

// MARK: - Shared section header helper

private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.headline)
        content()
    }
}
