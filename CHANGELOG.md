# Changelog

All notable changes to Eye Guard are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added (Island Merge — MioIsland UX absorbed into Eye Guard)

- **Dynamic Notch mode**: a new display surface that lives in the
  MacBook's notch area, inspired by MioIsland. Collapsed state shows a
  color-coded status dot + continuous-use timer; expanded state shows
  today's health score, next-break countdown, and a "Break Now" button.
- **Mutually-exclusive display modes**: users can switch between the
  original **Apu Mascot** mode and the new **Notch** mode from the menu
  bar picker. Only one surface is visible at a time; preference
  persists across launches (defaults to Apu for backward compatibility).
- **Notch-driven break flow**: in Notch mode, pre-break alerts appear
  as a pop banner with a typewriter-animated message instead of a
  separate overlay. The eye-exercise full-screen session still takes
  over when the user confirms the break.
- **Notch preferences**: horizontal offset (±30pt), hover-activation
  speed (instant / fast / normal / slow), and whether to draw a
  software notch on external displays. Persisted via UserDefaults.
- **Debug-only hooks** (`#if DEBUG`): `BreakScheduler.debugFastForward`
  and `debugForcePreBreak` to accelerate UI screenshot capture. Not
  included in release binaries.

### Changed

- `NotchContainerView` dispatches on `(status, contentType)` and
  renders EyeGuard-specific subviews when the notch is active.
- `EyeGuardOverlayManager` routes pre-break alerts through either the
  classic overlay banner or the notch pop banner based on the current
  `AppMode`.

### Preserved

- All existing business logic (BreakScheduler, ActivityMonitor, Tips,
  EyeExercises, HealthScoreCalculator, Dashboard, Preferences) is
  untouched. Notch is a new view layer, not a rewrite.
- 197 original tests + 36 new Notch/ModeManager/NotchPop/Debug-hook
  tests = 233/233 passing.

### Phase breakdown

See `.island_merge/phases/*.md` for the rewrite plan and `.island_merge/review_log/*.md` for the PM reviews that gated each phase.

| Phase | Scope |
|-------|-------|
| P1 | Notch shell (window, geometry, event monitors, boot animation) |
| P2 | Eye-guard data injection (collapsed/expanded views, bridge) |
| P3 | Mode switching (Apu ↔ Notch, persisted, menu picker) |
| P4 | Break flow (pop banner, typewriter, flow adapter) |
| P5 | Polish (preferences, deferred screenshots, release prep) |

### Notch mio-framework upgrade (branch `feat/notch-mio-upgrade`)

Replaces the bespoke Phase 1–4 notch shell with the full MioIsland mio
framework lifted verbatim into `EyeGuard/Sources/Notch/Framework/` (~7,500
lines, all symbols `Island`-prefixed). Gives Eye Guard mio's pixel-cat
mascot, spring animations, theme palette / typography modifiers, and
LiveEdit customization without re-implementing them.

**Day 1 — Surgery (compile-clean lift)**
- 44 mio framework files copied with `Island` prefix; conflicting models
  stubbed; SwiftUI #Preview blocks stripped; build green at 0 errors,
  233 tests passing.

**Day 2 — Eye Guard wiring on the new framework**
- `IslandNotchViewModel.eyeGuardBridge` field + view routing into
  existing `EyeGuardCollapsedContent` / `EyeGuardExpandedView`.
- `IslandNotchModule` + `IslandNotchBreakFlowAdapter` parallel to legacy
  `NotchModule`; `IslandNotchViewModel.pop(kind:message:duration:)`
  parity surface for break-flow edges.
- `EyeGuardNotchMenu` 5-action surface (Take break / Skip next / Pause /
  Reset session / Preferences) with `Actions` + `State` decoupled
  closure design — fully unit-tested.
- `AppModeCoordinator.notch` branch swapped to `IslandNotchModule.shared`;
  legacy `NotchModule.swift` retained for one-cycle rollback option.

**Day 3 — Visual polish & framework integration**
- `IslandNeonPixelCatView` rendered in the closed-state left wing
  alongside the EyeGuard tier color dot + MM:SS continuous-use timer.
- `.notchPalette()` applied at `IslandHelperViews` root → entire
  EyeGuard notch surface participates in mio's 0.3s theme crossfade.
- `.notchFont(13)` on the action menu so labels respect the user's
  `FontScale` preference.
- Spring animations (open/close/pop), 1s boot animation, and pop banner
  pipeline all inherited free from the mio lift; verified by new
  `IslandNotchBreakFlowAdapterContractTests`.
- LiveEdit horizontal-offset persistence already covered by 6 existing
  `NotchCustomizationStoreTests`.

**Test count:** 233 → 243 (+4.3%) across the upgrade branch.

**Day 4 — Cleanup (in progress)**
- 4.2 grep audit: ✅ no app-layer code references the legacy
  `NotchModule` / `NotchViewModel` types — the swap is clean. Only
  legacy notch files themselves and `NotchPopTests` retain references;
  these will be deleted together in 4.1 once 2.6 burn-in is confirmed.
- 4.3 multi-screen audit: ✅ `IslandNotchModule` filters built-in
  displays then falls back to `NSScreen.main`; each window controller
  reads `screen.hasPhysicalNotch` for proper geometry.
