import SwiftUI
import AppKit

enum DropZonePhase: Equatable {
    case idle, hovering, processing, done
}

struct DropZoneView: View {
    var phase: DropZonePhase
    let onOpenPanel: () -> Void
    var onLoop: () -> Void = {}

    @EnvironmentObject var prefs: DinkyPreferences
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var shouldReduceMotion: Bool { prefs.reduceMotion || systemReduceMotion }

    @State private var doneFlash      = false
    @State private var ringScale      : CGFloat = 1.0
    @State private var ringOpacity    : Double  = 0.5
    @State private var sparkleScale   : CGFloat = 0
    @State private var sparkleOpacity : Double  = 0

    var body: some View {
        ZStack {
            // Content sits beneath the animation so cards pass over the label
            VStack(spacing: 18) {
                if phase != .idle { symbolView }
                labelView
            }

            // Idle animation floats on top
            if phase == .idle {
                if shouldReduceMotion {
                    StaticCardStack()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    IdleAnimation(onLoop: onLoop)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onOpenPanel() }
        .onChange(of: phase) { _, new in
            if new == .done { doneFlash.toggle(); triggerSparkles() }
        }
    }

    @ViewBuilder
    private var symbolView: some View {
        switch phase {
        case .idle:
            EmptyView() // handled by background layer above

        case .hovering:
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.18), lineWidth: 1.5)
                    .frame(width: 144, height: 144)
                    .scaleEffect(ringScale).opacity(ringOpacity)
                Circle()
                    .stroke(Color.accentColor.opacity(0.28), lineWidth: 1.5)
                    .frame(width: 110, height: 110)
                    .scaleEffect(ringScale).opacity(ringOpacity)
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.28, green: 0.56, blue: 1.0),
                                 Color(red: 0.52, green: 0.28, blue: 0.96)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.accentColor.opacity(0.45), radius: 18, x: 0, y: 6)
                Image(systemName: "arrow.down")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, options: .repeating.speed(0.65))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                    ringScale = 1.12; ringOpacity = 0.12
                }
            }

        case .processing:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 52, weight: .ultraLight))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.rotate, options: .repeating)

        case .done:
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    let angle = Double(i) * 60 * (.pi / 180)
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(sparkleColors[i % sparkleColors.count])
                        .offset(x: CGFloat(cos(angle)) * 54 * sparkleScale,
                                y: CGFloat(sin(angle)) * 54 * sparkleScale)
                        .scaleEffect(sparkleScale > 0 ? 1 : 0.1)
                        .opacity(sparkleOpacity)
                }
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52, weight: .ultraLight))
                    .foregroundStyle(Color.green)
                    .symbolEffect(.bounce, value: doneFlash)
            }
        }
    }

    private let sparkleColors: [Color] = [.yellow, .orange, .pink, .purple, .cyan, .green]

    @ViewBuilder
    private var labelView: some View {
        switch phase {
        case .idle:
            VStack(spacing: 5) {
                Text("Drop images here")
                    .font(.title3).foregroundStyle(.primary)
                Text("or click to browse")
                    .font(.caption).foregroundStyle(.secondary)
            }
        case .hovering:
            Text("Release to compress")
                .font(.title3.weight(.semibold)).foregroundStyle(.white)
                .padding(.horizontal, 18).padding(.vertical, 8)
                .background(
                    Capsule().fill(LinearGradient(
                        colors: [Color(red: 0.28, green: 0.56, blue: 1.0),
                                 Color(red: 0.52, green: 0.28, blue: 0.96)],
                        startPoint: .leading, endPoint: .trailing))
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 4))
        case .processing:
            Text("Compressing…").font(.title3).foregroundStyle(.secondary)
        case .done:
            Text("All done!").font(.title3.weight(.medium)).foregroundStyle(Color.green)
        }
    }

    private func triggerSparkles() {
        sparkleScale = 0; sparkleOpacity = 1
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { sparkleScale = 1 }
        withAnimation(.easeOut(duration: 0.55).delay(0.3))             { sparkleOpacity = 0 }
    }
}

