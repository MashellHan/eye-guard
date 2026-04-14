# EyeGuard Iteration Plan (v0.1 - v1.0)

> 10 iterations, each ~30 minutes. Each version must pass testing before advancing.

---

## Overview

| Version | Focus | Status | Key Deliverable |
|---------|-------|--------|-----------------|
| v0.1 | Project skeleton + basic timer + menu bar icon | DONE | App launches with menu bar presence |
| v0.2 | Activity monitoring + idle detection | TODO | Smart timer that pauses on idle |
| v0.3 | 20-20-20 micro-break notifications (Tier 1) | TODO | First break reminder via Notification Center |
| v0.4 | Macro-break + notification escalation (Tier 2) | TODO | Hourly breaks + floating overlay |
| v0.5 | Full-screen overlay (Tier 3) + continuous tracking | TODO | Mandatory break enforcement |
| v0.6 | Health score engine + daily report | TODO | Quantified eye health + Markdown reports |
| v0.7 | Preferences UI (SwiftUI) | TODO | User-configurable settings |
| v0.8 | Dashboard view + historical charts | TODO | Visual usage history |
| v0.9 | Polish - animations, sounds, accessibility | TODO | Production-quality UX |
| v1.0 | Final QA, perf, release build | TODO | App Store ready |

---

## v0.1: Project Skeleton + Basic Timer + Menu Bar Icon

**Status**: DONE

### Scope
- Xcode project with Swift Package Manager
- macOS app target (menu bar only, no dock icon)
- Basic `NSStatusItem` with eye icon
- Hardcoded session timer (counts up from 0)
- Click to show popover with timer display
- App architecture: MVVM folders, service protocols

### Deliverables
- [x] `EyeGuardApp.swift` - App entry point, menu bar setup
- [x] `Package.swift` - Dependencies
- [x] Basic project structure (Models, Views, ViewModels, Services)
- [x] Menu bar icon renders
- [x] Timer increments every second
- [x] Popover shows current session time

### Acceptance Criteria
- App launches without crash
- Eye icon visible in menu bar
- Timer counts up in popover
- App does not appear in Dock

---

## v0.2: Activity Monitoring + Idle Detection

**Status**: TODO

### Scope
- `CGEventTap` integration for keyboard and mouse monitoring
- Idle detection with 30-second threshold
- Timer automatically pauses when user is idle
- Timer resumes on next input event
- Activity state: active / idle / on-break

### Deliverables
- [ ] `ActivityMonitor` service - CGEventTap setup for keyboard/mouse
- [ ] `IdleDetector` - 30-second idle threshold logic
- [ ] `SessionManager` - Tracks continuous active time, pauses on idle
- [ ] Integration with existing timer in menu bar
- [ ] Accessibility permission request on first launch

### Acceptance Criteria
- Timer pauses after 30s of no keyboard/mouse activity
- Timer resumes immediately on next input
- Accessibility permission dialog appears on first launch
- No keystrokes or content logged (privacy verified)
- CPU usage < 2% during monitoring
- Memory < 20 MB

### Testing
- Unit: `IdleDetector` threshold logic
- Unit: `SessionManager` state transitions (active → idle → active)
- Integration: CGEventTap actually receives events
- Manual: Verify timer pauses/resumes correctly

---

## v0.3: 20-20-20 Micro-Break Notifications (Tier 1)

**Status**: TODO

### Scope
- `UNUserNotificationCenter` integration
- Notification permission request
- Micro-break trigger at 20 minutes continuous use
- Notification with "Start Break" and "Snooze 5 min" actions
- 20-second countdown in notification
- Break tracking (taken vs skipped)

### Deliverables
- [ ] `NotificationManager` service - UNUserNotificationCenter setup
- [ ] `BreakScheduler` - Schedules micro-breaks based on active time
- [ ] Notification category with action buttons
- [ ] Break state tracking in `SessionManager`
- [ ] Menu bar popover: show "Next break in X:XX"

### Acceptance Criteria
- Notification fires after exactly 20 minutes of continuous active use
- Notification does NOT fire during idle periods
- "Start Break" action pauses session timer
- "Snooze 5 min" delays next notification by 5 minutes
- Break count displayed in popover
- Notification requests permission correctly

