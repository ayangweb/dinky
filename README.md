# Dinky

A small macOS utility that compresses images. Drop files in, get smaller ones back.

Supports JPG, PNG, WebP, and AVIF. Outputs WebP or AVIF depending on your preference. Strips metadata, respects max dimensions and file size targets, and saves next to the original by default.

## How it works

Built entirely in Swift and SwiftUI for macOS 26 (Tahoe). No Electron, no web views, no third-party UI frameworks.

Compression runs through a native `actor`-based service that shells out to platform image tools, keeping the main thread free. Multiple files compress concurrently up to the core count of the machine. Output quality is tuned automatically to hit the target file size if one is set.

The sidebar stores preferences via `@AppStorage`. The results list updates live as each file finishes. Error details are tappable. The idle animation on the drop zone runs through three choreographed variants then holds — portrait, landscape, and wide cards dragged in by a pinch cursor from whatever corner the window is closest to.

The app registers as an "Open with" handler and exposes a Finder Quick Action so you can compress without opening the app manually.

## Built with

- SwiftUI (macOS 26)
- AppKit for window and event integration
- `actor` concurrency model for compression
- `@AppStorage` / `UserDefaults` for preferences
- `NSServices` for Finder integration
- Claude for most of the code

## Install

Download the DMG, drag Dinky to Applications, and open it. macOS may ask you to approve it on first launch since it is not distributed through the App Store.