// MARK: - Idle drag animation

// MARK: - Static card stack (reduce motion)

private struct StaticCardStack: View {
    private let themes: [(Color, Color)] = [
        (Color(red: 0.28, green: 0.56, blue: 1.00), Color(red: 0.52, green: 0.28, blue: 0.96)),
        (Color(red: 0.96, green: 0.42, blue: 0.28), Color(red: 0.98, green: 0.74, blue: 0.18)),
        (Color(red: 0.18, green: 0.78, blue: 0.52), Color(red: 0.14, green: 0.62, blue: 0.88)),
    ]

    private func card(_ themeIndex: Int, width: CGFloat, height: CGFloat) -> some View {
        let (c1, c2) = themes[themeIndex]
        return RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: width, height: height)
            .shadow(color: c1.opacity(0.35), radius: 6, x: 0, y: 3)
    }

    var body: some View {
        ZStack {
            // wide landscape — back
            card(2, width: 68, height: 40)
                .offset(x: 20, y: -72)
                .rotationEffect(.degrees(7))
            // landscape — middle
            card(1, width: 64, height: 42)
                .offset(x: 0, y: -82)
                .rotationEffect(.degrees(2))
            // portrait — front
            card(0, width: 42, height: 56)
                .offset(x: -20, y: -74)
                .rotationEffect(.degrees(-6))
        }
    }
}

// MARK: - Animated idle

private struct IdleAnimation: View {

    var onLoop: () -> Void = {}

    @State private var animationID  : UUID    = UUID()
    @State private var finished     : Bool    = false
    @State private var viewSize     : CGSize  = CGSize(width: 440, height: 380)
    @State private var cursorOffset : CGSize  = .zero
    @State private var cursorLifted : Bool    = false
    @State private var card1Offset  : CGSize  = .zero
    @State private var card2Offset  : CGSize  = .zero
    @State private var card3Offset  : CGSize  = .zero
    @State private var card1Angle   : Double  = 0
    @State private var card2Angle   : Double  = 0
    @State private var card3Angle   : Double  = 0
    @State private var card1Opacity : Double  = 0
    @State private var card2Opacity : Double  = 0
    @State private var card3Opacity : Double  = 0
    @State private var entryCorner  : Corner  = .bottomRight
    @State private var step         : Int     = 0

    // Captured at loop start so theme never changes mid-animation or on re-render
    @State private var activeTheme1 : Int     = 0
    @State private var activeTheme2 : Int     = 2
    @State private var activeTheme3 : Int     = 4

    private let themes: [(Color, Color)] = [
        (Color(red: 0.28, green: 0.56, blue: 1.00), Color(red: 0.52, green: 0.28, blue: 0.96)),
        (Color(red: 0.96, green: 0.42, blue: 0.28), Color(red: 0.98, green: 0.74, blue: 0.18)),
        (Color(red: 0.18, green: 0.78, blue: 0.52), Color(red: 0.14, green: 0.62, blue: 0.88)),
        (Color(red: 0.96, green: 0.30, blue: 0.54), Color(red: 0.98, green: 0.56, blue: 0.28)),
        (Color(red: 0.44, green: 0.28, blue: 0.96), Color(red: 0.22, green: 0.68, blue: 0.98)),
    ]