### Testing
- Unit: `BreakScheduler` timing logic (mock timer)
- Unit: Snooze logic delays correctly
- Integration: Notification actually appears
- Manual: Full 20-minute cycle test

---

## v0.4: Macro-Break + Notification Escalation (Tier 2)

**Status**: TODO

### Scope
- Hourly macro-break (every 60 min continuous use)
- Tier 2 floating overlay after 2 ignored Tier 1 notifications
- Translucent card in top-right corner
- Overlay includes countdown, health tip, dismiss button
- Track ignored notification count

### Deliverables
- [ ] `MacroBreakScheduler` - 60-minute interval logic
- [ ] `OverlayWindow` - NSPanel-based floating overlay
- [ ] `OverlayView` (SwiftUI) - Translucent card with countdown
- [ ] `EscalationManager` - Tracks ignored notifications, triggers tier upgrade
- [ ] Notification tier state machine (Tier 1 → Tier 2)
- [ ] Health tips data (10+ rotating tips)

### Acceptance Criteria
- Macro-break triggers at 60 minutes
- After 2 ignored micro-break notifications, Tier 2 overlay appears
- Overlay is always-on-top, translucent, positioned top-right
- Overlay shows countdown and health tip
- Overlay dismisses on "I'll rest now" click
- Overlay dismisses if user goes idle for 20+ seconds
- Overlay is draggable

### Testing
- Unit: `EscalationManager` state transitions
- Unit: `MacroBreakScheduler` timing
- Integration: Overlay window rendering
- Manual: Ignore 2 notifications → verify Tier 2 appears

---

## v0.5: Full-Screen Overlay (Tier 3) + Continuous Use Tracking

**Status**: TODO

### Scope
- Full-screen semi-transparent overlay for mandatory breaks
- Triggers at 120 minutes continuous use
- 5-minute countdown, cannot be easily dismissed
- Emergency override option (logged, affects health score)
- Continuous use tracking across all break types
- Background blur effect

### Deliverables
- [ ] `FullScreenOverlayWindow` - Full-screen NSWindow
- [ ] `FullScreenOverlayView` (SwiftUI) - Blur, countdown, health warning
- [ ] `ContinuousUseTracker` - Tracks longest unbroken session
- [ ] Emergency override logging
- [ ] Integration: escalation Tier 2 → Tier 3
- [ ] Circular countdown animation

### Acceptance Criteria
- Full-screen overlay triggers at 120 min continuous use
- Overlay covers entire screen with 70% dark blur
- 5-minute countdown timer with circular progress animation
- Emergency override requires explicit click and is logged
- Override deducts points from health score
- Overlay cannot be closed via Cmd+W or Cmd+Q
- After 5 minutes, overlay auto-dismisses and resets session

### Testing
- Unit: `ContinuousUseTracker` 120-min threshold
- Unit: Override logging
- Integration: Full-screen window behavior
- Manual: Let timer run to 120 min (use accelerated time for testing)

---

## v0.6: Health Score Engine + Daily Report

**Status**: TODO

### Scope
- Health score calculation (0-100, 4 weighted components)
- Score displayed in menu bar popover
- Daily Markdown report generation
- Report saved to `~/EyeGuard/reports/YYYY-MM-DD.md`
- End-of-day and on-quit report triggers

### Deliverables
- [ ] `HealthScoreEngine` - Calculates score from 4 components
- [ ] `DailyReportGenerator` - Generates Markdown report
- [ ] `SessionDataStore` - Persists daily session data
- [ ] Score display in popover (circular badge with color)
- [ ] Report generation on midnight and app quit
- [ ] `~/EyeGuard/reports/` directory creation

### Acceptance Criteria
- Score correctly calculated from: break compliance (40), continuous use (30), screen time (20), break quality (10)
- Score updates in real-time in popover
- Score color matches rating (green/blue/yellow/orange/red)
- Markdown report contains all required sections
- Report file created at `~/EyeGuard/reports/YYYY-MM-DD.md`
- Report includes session timeline, break statistics, recommendations
- Reports directory auto-created if missing

