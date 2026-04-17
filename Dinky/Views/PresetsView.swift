import SwiftUI

struct PresetsView: View {
    @EnvironmentObject var prefs: DinkyPreferences
    @Binding var selectedFormat: CompressionFormat
    @State private var editingID: UUID? = nil
    @State private var editingName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if prefs.savedPresets.isEmpty {
                Text("No presets saved yet.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(prefs.savedPresets) { preset in
                    presetRow(preset)
                }
            }

            Button {
                saveCurrentAsPreset()
            } label: {
                Label("Save current settings", systemImage: "plus")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    private func presetRow(_ preset: CompressionPreset) -> some View {
        HStack(spacing: 6) {
            if editingID == preset.id {
                TextField("Name", text: $editingName, onCommit: { commitRename(preset) })
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11))
                    .onExitCommand { editingID = nil }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text(preset.name)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                    Text(preset.autoFormat ? "Auto" : preset.format.displayName)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    editingID = preset.id
                    editingName = preset.name
                }
            }

            Spacer()

            Button {
                var fmt = selectedFormat
                preset.apply(to: prefs, selectedFormat: &fmt)
                selectedFormat = fmt
            } label: {
                Text("Apply")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)

            Button {
                deletePreset(preset)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    private func saveCurrentAsPreset() {
        let count = prefs.savedPresets.count + 1
        let preset = CompressionPreset(name: "Preset \(count)", from: prefs, format: selectedFormat)
        var presets = prefs.savedPresets
        presets.append(preset)
        prefs.savedPresets = presets
        // Start editing the name immediately
        editingID = preset.id
        editingName = preset.name
    }

    private func commitRename(_ preset: CompressionPreset) {
        guard !editingName.trimmingCharacters(in: .whitespaces).isEmpty else {
            editingID = nil; return
        }
        var presets = prefs.savedPresets
        if let idx = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[idx].name = editingName.trimmingCharacters(in: .whitespaces)
        }
        prefs.savedPresets = presets
        editingID = nil
    }

    private func deletePreset(_ preset: CompressionPreset) {
        if prefs.activePresetID == preset.id.uuidString { prefs.activePresetID = "" }
        prefs.savedPresets = prefs.savedPresets.filter { $0.id != preset.id }
    }
}
