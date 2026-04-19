import AppKit
import Foundation
import SwiftUI

// MARK: - Action + storage model

enum ShortcutAction: String, CaseIterable, Identifiable {
    case openFiles
    case pasteClipboard
    case compressNow
    case clearAll
    case deleteSelected

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openFiles: return "Open Files…"
        case .pasteClipboard: return "Clipboard Compress"
        case .compressNow: return "Compress Now"
        case .clearAll: return "Clear All"
        case .deleteSelected: return "Delete Selected"
        }
    }

    var defaultShortcut: CustomShortcut {
        switch self {
        case .openFiles:
            return CustomShortcut(key: "o", modifiers: .command)
        case .pasteClipboard:
            return CustomShortcut(key: "v", modifiers: [.command, .shift])
        case .compressNow:
            return CustomShortcut(key: "return", modifiers: .command)
        case .clearAll:
            return CustomShortcut(key: "k", modifiers: [.command, .option])
        case .deleteSelected:
            return CustomShortcut(key: "delete", modifiers: .command)
        }
    }
}

/// Fixed Dinky menu shortcuts (not user-customizable). Must stay in sync with `DinkyApp` / system conventions.
enum DinkyFixedShortcut {
    case toggleSidebar
    case dinkyHelp
    case settings

    var title: String {
        switch self {
        case .toggleSidebar: return "Toggle Sidebar"
        case .dinkyHelp: return "Dinky Help"
        case .settings: return "Settings"
        }
    }

    var shortcut: CustomShortcut {
        switch self {
        case .toggleSidebar:
            return CustomShortcut(key: "\\", modifiers: [.command, .shift])
        case .dinkyHelp:
            return CustomShortcut(key: "?", modifiers: [.command, .shift])
        case .settings:
            return CustomShortcut(key: ",", modifiers: .command)
        }
    }

    static let allCases: [DinkyFixedShortcut] = [.toggleSidebar, .dinkyHelp, .settings]
}

// MARK: - CustomShortcut

struct CustomShortcut: Codable, Equatable, Hashable {
    /// Single character, or a named key: `return`, `delete`, `deleteForward`, `tab`, `escape`, `space`, or punctuation like `\\`, `,`, `?`.
    var key: String
    /// `NSEvent.ModifierFlags` raw value, masked to device-independent modifier keys only.
    var modifiers: UInt

    init(key: String, modifiers: NSEvent.ModifierFlags) {
        self.key = key
        self.modifiers = Self.normalizeModifiers(modifiers.rawValue)
    }

    init(key: String, modifiers: UInt) {
        self.key = key
        self.modifiers = Self.normalizeModifiers(modifiers)
    }

    static func normalizeModifiers(_ raw: UInt) -> UInt {
        NSEvent.ModifierFlags(rawValue: raw)
            .intersection(.deviceIndependentFlagsMask)
            .intersection([.command, .shift, .option, .control])
            .rawValue
    }

    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers)
    }

    var eventModifiers: EventModifiers {
        var em = EventModifiers()
        let m = modifierFlags
        if m.contains(.command) { em.insert(.command) }
        if m.contains(.shift) { em.insert(.shift) }
        if m.contains(.option) { em.insert(.option) }
        if m.contains(.control) { em.insert(.control) }
        return em
    }

    /// SwiftUI menu / button shortcut.
    var swiftUIKeyboardShortcut: KeyboardShortcut {
        let em = eventModifiers
        switch key {
        case "return":
            return KeyboardShortcut(.return, modifiers: em)
        case "delete":
            return KeyboardShortcut(.delete, modifiers: em)
        case "deleteForward":
            return KeyboardShortcut(.deleteForward, modifiers: em)
        case "tab":
            return KeyboardShortcut(.tab, modifiers: em)
        case "escape":
            return KeyboardShortcut(.escape, modifiers: em)
        case "space":
            return KeyboardShortcut(.space, modifiers: em)
        case "upArrow":
            return KeyboardShortcut(.upArrow, modifiers: em)
        case "downArrow":
            return KeyboardShortcut(.downArrow, modifiers: em)
        case "leftArrow":
            return KeyboardShortcut(.leftArrow, modifiers: em)
        case "rightArrow":
            return KeyboardShortcut(.rightArrow, modifiers: em)
        default:
            guard let ch = key.first else {
                return KeyboardShortcut(.init("?"), modifiers: em)
            }
            return KeyboardShortcut(KeyEquivalent(ch), modifiers: em)
        }
    }

    /// Human-readable combo like `⌘⇧V` for keycaps / tooltips.
    var displayString: String {
        var s = ""
        let m = modifierFlags
        if m.contains(.control) { s += "⌃" }
        if m.contains(.option) { s += "⌥" }
        if m.contains(.shift) { s += "⇧" }
        if m.contains(.command) { s += "⌘" }
        s += keyDisplaySymbol
        return s
    }

    private var keyDisplaySymbol: String {
        switch key {
        case "return": return "↩"
        case "delete", "deleteForward": return "⌫"
        case "tab": return "⇥"
        case "escape": return "⎋"
        case "space": return "Space"
        case "upArrow": return "↑"
        case "downArrow": return "↓"
        case "leftArrow": return "←"
        case "rightArrow": return "→"
        case "\\": return "\\"
        case ",": return ","
        default:
            if key.count == 1, let c = key.first {
                if c.isLetter { return String(c).uppercased() }
                return String(c)
            }
            return key
        }
    }

    /// Builds from a local key-down event. Requires Command; ignores modifier-only events.
    static func from(event: NSEvent) -> CustomShortcut? {
        guard event.type == .keyDown else { return nil }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command) else { return nil }

        let mods = Self.normalizeModifiers(flags.rawValue)

        switch event.keyCode {
        case 36: // Return
            return CustomShortcut(key: "return", modifiers: mods)
        case 48: // Tab
            return CustomShortcut(key: "tab", modifiers: mods)
        case 51: // Backspace — maps to SwiftUI `.delete`
            return CustomShortcut(key: "delete", modifiers: mods)
        case 117: // Forward delete
            return CustomShortcut(key: "deleteForward", modifiers: mods)
        case 53: // Escape
            return CustomShortcut(key: "escape", modifiers: mods)
        case 49: // Space
            return CustomShortcut(key: "space", modifiers: mods)
        case 123: return CustomShortcut(key: "leftArrow", modifiers: mods)
        case 124: return CustomShortcut(key: "rightArrow", modifiers: mods)
        case 125: return CustomShortcut(key: "downArrow", modifiers: mods)
        case 126: return CustomShortcut(key: "upArrow", modifiers: mods)
        default:
            break
        }

        guard let ch = event.charactersIgnoringModifiers?.first else { return nil }
        let lower = String(ch).lowercased()
        guard let first = lower.first else { return nil }

        // Control / non-printing
        if first.isNewline || first == "\t" { return nil }

        if first.isLetter || first.isNumber {
            return CustomShortcut(key: String(first), modifiers: mods)
        }

        // Punctuation paths (modifiers may alter what's in charactersIgnoringModifiers)
        return CustomShortcut(key: String(first), modifiers: mods)
    }
}

