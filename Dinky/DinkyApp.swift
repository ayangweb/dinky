import SwiftUI
import AppKit

@main
struct DinkyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var prefs = DinkyPreferences()

    var body: some Scene {
        WindowGroup {
            ContentView(prefs: prefs)
                .environmentObject(prefs)
                .background(.ultraThinMaterial)        // frosted glass fill
                .background(TransparentWindow())       // makes NSWindow itself see-through
                .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 640, height: 520)
        .defaultWindowPlacement { _, context in
            let display = context.defaultDisplay
            let center  = CGPoint(x: display.visibleRect.midX, y: display.visibleRect.midY)
            return WindowPlacement(center)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Images…") {
                    NotificationCenter.default.post(name: .dinkyOpenPanel, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }

        Settings {
            PreferencesView()
                .environmentObject(prefs)
        }
    }
}

// Reaches into the hosting NSWindow and clears its background so the
// SwiftUI .ultraThinMaterial above can show the blur/vibrancy through.
private struct TransparentWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // Defer until the view is in the window hierarchy
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
    }
}