    private var cardCount   : Int { step % 2 == 0 ? 2 : 1 }
    private var animStyle   : Int { step % 3 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // card3 — wide landscape (back layer, third trip only)
                photoCard(themeIndex: activeTheme3, width: 68, height: 40)
                    .offset(card3Offset)
                    .rotationEffect(.degrees(card3Angle))
                    .opacity(card3Opacity)

                // card2 — landscape (wider)
                photoCard(themeIndex: activeTheme2, width: 64, height: 42)
                    .offset(card2Offset)
                    .rotationEffect(.degrees(card2Angle))
                    .opacity(card2Opacity)

                // card1 — portrait (taller)
                photoCard(themeIndex: activeTheme1, width: 42, height: 56)
                    .offset(card1Offset)
                    .rotationEffect(.degrees(card1Angle))
                    .opacity(card1Opacity)

                Image("pinch-hand")
                    .interpolation(.high)
                    .frame(width: 60, height: 50)
                    .offset(cursorOffset)
                    .offset(x: 18, y: cursorLifted ? -11 : 0)
            }
            // Fill the full ZStack area so offsets are relative to the true centre
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Elements enter/exit naturally at the edge — no artificial fade needed
            .clipped()
            .onChange(of: geo.size) { _, s in viewSize = s }
            .onAppear { viewSize = geo.size }
        }
        .task(id: animationID) { await runLoop() }
        .onHover { hovering in
            if hovering && finished {
                finished = false
                animationID = UUID()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didMoveNotification))   { _ in entryCorner = Self.currentCorner() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResizeNotification)) { _ in entryCorner = Self.currentCorner() }
        .onAppear { entryCorner = Self.currentCorner() }
    }

    private func photoCard(themeIndex: Int, width: CGFloat, height: CGFloat) -> some View {
        let (c1, c2) = themes[themeIndex]
        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [c1, c2],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: c1.opacity(0.40), radius: 8, x: 0, y: 4)
            Image(systemName: "photo.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.90))
        }
        .frame(width: width, height: height)
    }

    // MARK: - Corner

    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
        var sign: Double {
            switch self {
            case .topLeft, .bottomRight:  return  1
            case .topRight, .bottomLeft: return -1
            }
        }
    }

    // Start just beyond the visible edge so elements enter naturally via clipping
    private func edgeOffset(corner: Corner, extra: CGFloat = 70) -> CGSize {
        let x = viewSize.width  / 2 + extra
        let y = viewSize.height / 2 + extra
        switch corner {
        case .topLeft:     return CGSize(width: -x, height: -y)
        case .topRight:    return CGSize(width:  x, height: -y)
        case .bottomLeft:  return CGSize(width: -x, height:  y)
        case .bottomRight: return CGSize(width:  x, height:  y)
        }
    }

    static func currentCorner() -> Corner {
        let win = NSApp.windows.first { $0.isVisible && $0.styleMask.contains(.titled) }
        guard let win, let screen = win.screen ?? NSScreen.main else { return .bottomRight }
        let wc = CGPoint(x: win.frame.midX, y: win.frame.midY)
        let sc = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
        // Always enter from the bottom — only left/right varies by window position
        return wc.x >= sc.x ? .bottomLeft : .bottomRight
    }

    // MARK: - Loop

    private func runLoop() async {
        await sleep(200)
        for i in 0..<3 {
            guard !Task.isCancelled else { return }
            // Lock in themes before the animation starts — they won't change until the next loop
            activeTheme1 = step % 5
            activeTheme2 = (step + 2) % 5
            activeTheme3 = (step + 4) % 5
            switch animStyle {
            case 0: await playDragAndDrop()
            case 1: await playSwoop()
            default: await playTwoTrips()
            }
            onLoop()
            if i < 2 {
                step += 1
                await sleep(400)
            }
        }
        finished = true
    }

    // ── Variant A: straight drag in, release, exit ───────────────
    private func playDragAndDrop() async {
        let s = edgeOffset(corner: entryCorner)
        let g = entryCorner.sign
        let lh = landing.height
        await snap(cursor: s,
                   c1: CGSize(width: s.width + 22 * g, height: s.height + 15),
                   c2: CGSize(width: s.width + 38 * g, height: s.height + 26),
                   a1: 14 * g, a2: 22 * g,
                   op1: cardCount >= 1 ? 1 : 0, op2: cardCount >= 2 ? 1 : 0)

        // Travel to landing point — cards trail cursor from their corner
        let travel = travelDuration()
        withAnimation(.timingCurve(0.22, 0.0, 0.28, 1.0, duration: travel)) {
            cursorOffset = landing
            card1Offset  = CGSize(width: 14 * g, height: lh + 10)
            card2Offset  = CGSize(width: 24 * g, height: lh + 18)
            card1Angle   = 4 * g;  card2Angle = 8 * g
        }
        await sleep(Int(travel * 1000))

        // Release — cursor lifts, cards spring to centred resting position
        withAnimation(.spring(response: 0.30, dampingFraction: 0.52)) {
            cursorLifted = true
            card1Offset  = CGSize(width: -9, height: lh + 4)
            card2Offset  = CGSize(width:  9, height: lh + 14)
            card1Angle   = -4;  card2Angle = 5
        }
        await sleep(500)

        // Cursor exits back to corner
        withAnimation(.timingCurve(0.55, 0.0, 1.0, 1.0, duration: 0.45)) {
            cursorOffset = s; cursorLifted = false
        }
        await sleep(300)

        withAnimation(.easeOut(duration: 0.18)) { card1Opacity = 0; card2Opacity = 0; card3Opacity = 0 }
        await sleep(220)
    }

    // ── Variant B: overshoot arc then spring ─────────────────────
    private func playSwoop() async {
        let s = edgeOffset(corner: entryCorner, extra: 80)
        let g = entryCorner.sign
        let lh = landing.height
        await snap(cursor: s,
                   c1: CGSize(width: s.width + 20 * g, height: s.height + 14),
                   c2: CGSize(width: s.width + 36 * g, height: s.height + 24),
                   a1: 18 * g, a2: 26 * g,
                   op1: cardCount >= 1 ? 1 : 0, op2: cardCount >= 2 ? 1 : 0)

        let travel = travelDuration()
        // Overshoot past centre — cards trail with corner-side lean
        withAnimation(.timingCurve(0.4, 0.0, 0.55, 1.0, duration: travel * 0.65)) {
            cursorOffset = CGSize(width: -10 * g, height: lh - 8)
            card1Offset  = CGSize(width:  -6 * g, height: lh - 4)
            card2Offset  = CGSize(width:   6 * g, height: lh + 6)
            card1Angle   = -3 * g;  card2Angle = 3 * g
        }
        await sleep(Int(travel * 650))

        // Spring back — settle centred above text
        withAnimation(.spring(response: 0.38, dampingFraction: 0.60)) {
            cursorOffset = landing
            card1Offset  = CGSize(width: -9, height: lh + 4)
            card2Offset  = CGSize(width:  9, height: lh + 14)
            card1Angle   = -4;  card2Angle = 5
        }
        await sleep(420)

        withAnimation(.spring(response: 0.28, dampingFraction: 0.48)) {
            cursorLifted = true
            card1Offset  = CGSize(width: -9, height: lh + 8)
            card2Offset  = CGSize(width:  9, height: lh + 18)
        }
        await sleep(460)

        withAnimation(.timingCurve(0.55, 0.0, 1.0, 1.0, duration: 0.40)) {
            cursorOffset = s; cursorLifted = false
        }
        await sleep(280)

        withAnimation(.easeOut(duration: 0.16)) { card1Opacity = 0; card2Opacity = 0; card3Opacity = 0 }
        await sleep(200)
    }

    // ── Variant C: three separate trips ──────────────────────────
    private func playTwoTrips() async {
        let s = edgeOffset(corner: entryCorner)
        let g = entryCorner.sign
        let lh = landing.height
        let travel = travelDuration()

        // Trip 1 — portrait card, settles left
        await snap(cursor: s,
                   c1: CGSize(width: s.width + 18 * g, height: s.height + 12),
                   c2: s, a1: 13 * g, a2: 0, op1: 1, op2: 0)

        withAnimation(.timingCurve(0.22, 0.0, 0.28, 1.0, duration: travel)) {
            cursorOffset = CGSize(width: 8 * g, height: lh + 6)
            card1Offset  = CGSize(width: 16 * g, height: lh + 10)
            card1Angle   = 4 * g
        }
        await sleep(Int(travel * 1000))

        withAnimation(.spring(response: 0.26, dampingFraction: 0.55)) {
            cursorLifted = true
            card1Offset  = CGSize(width: -20, height: lh + 6)
            card1Angle   = -6
        }
        await sleep(260)
        withAnimation(.timingCurve(0.55, 0.0, 1.0, 1.0, duration: 0.40)) {
            cursorOffset = s; cursorLifted = false
        }
        await sleep(340)

        // Trip 2 — landscape card, settles centre
        card2Offset = CGSize(width: s.width + 28 * g, height: s.height + 18)
        card2Angle  = 18 * g
        withAnimation(.easeIn(duration: 0.08)) { card2Opacity = 1 }

        withAnimation(.timingCurve(0.22, 0.0, 0.28, 1.0, duration: travel)) {
            cursorOffset = CGSize(width: 6 * g, height: lh + 4)
            card2Offset  = CGSize(width: 18 * g, height: lh + 14)
            card2Angle   = 6 * g
        }
        await sleep(Int(travel * 1000))

        withAnimation(.spring(response: 0.28, dampingFraction: 0.52)) {
            cursorLifted = true
            card2Offset  = CGSize(width: 0, height: lh - 2)
            card2Angle   = 2
        }
        await sleep(260)
        withAnimation(.timingCurve(0.55, 0.0, 1.0, 1.0, duration: 0.40)) {
            cursorOffset = s; cursorLifted = false
        }
        await sleep(340)

        // Trip 3 — square card, settles right
        card3Offset = CGSize(width: s.width + 36 * g, height: s.height + 22)
        card3Angle  = 24 * g
        withAnimation(.easeIn(duration: 0.08)) { card3Opacity = 1 }

        withAnimation(.timingCurve(0.22, 0.0, 0.28, 1.0, duration: travel)) {
            cursorOffset = landing
            card3Offset  = CGSize(width: 22 * g, height: lh + 16)
            card3Angle   = 8 * g
        }
        await sleep(Int(travel * 1000))

        withAnimation(.spring(response: 0.28, dampingFraction: 0.50)) {
            cursorLifted = true
            card3Offset  = CGSize(width: 20, height: lh + 8)
            card3Angle   = 7
        }
        await sleep(460)

        withAnimation(.timingCurve(0.55, 0.0, 1.0, 1.0, duration: 0.42)) {
            cursorOffset = s; cursorLifted = false
        }
        await sleep(300)

        // All three cards remain visible — this is the final frozen frame
    }

    // MARK: - Helpers

    /// Where the cursor and cards land — above the centred label text
    private var landing: CGSize { CGSize(width: 0, height: -80) }

    /// Scale travel duration to window size — bigger window = slightly longer drag
    private func travelDuration() -> Double {
        let diagonal = sqrt(viewSize.width * viewSize.width + viewSize.height * viewSize.height)
        return min(2.0, max(0.9, Double(diagonal) / 600))
    }

    @MainActor
    private func snap(cursor c: CGSize,
                       c1: CGSize, c2: CGSize,
                       a1: Double, a2: Double,
                       op1: Double, op2: Double) async {
        cursorOffset = c
        card1Offset  = c1;   card2Offset  = c2
        card1Angle   = a1;   card2Angle   = a2
        card1Opacity = op1;  card2Opacity = op2
        card3Opacity = 0
        cursorLifted = false
    }

    private func sleep(_ ms: Int) async {
        try? await Task.sleep(for: .milliseconds(ms))
    }
}

