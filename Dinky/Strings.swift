// Strings.swift — all user-facing copy in one place

import Foundation

/// One row for Settings → Shortcuts and any in-app reference lists.
struct KeyboardShortcutReference: Identifiable {
    let title: String
    let keys: String
    var id: String { title }
}

extension Notification.Name {
    static let dinkyOpenPanel     = Notification.Name("dinkyOpenPanel")
    static let dinkyOpenFiles     = Notification.Name("dinkyOpenFiles")
    static let dinkyCheckUpdates  = Notification.Name("dinkyCheckUpdates")
    static let dinkyPasteClipboard  = Notification.Name("dinkyPasteClipboard")
    static let dinkyShowHistory     = Notification.Name("dinkyShowHistory")
    /// `object` is `PreferencesTab.rawValue` (Int)
    static let dinkySelectPreferencesTab = Notification.Name("dinkySelectPreferencesTab")
    static let dinkyClearAll            = Notification.Name("dinkyClearAll")
    static let dinkyToggleSidebar       = Notification.Name("dinkyToggleSidebar")
    static let dinkyDeleteSelectedRows  = Notification.Name("dinkyDeleteSelectedRows")
    static let dinkyStartCompression    = Notification.Name("dinkyStartCompression")
    /// Re-register the system-wide “Clipboard Compress” hotkey (toggle or shortcut changed).
    static let dinkyGlobalPasteHotkeyChanged = Notification.Name("dinkyGlobalPasteHotkeyChanged")
}

enum S {
    // Drop zone — idle taglines cycle with each animation loop
    static let dropIdleTaglines: [String] = [
        "Big in. Dinky out.",
        "Making your files dinky.",
        "Dinky does it.",
        "Big files. Dinky results.",
        "Think dinky.",
        "Drop big. Pick up dinky.",
        "Go on, get dinky.",
        "In big. Out dinky.",
        "Dinkify your files.",
        "Get dinky with it.",
        "Images, videos, PDFs — all dinky.",
    ]
    static func dropIdle(loop: Int) -> String {
        dropIdleTaglines[loop % dropIdleTaglines.count]
    }
    static let dropHover     = "Let go."

    // Processing
    static let processSingle = "On it."
    static let processBatch  = "Working through the pile."
    static let processBig    = "Big batch. Give me a moment."

    // Completion
    static let doneGood      = "Done. Look how little they are now."
    static let doneMixed     = "Done. Some were already pretty lean."

    // Per-file
    static let skipped       = "Already tiny. Skipped."
    static let errored       = "Couldn't crunch this one. Skipped."
    static let zeroBytes     = "Couldn't make this one any smaller. Keeping the original."

    // Buttons
    static func compressButton(_ n: Int) -> String {
        n == 1 ? "Compress 1 file" : "Compress \(n) files"
    }
    static let clear         = "Clear"

    // Preferences
    static let prefsTitle    = "Preferences"

    /// Settings › General › Behavior — global clipboard shortcut explainer (combo comes from `CustomShortcut.displayString`).
    static func behaviorPasteClipboardGlobalFootnote(currentShortcutDisplay: String) -> String {
        "Triggers Clipboard Compress from any app while Dinky is running (currently \(currentShortcutDisplay))."
    }

    /// Settings › General › Compression — parallel job cap (three tiers: 1, 3, or 8).
    /// Wording matches the marketing site (“Fast / Fastest”) with a middle **Faster** step.
    static let concurrentCompressionPickerLabel = "Batch speed"
    static let concurrentCompressionFootnote =
        "How many files crunch at once — not image, video, or PDF quality. Fast is gentle; Fastest clears the queue sooner if your Mac is up for it."

    static func concurrentCompressionTierOption(limit: Int) -> String {
        switch limit {
        case 1: return "Fast — one at a time, dinky zen"
        case 3: return "Faster — up to three in parallel"
        case 8: return "Fastest — up to eight, all cores welcome"
        default: return "Up to \(limit)"
        }
    }

    /// Plain label for assistive tech (menu text stays playful).
    static func concurrentCompressionAccessibilityLabel(limit: Int) -> String {
        switch limit {
        case 1: return "Up to one file compressing at a time"
        case 3: return "Up to three files compressing at a time"
        case 8: return "Up to eight files compressing at a time"
        default: return "Up to \(limit) files compressing at a time"
        }
    }

    // Format names
    static let webp = "WebP"
    static let avif = "AVIF"
    static let png  = "PNG"

    /// Shown in About, Settings, and linked with `mailto:`.
    static let supportEmail = "help@dinkyfiles.com"

    // Paste from clipboard
    static let pasteEmptyTitle = "Nothing to paste"
    static let pasteEmptyMessage = "Copy a supported file in Finder, or copy an image (PNG or TIFF), then try again."
    static let pasteDuplicateTitle = "Already in the list"
    static let pasteDuplicateMessage = "That file is already queued — drop something new or clear the list first."

    // Settings → Shortcuts (keep in sync with `DinkyApp` menu commands + standard Help / Settings)
    static let shortcutsTabServicesFooter =
        "Assign shortcuts for Finder’s “Compress with Dinky” in System Settings → Keyboard → Keyboard Shortcuts → Services."
    static var shortcutsTabHelpFooter: String {
        let k = DinkyFixedShortcut.dinkyHelp.shortcut.displayString
        return "For watch folders, presets, and full troubleshooting, open Dinky Help from the Help menu (\(k))."
    }
    static let shortcutsAppDescription =
        "Dinky exposes a Compress Images action to the Shortcuts app. Use it to pipe files from Finder or other actions through Dinky with a chosen format — same engine as in-app compression (Smart quality, resize, and metadata follow Settings)."

    static let shortcutsCustomizableHeader = "Customize"
    static let shortcutsFixedHeader = "System & help"
    static let shortcutsResetAll = "Reset All Shortcuts"
    static let shortcutsResetRow = "Reset"
    static let shortcutsEdit = "Edit"
    static let shortcutsCancelEdit = "Cancel"
    static let shortcutsRecorderPrompt = "Press a key…"
    /// Inline hint shown beneath the recorder while it’s listening.
    static let shortcutsRecorderHint = "Press a combo to save · Esc to cancel · Delete to reset"
    static let shortcutsConflictPrefix = "Already used by"
    static let shortcutsSystemWarningPrefix = "Overrides macOS:"

    /// Non-customizable menu items (matches `DinkyFixedShortcut` + system Settings).
    static var fixedMenuShortcutReference: [KeyboardShortcutReference] {
        DinkyFixedShortcut.allCases.map {
            KeyboardShortcutReference(title: $0.title, keys: $0.shortcut.displayString)
        }
    }
}
