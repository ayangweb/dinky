import SwiftUI
import AppKit

struct PreferencesView: View {
    @EnvironmentObject var prefs: DinkyPreferences

    var body: some View {
        TabView {
            OutputTab()
                .tabItem { Label("Output", systemImage: "folder") }
                .environmentObject(prefs)
            BehaviorTab()
                .tabItem { Label("Behavior", systemImage: "gearshape") }
                .environmentObject(prefs)
        }
        .frame(width: 420, height: 280)
    }
}

// MARK: - Output tab

private struct OutputTab: View {
    @EnvironmentObject var prefs: DinkyPreferences

    var body: some View {
        Form {
            Section("Save Location") {
                Picker("Where to save", selection: Binding(
                    get: { prefs.saveLocation },
                    set: { prefs.saveLocation = $0 }
                )) {
                    Text("Same folder as original").tag(SaveLocation.sameFolder)
                    Text("Downloads folder").tag(SaveLocation.downloads)
                    Text("Custom folder…").tag(SaveLocation.custom)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()

                if prefs.saveLocation == .custom {
                    HStack {
                        Text(prefs.customFolderDisplayPath.isEmpty
                             ? "No folder selected" : prefs.customFolderDisplayPath)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Choose…") { pickCustomFolder() }
                            .buttonStyle(.bordered)
                    }
                }
            }

            Section("Filename") {
                Picker("Output name", selection: Binding(
                    get: { prefs.filenameHandling },
                    set: { prefs.filenameHandling = $0 }
                )) {
                    Text("Append \"-dinky\" suffix").tag(FilenameHandling.appendSuffix)
                    Text("Replace original").tag(FilenameHandling.replaceOrigin)
                    Text("Custom suffix").tag(FilenameHandling.customSuffix)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()

                if prefs.filenameHandling == .customSuffix {
                    HStack {
                        Text("Suffix")
                            .foregroundStyle(.secondary)
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
        .formStyle(.grouped)
        .padding(.top, 8)
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
            prefs.saveLocation = .custom
        }
    }
}

// MARK: - Behavior tab

private struct BehaviorTab: View {
    @EnvironmentObject var prefs: DinkyPreferences

    var body: some View {
        Form {
            Section("Compression") {
                Toggle("Skip already-optimized files", isOn: Binding(
                    get: { prefs.skipAlreadyOptimized },
                    set: { prefs.skipAlreadyOptimized = $0 }
                ))
                Text("Skips files where savings would be less than 2%.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("Preserve original timestamps", isOn: Binding(
                    get: { prefs.preserveTimestamps },
                    set: { prefs.preserveTimestamps = $0 }
                ))
            }

            Section("Sound") {
                Toggle("Play sound when done", isOn: Binding(
                    get: { prefs.playSoundEffects },
                    set: { prefs.playSoundEffects = $0 }
                ))
            }

            Section("Accessibility") {
                Toggle("Reduce motion", isOn: Binding(
                    get: { prefs.reduceMotion },
                    set: { prefs.reduceMotion = $0 }
                ))
                Text("Replaces the drop zone animation with a still arrangement of cards.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }
}
