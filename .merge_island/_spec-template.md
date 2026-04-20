# Spec Template — EyeGuard × MioIsland

> Updated 2026-04-20 (retro): every new spec must include a "Multi-Screen / Display Topology" section. Skipping this section was the upstream cause of the mascot-position bug.

## 1. Goal
What user-visible outcome does this phase deliver? One paragraph.

## 2. Scope (in / out)
- In:
- Out:

## 3. UX

### 3.1 Layout
ASCII or sketch.

### 3.2 States
List every visual state and the trigger for entering / leaving it.

## 4. Multi-Screen / Display Topology (MANDATORY — retro 2026-04-20)

Answer **all** of the following. "N/A" must be justified in one sentence.

| Scenario | Expected behavior |
|----------|-------------------|
| Single built-in display | |
| Built-in + external (built-in is `NSScreen.main`) | |
| Built-in + external (external is `NSScreen.main`) | |
| External only (laptop closed / clamshell) | |
| Display hot-plug while running (connect) | |
| Display hot-plug while running (disconnect) | |
| `safeAreaInsets.top == 0` (non-notch screen) | |

For each scenario, name the **screen the window must follow** and the **fallback** when that screen disappears.

## 5. Architecture

### 5.1 Files touched
### 5.2 New types
### 5.3 Pure helpers (must be testable without AppKit)

## 6. Testing Plan

| Layer | Coverage target | Tests |
|-------|----------------|-------|
| Pure helpers | 100% | |
| Controllers | 80% | |
| Integration | critical paths | |

For window/positioning specs, include the **standard multi-screen suite** from `.merge_island/testing-matrix.md`.

## 7. Risks & Open Questions
