import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var eventMonitor: Any?

    func enable(vm: ContentViewModel, prefs: DinkyPreferences) {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            let img = NSImage(named: "MenuBarIcon")
            img?.isTemplate = true
            img?.size = NSSize(width: 18, height: 18)
            button.image = img
            button.imageScaling = .scaleNone
            button.action = #selector(togglePanel(_:))
            button.target = self
        }

        let content = MenuBarContentView(vm: vm).environmentObject(prefs)
        let host = NSHostingController(rootView: content)
        host.view.frame = NSRect(x: 0, y: 0, width: 320, height: 310)

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 310),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isFloatingPanel = true
        p.level = .popUpMenu
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.contentViewController = host
        panel = p

        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closePanel()
        }
    }

    func disable() {
        closePanel()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        panel = nil
        statusItem = nil
    }

    @objc private func togglePanel(_ sender: NSStatusBarButton) {
        guard let panel else { return }
        if panel.isVisible { closePanel() } else { openPanel() }
    }

    private func openPanel() {
        guard let panel, let button = statusItem?.button,
              let buttonWindow = button.window else { return }

        let buttonFrame = buttonWindow.convertToScreen(button.frame)
        var origin = CGPoint(
            x: buttonFrame.midX - panel.frame.width / 2,
            y: buttonFrame.minY - panel.frame.height - 4
        )

        if let screen = NSScreen.main {
            let vf = screen.visibleFrame
            origin.x = max(vf.minX + 4, min(origin.x, vf.maxX - panel.frame.width - 4))
        }

        panel.setFrameOrigin(origin)
        panel.makeKeyAndOrderFront(nil)
    }

    private func closePanel() {
        panel?.orderOut(nil)
    }
}
