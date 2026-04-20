# Testing Matrix — EyeGuard × MioIsland

> Created 2026-04-20 after the mascot-position retro.
> Every UI/window controller MUST have tests in each applicable cell.

## Standard multi-screen suite (window/positioning code)

| # | Screen topology | Required test |
|---|----------------|---------------|
| 1 | Single built-in (origin 0,0; 1440×900) | `frame.origin` is inside `visibleFrame` |
| 2 | External-as-main (origin 2560,0; 2560×1440) | window still placed on built-in (when controller targets built-in) |
| 3 | External-only (no built-in) | falls back to `NSScreen.main`, no crash |
| 4 | Hot-plug connect | controller observes `didChangeScreenParameters`, reposition called |
| 5 | Hot-plug disconnect | window not orphaned on a disappeared screen |
| 6 | Non-notch screen | `notchSize` fallback used; window still drawn |
| 7 | Peek mode (mascot only) | `frame.minY` puts only `peekVisibleHeight` pt above `visibleFrame.minY` |

## Coverage targets

| Module | Target | Enforced |
|--------|--------|----------|
| `Sources/Mascot/` | 80% | CI `coverage-gate.yml` |
| `Sources/Notch/` | 80% | CI `coverage-gate.yml` |
| `Sources/Notch/Geometry/` (pure) | 100% | CI |
| Other modules | 70% | warning only |

## Pure helper rule

If your code calls **any** of: `NSScreen`, `NSWindow.frame`, `setFrame*`, `safeAreaInsets`, `auxiliaryTopLeftArea`, `CGDisplay*` — extract the math into a pure `struct` with a `static` method that takes the relevant `CGRect`/`CGSize`/`CGFloat`s as parameters. Then unit-test the pure helper with synthetic inputs.

This is non-negotiable: the AppKit layer cannot be fully unit-tested, so pure helpers are the only way to lock behavior.

## Examples (existing)

- `MascotPositionCalculator.bottomRight(...)` — covers cells 1, 2, 3, 7
- `IslandNotchFrameCalculator.frame(...)` — covers cells 1, 2 for notch panel

## Reviewer enforcement

PRs that add window/positioning code without filling the matrix above will be marked **BLOCK**. See `.merge_island/review-checklist.md`.
