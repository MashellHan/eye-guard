# Multi-Screen Guide for Contributors

> Created 2026-04-20 as part of the mascot-position retro. Read this before touching any window or positioning code.

## TL;DR

1. **Never use `NSScreen.main` directly in window code.** Use `targetScreen` (helper that returns `NSScreen.builtin ?? NSScreen.main`).
2. **Always use values you just computed when calling `setFrame`.** Do not pass `window.frame` to `setFrame` — that is a no-op.
3. **Subscribe to `didChangeScreenParameters`** in any controller that owns a window.
4. **Extract math into a pure struct** so it can be unit-tested without AppKit.

## Why

`NSScreen.main` is "the screen with the keyboard focus", not "the built-in laptop screen". When the user moves focus to an external display:

- `NSScreen.main.visibleFrame.origin` is **not** `(0, 0)` — it's wherever the external display sits in the global coordinate space (e.g., `(2560, 0)`).
- Code like `let x = visibleFrame.maxX - 140` then computes coordinates **on the external screen**, but if your window is placed on the built-in screen, the result lands somewhere unexpected (typically near the top edge of the built-in screen).

This is exactly the bug fixed in commit `01f15be`. See `.merge_island/retro/2026-04-20-mascot-position-bug.md`.

## Patterns

### Picking the target screen

```swift
private var targetScreen: NSScreen? {
    NSScreen.builtin ?? NSScreen.main
}
```

`NSScreen.builtin` is defined in `EyeGuard/Sources/Notch/Geometry/NSScreen+Notch.swift`.

### Computing then applying a frame

```swift
let newFrame = MyCalculator.frame(...)
NSAnimationContext.runAnimationGroup { ctx in
    ctx.duration = 0.35
    window.animator().setFrame(newFrame, display: true)
}
```

Do **not** write:

```swift
let finalX = ...
let runtimeWidth = ...
_ = (finalX, runtimeWidth)            // ❌ retro 2026-04-20
window.animator().setFrame(window.frame, display: true)  // ❌ stale frame
```

SwiftLint's `no_discarded_locals` rule will fail the build on the first line.

### Reacting to display hot-plug

```swift
private var screenChangeObserver: NSObjectProtocol?

init(...) {
    screenChangeObserver = NotificationCenter.default.addObserver(
        forName: NSApplication.didChangeScreenParametersNotification,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        Task { @MainActor in self?.repositionAfterScreenChange() }
    }
}

deinit {
    if let observer = screenChangeObserver {
        NotificationCenter.default.removeObserver(observer)
    }
}
```

### Pure helper rule

Anything that touches `NSScreen` / `NSWindow.frame` should delegate the math to a pure `struct`:

```swift
struct MyCalculator {
    static func position(in visibleFrame: CGRect, windowSize: CGSize) -> NSPoint {
        // pure math, no AppKit objects
    }
}
```

Test the calculator with synthetic `CGRect`s. The AppKit layer becomes a thin shim.

## Testing checklist

See `.merge_island/testing-matrix.md` for the full standard suite. Minimum: cells 1, 2, 3 of the matrix.

## Existing helpers

- `MascotPositionCalculator` — `EyeGuard/Sources/Mascot/MascotPositionCalculator.swift`
- `IslandNotchFrameCalculator` — `EyeGuard/Sources/Notch/Framework/Geometry/IslandNotchFrameCalculator.swift`
- `NSScreen.builtin` — `EyeGuard/Sources/Notch/Geometry/NSScreen+Notch.swift`
