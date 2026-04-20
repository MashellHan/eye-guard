# Code Review Checklist — EyeGuard × MioIsland

> Added 2026-04-20 after the mascot-position retro.
> Reviewer must tick every box before approving any PR that touches `Sources/Mascot`, `Sources/Notch`, or any window/positioning code.

## A. Window & Screen (NEW — added by retro)

- [ ] No bare `NSScreen.main` in window/positioning code (use `targetScreen` helper or `NSScreen.builtin ?? NSScreen.main`)
- [ ] Every `setFrame` / `setFrameOrigin` call uses values **computed in the same scope**, not stale `window.frame`
- [ ] Local variables computed for geometry are actually consumed (no `_ = (foo, bar)` patterns)
- [ ] Multi-screen behavior tested: external display as `NSScreen.main`, no built-in display, screen disconnected mid-session
- [ ] Subscribed to `NSApplication.didChangeScreenParametersNotification` if the controller owns a window
- [ ] Coordinate-system assumption documented (macOS y-axis points up; `visibleFrame.origin` may be non-zero on non-main screens)

## B. Test Coverage

- [ ] Pure geometry helpers exist as standalone `struct`s with `static` methods (so they are unit-testable without `NSScreen`)
- [ ] Each new `NSWindow` subclass / controller has at least one frame-assertion test
- [ ] Mascot/Notch module coverage stays ≥ 80% (`swift test --enable-code-coverage`)
- [ ] No test was disabled / `@Test(.disabled)` without an attached issue link

## C. General Quality

- [ ] Functions ≤ 50 lines; files ≤ 800 lines
- [ ] No deep nesting (>4 levels) — use early return / guards
- [ ] Errors handled explicitly (no silent `try?` on critical paths)
- [ ] No hardcoded secrets, paths, magic numbers (use constants)
- [ ] No `print()` — use `os.Logger` / `Log.*`
- [ ] Sendable / `@MainActor` annotations correct under Swift 6 strict concurrency

## D. Spec & Documentation

- [ ] Behavior change is reflected in the relevant `.merge_island/*.md` spec
- [ ] If the change touches multi-screen behavior, `MULTI_SCREEN_GUIDE.md` updated
- [ ] CHANGELOG entry added under the Unreleased section
- [ ] If a bug was fixed, a retro is filed in `.merge_island/retro/` (when impact warrants it)

## E. Pre-merge

- [ ] `swift build` clean (no warnings)
- [ ] `swift test` all green
- [ ] `swiftlint --strict` exits 0 (CI gates on this)
- [ ] Branch up to date with target branch