// MARK: - Conflicts

enum ShortcutConflict: Equatable {
    /// Another Dinky command already uses this combo.
    case internalCollision(otherTitle: String)
    /// Known macOS / app convention — allowed but warned.
    case systemReserved(name: String)
}

enum ShortcutValidator {

    /// Ordered list of well-known system / cross-app shortcuts (⌘Q, ⌘W, …). Not exhaustive.
    private static let reservedSystemShortcuts: [(combo: CustomShortcut, name: String)] = [
        (CustomShortcut(key: "q", modifiers: .command), "Quit App"),
        (CustomShortcut(key: "w", modifiers: .command), "Close Window"),
        (CustomShortcut(key: "m", modifiers: .command), "Minimize"),
        (CustomShortcut(key: "h", modifiers: .command), "Hide App"),
        (CustomShortcut(key: "n", modifiers: .command), "New"),
        (CustomShortcut(key: "t", modifiers: .command), "New Tab"),
        (CustomShortcut(key: "z", modifiers: .command), "Undo"),
        (CustomShortcut(key: "z", modifiers: [.command, .shift]), "Redo"),
        (CustomShortcut(key: "c", modifiers: .command), "Copy"),
        (CustomShortcut(key: "x", modifiers: .command), "Cut"),
        (CustomShortcut(key: "v", modifiers: .command), "Paste"),
        (CustomShortcut(key: "a", modifiers: .command), "Select All"),
        (CustomShortcut(key: "f", modifiers: .command), "Find"),
        (CustomShortcut(key: "g", modifiers: .command), "Find Next"),
        (CustomShortcut(key: "g", modifiers: [.command, .shift]), "Find Previous"),
        (CustomShortcut(key: "p", modifiers: .command), "Print"),
        (CustomShortcut(key: "s", modifiers: .command), "Save"),
        (CustomShortcut(key: "i", modifiers: .command), "Get Info"),
        (CustomShortcut(key: "o", modifiers: [.command, .shift]), "Open in New Window"),
        (CustomShortcut(key: "space", modifiers: .command), "Spotlight"),
        (CustomShortcut(key: "space", modifiers: .control), "Input Sources / Emoji"),
        (CustomShortcut(key: "tab", modifiers: .command), "App Switcher"),
        (CustomShortcut(key: "`", modifiers: .command), "Cycle Windows"),
    ]

    static func conflict(
        for shortcut: CustomShortcut,
        assigningTo action: ShortcutAction,
        in prefs: DinkyPreferences
    ) -> ShortcutConflict? {
        if prefs.shortcut(for: action) == shortcut {
            return nil
        }

        for other in ShortcutAction.allCases where other != action {
            if prefs.shortcut(for: other) == shortcut {
                return .internalCollision(otherTitle: other.title)
            }
        }

        for fixed in DinkyFixedShortcut.allCases {
            if fixed.shortcut == shortcut {
                return .internalCollision(otherTitle: fixed.title)
            }
        }

        if let hit = reservedSystemShortcuts.first(where: { $0.combo == shortcut }) {
            return .systemReserved(name: hit.name)
        }

        return nil
    }

    /// Whether the current binding should show the yellow “overrides macOS” affordance (persisted shortcut only).
    static func systemWarning(for shortcut: CustomShortcut) -> String? {
        reservedSystemShortcuts.first(where: { $0.combo == shortcut })?.name
    }
}