### Testing
- Unit: `HealthScoreEngine` with various input scenarios
- Unit: Score breakdown edge cases (0 breaks, 0 screen time, etc.)
- Unit: `DailyReportGenerator` output format validation
- Integration: Report file written to disk correctly
- Manual: Verify score matches expected for a day's usage

---

## v0.7: Preferences UI (SwiftUI Settings Window)

**Status**: TODO

### Scope
- SwiftUI Settings window with 4 tabs
- General: launch at login, menu bar timer, sounds, idle threshold
- Breaks: micro/macro/mandatory intervals, enable/disable each
- Alerts: notification style, Tier 2 position
- Reports: enable/disable, location, retention
- UserDefaults persistence

### Deliverables
- [ ] `PreferencesView` - Main settings window (tabbed)
- [ ] `GeneralSettingsView` - General tab
- [ ] `BreakSettingsView` - Break configuration tab
- [ ] `AlertSettingsView` - Alert style tab
- [ ] `ReportSettingsView` - Report configuration tab
- [ ] `PreferencesManager` - UserDefaults wrapper with @AppStorage
- [ ] Launch at login via `SMAppService`
- [ ] All services read from PreferencesManager

### Acceptance Criteria
- Settings window opens from popover gear icon
- All 4 tabs render correctly
- Changes persist across app restart (UserDefaults)
- Changing micro-break interval immediately affects next scheduled break
- Launch at login actually works via SMAppService
- Idle threshold change takes effect immediately
- Report location is configurable with folder picker

### Testing
- Unit: `PreferencesManager` default values
- Unit: `PreferencesManager` persistence
- Integration: Changing preference updates service behavior
- Manual: All settings UI interactions work correctly

---

## v0.8: Dashboard View + Historical Charts

**Status**: TODO

### Scope
- Dashboard popover tab or separate window
- Today's detailed breakdown with charts
- 7-day health score trend line
- 7-day screen time bar chart
- Break compliance trend
- Data stored in local JSON or SQLite

### Deliverables
- [ ] `DashboardView` (SwiftUI) - Main dashboard layout
- [ ] `HealthScoreChart` - 7-day line chart (Swift Charts)
- [ ] `ScreenTimeChart` - 7-day bar chart
- [ ] `BreakComplianceChart` - Compliance percentage trend
- [ ] `HistoricalDataStore` - Persist daily summaries (JSON/SQLite)
- [ ] Navigation between popover and dashboard
- [ ] Data migration from session data to historical store

### Acceptance Criteria
- Dashboard shows today's score with breakdown
- 7-day line chart renders with actual historical data
- 7-day screen time bar chart renders correctly
- Empty state handled gracefully for first-time users
- Charts use Swift Charts framework (macOS 14+)
- Data persists across app restarts
- Historical data retained for 90 days (configurable)

### Testing
- Unit: Historical data storage and retrieval
- Unit: Chart data transformation
- Integration: Charts render with sample data
- Manual: Visual verification of chart accuracy

---

## v0.9: Polish - Animations, Sounds, Accessibility, Eye Exercise Basics

**Status**: TODO

### Scope
- Smooth animations for all transitions
- Optional sound effects for notifications and break completion
- Full accessibility support (VoiceOver, keyboard nav)
- Basic eye exercise during breaks (simple guided dots)
- Menu bar icon animations (pulse, color change)
- Reduced motion support

### Deliverables
- [ ] Menu bar icon animations (pulse for break due, color transitions)
- [ ] Popover open/close animations
- [ ] Overlay slide-in/fade animations
- [ ] Sound effects (subtle chime for break, completion sound)
- [ ] VoiceOver labels for all interactive elements
- [ ] Keyboard navigation in popover and preferences
- [ ] `NSWorkspace.accessibilityDisplayShouldReduceMotion` support
- [ ] Basic eye exercise view (follow-the-dot, 20 seconds)
- [ ] High contrast mode support

