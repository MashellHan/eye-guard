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
