# Release Notes — v4.0.0 "Island Merge"

> Draft — do not tag until Phase 5 remaining items (UI screenshots,
> multi-screen rendering, `NotchPreferencesSection` view) are complete
> and the Impl Agent or user has validated on real hardware.

## 🏝️ Dynamic Notch, meet Eye Guard

Eye Guard 4.0 absorbs the **Dynamic Notch UX from [MioIsland](https://github.com/MioMioOS/MioIsland)**
as a brand-new display surface, sitting alongside the original Apu
Mascot mode. The business logic — break scheduling, eye exercises,
health score, activity monitoring — is untouched; Notch is a pure view
layer you can switch on or off from the menu bar.

## Highlights

### Two display modes, one app

- **Apu Mascot (default)**: unchanged, warm, corner-of-screen companion.
- **Dynamic Notch (new)**: glanceable status in the MacBook's notch area, pop banners for pre-break alerts, typewriter-animated messages, hover/click to expand.

### Status at a glance

- Color-coded dot (🟢 < 10 min · 🟡 10–15 · 🟠 15–20 · 🔴 ≥ 20) next to a live `MM:SS` continuous-use timer.
- Expanded panel surfaces today's health score, next-break countdown, and a Break Now button.

### Break flow, re-imagined

- Pre-break alert slides out of the notch with a typewriter animation.
- "Break Now" / "Postpone" buttons sit directly in the expanded pill.
- Full-screen eye exercise session still takes over on confirmation.

### New preferences

- Horizontal offset ±30pt.
- Hover-activation speed: instant / fast / normal / slow.
- Opt-in software notch on external (non-notched) displays.

### Mode switching is persistent

- Pick once from the menu bar; preference survives restarts.
- Defaults to Apu Mascot for backward compatibility.

## Under the hood

- 5 rewrite phases, each PM-gated with build + test + screenshot checks. See `.island_merge/` for the full artifact trail.
- 227 → **233 tests**, 0 warnings.
- `BreakScheduler` gains `#if DEBUG` fast-forward / force-pre-break hooks so future UI screenshots can be captured on demand.

## Upgrade notes

- All existing data and preferences persist.
- First launch after upgrade remains in Apu mode; opt into Notch from the menu bar.
- No deprecations — everything from 3.x still works.

## Known deferred items (see Phase 5 review log)

- Several UI screenshots (yellow/red collapsed tiers, switch animation, preferences picker, break flow) still need real-hardware capture via the new debug hooks.
- `NotchPreferencesSection.swift` view not yet wired to `NotchCustomizationStore`.
- External-display software notch rendering is configured but not visually finalized.

## Credits

- Dynamic Notch UX concept & initial implementation: [MioIsland](https://github.com/MioMioOS/MioIsland) (forked to `MashellHan/mio-guard`).
- Eye Guard maintainers: see repo.
