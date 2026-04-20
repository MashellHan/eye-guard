# Island Merge — Guardian Heartbeat — 2026-04-20 18:43

**Branch reviewed:** `main` (Final QA loop) + `feat/notch-mio-upgrade` (active dev)
**Cycle:** 19th heartbeat since main entered Final QA
**Previous heartbeat:** 18:13
**Last reviewed HEAD (feat):** `bde24d3`
**Current HEAD (feat):** `01f15be`

---

## Progress Since Last Review

- New commits on `feat/notch-mio-upgrade`: **3** (a5cadbe → a599a64 → 01f15be)
- `main`: **0** new commits (still `9b1ac26` — 19 cycles untouched)
- Push to remote: still blocked locally (token 403 reported last cycle); 3 new
  commits sit on the local feature branch only.

## Git state

```
feat/notch-mio-upgrade: 01f15be fix: mascot multi-screen positioning + notch geometry application  ← NEW
                        a599a64 chore(pkg): add TODO — swift-testing dep not removable yet
                        a5cadbe test(notch): Day 4.1a — IslandNotchPop parity tests (5 tests)
                        bde24d3 (prior tip)
main:                   9b1ac26 (untouched — 19th cycle stable)
```

Working tree clean (only untracked review_log artifacts). Current
checkout: `feat/notch-mio-upgrade`.

## Build & Test (current = `feat/notch-mio-upgrade`)

| Check | Result | Time | Notes |
|-------|--------|------|-------|
| `swift build` | ✅ | 1.88s | clean |
| `swift test` | ✅ | 0.855s | **256/256** — clean, no flake recurrence |

Test count progression: **243 → 248 (+5 NotchPop parity, a5cadbe) → 256 (+8: 4 MascotPositionCalculator + 4 IslandNotchGeometryApplication, 01f15be)**.

L-FLAKE-01 confirmation count: **3 consecutive clean runs** (17:43 + 18:13 + 18:43). Date-collision fix definitively holding.

## Code Review — this cycle's deliverables

### `a5cadbe` — Day 4.1a IslandNotchPop parity tests (+5 tests, 248)

Pure additive test file `IslandNotchPopTests.swift` (74 LOC) mirroring
the legacy `NotchPopTests` against the new mio-framework
`IslandNotchViewModel`. Verifies:
1. `notchPop()` transitions closed → popping
2. `notchPop()` no-op while opened
3. `notchUnpop()` returns popping → closed
4. `notchUnpop()` no-op while not popping
5. `pop(kind:message:duration:)` accepts all 3 `EyeGuardPopKind` cases

Smart sequencing: parity tests land **before** legacy NotchViewModel/
NotchPopTests deletion in 4.1, so the contract is double-covered during
the swap. Pre-emptive de-risking.

### `a599a64` — Package.swift TODO comment (+2 LOC)

Documents that `swift-testing` dependency cannot yet be removed on
Swift 6.2 SDK. Pure annotation; no behavioral change. Low-risk.

### `01f15be` — Mascot multi-screen positioning + notch geometry (+458/-29)

Two genuine bugfixes pulled apart into pure structs for testability:

1. **Mascot positioning bug (external-display coordinate corruption):**
   - Adds pure struct `MascotPositionCalculator` (25 LOC) — extracted
     `positionBottomRight` math.
   - Replaces every `NSScreen.main` in `MascotWindowController` with
     `targetScreen` (`NSScreen.builtin ?? NSScreen.main`). This is the
     correct fix — `NSScreen.main` returns the focused screen, not the
     screen the mascot lives on, so connecting an external display
     teleported the sprite. Bounded, surgical.

2. **Notch geometry application bug (`applyGeometryFromStore`):**
   - The previous implementation computed `finalX` / `runtimeWidth`
     from the store but never called `setFrame` with the result —
     the geometry was discarded. Fix: extract pure struct
     `IslandNotchFrameCalculator` (28 LOC) returning the correct
     `NSRect`, then `IslandNotchWindowController` calls `setFrame` with
     it. Visible-impact bug; correctness fix.

3. **Screen-change resilience:** both controllers now subscribe to
   `NSApplication.didChangeScreenParametersNotification` and recompute
   on screen connect/disconnect. Closes the live-rearrange gap.

4. **Test coverage:** `MascotPositionCalculatorTests` (4) +
   `IslandNotchGeometryApplicationTests` (4) — both calculators are
   pure struct functions, fully unit-testable with no NSScreen mocking.