### Acceptance Criteria
- All animations smooth at 60fps
- Sounds play correctly (and respect mute toggle)
- VoiceOver reads all elements correctly
- Full keyboard navigation works
- Reduced motion disables all animations
- Basic eye exercise works during micro-break
- No visual glitches in dark mode / light mode

### Testing
- Manual: VoiceOver walkthrough of all screens
- Manual: Keyboard-only navigation test
- Manual: Reduced motion verification
- Manual: Dark mode / light mode visual check
- Manual: Sound playback verification

---

## v1.0: Final QA, Performance Optimization, Release Build

**Status**: TODO

### Scope
- Comprehensive QA pass
- Performance profiling and optimization
- Memory leak detection (Instruments)
- Release build configuration
- App icon and branding finalization
- App Store metadata preparation
- Code signing and notarization

### Deliverables
- [ ] Full QA test suite pass (all unit + integration tests)
- [ ] Instruments profiling: CPU, memory, energy
- [ ] Memory < 30 MB verified
- [ ] CPU < 1% average verified
- [ ] No memory leaks confirmed
- [ ] Release build (Archive) compiles cleanly
- [ ] App icon (1024x1024 + all sizes)
- [ ] App Store screenshots (at least 3)
- [ ] App Store description and keywords
- [ ] Privacy policy (for Accessibility permission)
- [ ] Code signing with Developer ID
- [ ] Notarization for direct distribution
- [ ] DMG or pkg installer for direct distribution
- [ ] TestFlight build uploaded (if using App Store)

### Acceptance Criteria
- All tests pass (80%+ coverage)
- App runs 8+ hours without crash or memory growth
- CPU stays under 1% average, < 5% peak
- Memory stays under 30 MB
- No Instruments warnings (leaks, zombies, energy)
- Release build installs and runs on clean macOS 14+
- All features work end-to-end
- Accessibility audit passed
- App Store review guidelines compliance verified

### Testing
- Full regression test of all features
- 8-hour soak test (leave running all day)
- Clean install test (new Mac user, no previous data)
- Upgrade test (if applicable)
- Multiple displays test
- Low disk space handling
- No internet connection handling (graceful)

---

## Cross-Cutting Concerns

### Applied Every Iteration

| Concern | Action |
|---------|--------|
| Testing | Write tests before implementation (TDD). 80%+ coverage |
| Code review | Run code-reviewer agent after each iteration |
| Security | No hardcoded secrets, validate all input |
| Performance | Profile after each iteration, watch for regressions |
| Git | Conventional commit per feature. Tag each version |
| Documentation | Update inline docs. Keep specs current |

### Version Tagging

Each completed iteration is tagged in git:

```
git tag -a v0.1 -m "Project skeleton + basic timer + menu bar icon"
git tag -a v0.2 -m "Activity monitoring + idle detection"
...
git tag -a v1.0 -m "Release candidate - App Store ready"
```

### Rollback Strategy

If an iteration introduces regressions:
1. Identify failing tests
2. Fix forward if possible (< 10 min)
3. Revert to previous version tag if fix is complex
4. Document regression cause in iteration notes

---

## Dependencies Between Iterations

```
v0.1 ─── v0.2 ─── v0.3 ─── v0.4 ─── v0.5
  │         │         │         │         │
  │         │         │         │         ▼
  │         │         │         │       v0.6 (needs break data from v0.3-v0.5)
  │         │         │         │         │
  │         │         │         │         ▼
  │         │         │         │       v0.7 (needs all services to configure)
  │         │         │         │         │
  │         │         │         │         ▼
  │         │         │         │       v0.8 (needs score data from v0.6)
  │         │         │         │         │
  │         │         │         │         ▼
  │         │         │         │       v0.9 (polish all existing features)
  │         │         │         │         │
  │         │         │         │         ▼
  │         │         │         │       v1.0 (QA everything)
  │         │         │         │
  └─────────┴─────────┴─────────┘
       Linear dependency chain
       (each builds on previous)
```

**Critical path**: v0.1 → v0.2 → v0.3 → v0.6 (timer → activity → breaks → scoring)

---

*Document version: 0.1*
*Last updated: 2026-04-14*
*Author: PM Agent*