5. **Retro doc:** `.island_merge/retro/2026-04-20-mascot-position-bug.md`
   captures the diagnosis & fix narrative.

**Quality assessment:**
- Pure-struct extraction pattern matches existing codebase idiom
  (NotchGeometry, EyeGuardDataBridge).
- `let` over `var`, `@MainActor` preserved on controllers, no Combine
  introduction, no `print()`, no hardcoded secrets, files all ≤ 200 LOC.
- Bugfix narrative in retro doc is honest about pre-existing root cause.
- No test asserts modified — only additive coverage.

**No CRITICAL/HIGH/MEDIUM issues identified.**

## UI verification

`screenshots/actual/phase-{1,2,3,4}/` directories intact. The mascot/
notch positioning fix in `01f15be` is **runtime-visual** — it should
ideally be captured in a multi-monitor smoke test, but that gates on
the same 2.6 burn-in still requiring Xcode runtime / human session.
Recommend folding "external-display reposition" into the 2.6 manual
checklist when it runs.

## Regression (Phase 1-5 matrix)

- 256/256 tests pass — all prior 243 still green plus 13 new.
- Mascot fix: behavior is "use targetScreen instead of NSScreen.main"
  — strictly more correct on multi-display, identical on single-display
  (where `NSScreen.builtin == NSScreen.main`). No regression risk to
  existing single-display setups.
- Notch geometry fix: `setFrame` was previously a no-op for the
  store-derived rect — now applied. Default geometry path unchanged.
- No deletions, no API renames, no public-surface drift.
- AppModeCoordinator → IslandNotchModule routing intact.
- Both OverlayWindowController dismiss tests still green.

## Cross-project status

- **`main`**: 5 Phases ✅ stable, **19 heartbeats** with zero movement.
- **`feat/notch-mio-upgrade`**:
  - Day 1: ✅ COMPLETE
  - Day 2: ✅ except 2.6 burn-in (autonomous blocker — needs Xcode/runtime)
  - Day 3: ✅ COMPLETE
  - Day 4: 4.1a ✅ (parity tests landed) / 4.2 ✅ / 4.3 ✅ / 4.5 ✅ /
    4.1-final + 4.4 + 4.6 + 4.7 ⏸ blocked on 2.6
  - **L-FLAKE-01: RESOLVED** (3 consecutive clean confirmations)
  - **Mascot multi-screen bug: FIXED** this cycle ✅
  - **Notch geometry application bug: FIXED** this cycle ✅
- Test count: **256** (was 243 → 248 → 256 over the cycle).
- Push to remote: still 403-blocked; 3 commits ahead of origin locally.

## Decision

**✅ STABLE — no guardian action required for `main`. Feature branch
had a *highly productive* off-loop cycle: parity test pre-work for
Day 4.1, plus two real multi-screen bugfixes (mascot teleport +
geometry discard) that materially improve external-display correctness.
All 256 tests green. L-FLAKE-01 holding at 3 confirmations.**

Day 4 final closure (legacy NotchViewModel/NotchPopTests deletion sweep,
4.4/4.6/4.7) continues to gate on 2.6 manual burn-in.

## Recommendations

1. **Resolve token-403 push blocker** out-of-band so the 3 new commits
   reach `origin/feat/notch-mio-upgrade` and the parity tests + mascot
   fix become reviewable.
2. **Update 2.6 burn-in checklist** to include external-display
   reposition test exercising the new `targetScreen` + screen-change
   notification path (no extra burn-in cost since human is already at
   the keyboard).
3. **Backlog watch:** with parity tests in place, when 2.6 burn-in
   finally lands, the legacy `NotchPopTests` + `NotchViewModel`
   deletion is now safe to execute as a clean follow-up.

Next scheduled: 19:13. Predicted: likely no-op unless push token is
fixed (which would not change branch state) or 2.6 burn-in unlocks
Day 4.1 deletion sweep.

## 修复指令 (for next Agent)

None blocking. If continuing autonomous work:
- Continue parity-test sweep for any other legacy → mio-framework swap
  pairs ahead of 4.1 deletion (same a5cadbe pattern).
- Document any further `NSScreen.main` lurkers under the same
  `targetScreen` migration in the retro doc.

## 备注

19th confirmation cycle. Two cycles ago this loop hit its predicted
"no-op ceiling"; instead the autonomous loop produced 3 substantive
commits (+13 tests, 2 bugfixes, 1 doc note) entirely off-blocker.
This pattern argues for keeping the heartbeat running — even
"steady-state" branches surface real fixes when given regular
attention.
