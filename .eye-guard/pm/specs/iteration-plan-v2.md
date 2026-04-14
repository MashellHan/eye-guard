# EyeGuard Iteration Plan v2 (v0.1 - v2.0)

> **Philosophy**: One feature per version. Stable and tested before moving on.
> Each version must pass testing (80%+ coverage) before advancing.

---

## Overview

| Version | Phase | Focus | Status | Key Deliverable |
|---------|-------|-------|--------|-----------------|
| v0.1 | Core | Project skeleton + menu bar icon + basic timer | DONE | App launches with menu bar presence |
| v0.2 | Core | Pipeline wiring + bug fixes + tests + Logger | DONE | Robust foundation with logging & tests |
| v0.3 | Core | 20-20-20 micro-break notifications | TODO | First break reminder via Notification Center |
| v0.4 | Core | Hourly macro-break + notification escalation | TODO | Floating overlay for ignored notifications |
| v0.5 | Core | Continuous use tracking + mandatory break | TODO | Full-screen overlay at 120 min |
| v0.6 | Score | Health score engine (0-100) | TODO | Real-time quantified eye health |
| v0.7 | Score | Daily Markdown report generation | TODO | Auto-saved daily reports |
| v0.8 | Score | Preferences UI (SwiftUI settings window) | TODO | User-configurable settings |
| v0.9 | Mascot | Mascot v1 - cute floating character | TODO | Idle mascot on screen edge |
| v1.0 | Mascot | Mascot break reminders | TODO | Mascot animates during break time |
| v1.1 | Mascot | Mascot interactions | TODO | Click, hover, drag interactions |
| v1.2 | Mascot | Mascot expressions & moods | TODO | Emotional states based on usage |
| v1.3 | Enhance | Eye exercise animations with mascot | TODO | Guided eye movement routines |
| v1.4 | Enhance | Medical tips carousel | TODO | Rotating ophthalmological tips |
| v1.5 | Enhance | Late night guardian (10 PM+ mode) | TODO | Warmer reminders after 10 PM |
| v1.6 | Enhance | Color balance suggestions | TODO | Screen palette analysis |
| v1.7 | Enhance | Dashboard view + historical charts | TODO | SwiftUI Charts visual history |
| v1.8 | Intel | Sound effects + nature sounds | TODO | Audio ambiance during breaks |
| v1.9 | Intel | LLM integration (Claude API) | TODO | Personalized health analysis |
| v2.0 | Intel | ML adaptive timing | TODO | Learned optimal break patterns |

---

## Phase 1: Core (v0.1 - v0.5)

### v0.1: Project Skeleton + Basic Timer + Menu Bar Icon

**Status**: DONE

#### Scope
- Xcode project with Swift Package Manager
- macOS app target (menu bar only, no dock icon)
- Basic `NSStatusItem` with eye icon
- Hardcoded session timer (counts up from 0)
- Click to show popover with timer display
- App architecture: MVVM folders, service protocols

#### Acceptance Criteria
- [x] App launches without crash
- [x] Eye icon visible in menu bar
- [x] Timer counts up in popover
- [x] App does not appear in Dock

---

### v0.2: Pipeline Wiring + Bug Fixes + Tests + Logger

**Status**: DONE

#### Scope
- Structured logging system (`Logger` service)
- Pipeline wiring between services (timer → activity → UI)
- Bug fixes from v0.1 feedback
- Unit test foundation with XCTest
- CI-friendly test configuration

#### Acceptance Criteria
- [x] Logger outputs structured logs with levels (debug, info, warn, error)
- [x] Service pipeline connected end-to-end
- [x] All v0.1 bugs resolved
- [x] Unit tests pass with 80%+ coverage on core logic
- [x] Tests runnable via `swift test`

---

### v0.3: 20-20-20 Micro-Break Notifications (Tier 1)

**Status**: TODO

#### Scope
- `UNUserNotificationCenter` integration
- Notification permission request flow
- Micro-break trigger at 20 minutes continuous use
- Notification with "Start Break" and "Snooze 5 min" actions
- 20-second break countdown
- Break tracking (taken vs. skipped)

#### Deliverables
- [ ] `NotificationManager` service - UNUserNotificationCenter setup
- [ ] `BreakScheduler` - schedules micro-breaks based on active time
- [ ] Notification category with action buttons
- [ ] Break state tracking in `SessionManager`
- [ ] Menu bar popover: show "Next break in X:XX"

#### Acceptance Criteria
- Notification fires after exactly 20 min of continuous active use
- Notification does NOT fire during idle periods
- "Start Break" action pauses session timer for 20 seconds
- "Snooze 5 min" delays next notification by 5 minutes
- Break count displayed in popover
- Notification requests permission correctly on first trigger

#### Testing
- Unit: `BreakScheduler` timing logic (mock timer)
- Unit: Snooze logic delays correctly
- Integration: Notification actually appears
- Manual: Full 20-minute cycle test (accelerated)

---

### v0.4: Hourly Macro-Break + Notification Escalation (Tier 2)

**Status**: TODO

#### Scope
- Hourly macro-break (every 60 min continuous use)
- Tier 2 floating overlay when 2+ Tier 1 notifications are ignored
- Translucent card in top-right corner (NSPanel)
- Overlay includes countdown, health tip, dismiss button
- Track ignored notification count

#### Deliverables
- [ ] `MacroBreakScheduler` - 60-minute interval logic
- [ ] `OverlayWindow` - NSPanel-based floating overlay
- [ ] `OverlayView` (SwiftUI) - translucent card with countdown
- [ ] `EscalationManager` - tracks ignored count, triggers tier upgrade
- [ ] Health tips data (10+ rotating tips)

#### Acceptance Criteria
- Macro-break triggers at 60 minutes
- After 2 ignored micro-break notifications, Tier 2 overlay appears
- Overlay is always-on-top, translucent, positioned top-right
- Overlay shows countdown + health tip
- Overlay dismisses on "I'll rest now" click
- Overlay dismisses if user goes idle for 20+ seconds
- Overlay is draggable

#### Testing
- Unit: `EscalationManager` state transitions
- Unit: `MacroBreakScheduler` timing
- Integration: Overlay window rendering
- Manual: Ignore 2 notifications -> verify Tier 2 appears

---

### v0.5: Continuous Use Tracking + Mandatory Break (Tier 3)

**Status**: TODO

#### Scope
- Full-screen semi-transparent overlay for mandatory breaks
- Triggers at 120 minutes continuous use
- 5-minute countdown, cannot be easily dismissed
- Emergency override option (logged, affects health score)
- Background blur effect

#### Deliverables
- [ ] `FullScreenOverlayWindow` - full-screen NSWindow
- [ ] `FullScreenOverlayView` (SwiftUI) - blur, countdown, health warning
- [ ] `ContinuousUseTracker` - tracks longest unbroken session
- [ ] Emergency override with logging
- [ ] Integration: escalation Tier 2 -> Tier 3
- [ ] Circular countdown animation

#### Acceptance Criteria
- Full-screen overlay triggers at 120 min continuous use
- Overlay covers entire screen with 70% dark blur
- 5-minute countdown timer with circular progress animation
- Emergency override requires explicit click and is logged
- Override deducts points from health score
- Overlay cannot be closed via Cmd+W or Cmd+Q
- After 5 minutes, overlay auto-dismisses and resets session

#### Testing
- Unit: `ContinuousUseTracker` 120-min threshold
- Unit: Override logging
- Integration: Full-screen window behavior
- Manual: Verify with accelerated timer

---

## Phase 2: Score & Reports (v0.6 - v0.8)

### v0.6: Health Score Engine (0-100, 4 Components)

**Status**: TODO

#### Scope
- Health score calculation algorithm
- 4 weighted components:
  - Break compliance (40 points)
  - Continuous use discipline (30 points)
  - Total screen time (20 points)
  - Break quality (10 points)
- Score displayed in menu bar popover with color badge
- Real-time score updates

#### Deliverables
- [ ] `HealthScoreEngine` - calculates score from 4 components
- [ ] `SessionDataStore` - persists daily session data
- [ ] Score display in popover (circular badge with color coding)
- [ ] Score color mapping: green (80-100), blue (60-79), yellow (40-59), orange (20-39), red (0-19)

#### Acceptance Criteria
- Score correctly calculated from all 4 components
- Score updates in real-time in popover
- Score color matches rating level
- Edge cases handled: 0 breaks, 0 screen time, first launch
- Score resets at midnight for new day

#### Testing
- Unit: `HealthScoreEngine` with boundary scenarios
- Unit: Score breakdown edge cases
- Unit: Color mapping correctness
- Integration: Score updates as breaks are taken/skipped

---

### v0.7: Daily Markdown Report Generation + Auto-Save

**Status**: TODO

#### Scope
- Generate comprehensive daily Markdown report
- Auto-save to `~/EyeGuard/reports/YYYY-MM-DD.md`
- Report triggers: midnight rollover, app quit
- Report sections: summary, timeline, break stats, score breakdown, recommendations

#### Deliverables
- [ ] `DailyReportGenerator` - generates Markdown report
- [ ] Report template with all sections
- [ ] `~/EyeGuard/reports/` directory auto-creation
- [ ] Midnight and on-quit report triggers
- [ ] Report includes personalized recommendations based on score

#### Acceptance Criteria
- Markdown report contains: date, score, timeline, break stats, recommendations
- Report file created at `~/EyeGuard/reports/YYYY-MM-DD.md`
- Reports directory auto-created if missing
- Report generation does not block main thread
- Report is human-readable and well-formatted

#### Testing
- Unit: `DailyReportGenerator` output format validation
- Unit: Recommendation logic based on score ranges
- Integration: Report file written to disk correctly
- Manual: Verify report content matches actual usage

---

### v0.8: Preferences UI (SwiftUI Settings Window)

**Status**: TODO

#### Scope
- SwiftUI Settings window with 4 tabs
- General: launch at login, idle threshold, sounds toggle
- Breaks: micro/macro/mandatory intervals, enable/disable each
- Alerts: notification style, overlay position
- Reports: enable/disable, save location, retention days
- UserDefaults persistence with `@AppStorage`

#### Deliverables
- [ ] `PreferencesView` - main settings window (tabbed)
- [ ] `GeneralSettingsView` - general tab
- [ ] `BreakSettingsView` - break configuration tab
- [ ] `AlertSettingsView` - alert style tab
- [ ] `ReportSettingsView` - report configuration tab
- [ ] `PreferencesManager` - UserDefaults wrapper
- [ ] Launch at login via `SMAppService`

#### Acceptance Criteria
- Settings window opens from popover gear icon
- All 4 tabs render correctly
- Changes persist across app restart
- Changing intervals immediately affects next scheduled break
- Launch at login works via SMAppService
- Folder picker for report location

#### Testing
- Unit: `PreferencesManager` default values and persistence
- Integration: Preference changes update service behavior
- Manual: All settings UI interactions work correctly

---

## Phase 3: Mascot (v0.9 - v1.2) -- USER PRIORITY

> See [mascot-design-spec.md](../ux/mascot-design-spec.md) for full design details.

### v0.9: Eye Guard Mascot v1 - Cute Floating Character

**Status**: TODO

#### Scope
- Introduce the EyeGuard mascot: a small, round, cute eye-themed creature
- Floating NSWindow (always-on-top, borderless, transparent background)
- Positioned on screen edge (bottom-right default)
- Idle animation: gentle breathing (scale pulse), occasional blink
- Click-through when idle (doesn't interfere with work)
- Can be hidden/shown from menu bar

#### Deliverables
- [ ] `MascotWindow` - NSWindow subclass (floating, level: .floating, transparent)
- [ ] `MascotView` (SwiftUI) - renders the mascot character
- [ ] `MascotSprite` - character artwork (SF Symbols + custom shapes, or asset catalog)
- [ ] `MascotAnimator` - idle animation controller (breathing, blinking)
- [ ] `MascotManager` - lifecycle management (show/hide, position persistence)
- [ ] Menu bar toggle: "Show/Hide Mascot"
- [ ] Window properties: `ignoresMouseEvents = true` when idle

#### Acceptance Criteria
- Mascot appears as a ~64x64 point character on bottom-right screen edge
- Gentle breathing animation loops smoothly (scale 1.0 -> 1.03 -> 1.0, 3s cycle)
- Occasional blink animation (every 4-6 seconds, randomized)
- Mascot does NOT interfere with clicking through to desktop/apps behind it
- Mascot stays on top of all windows
- Show/hide toggle works from menu bar
- Position persists across app restart
- CPU impact < 1% for idle animation

#### Technical Notes
- Use `NSWindow` with `.floating` level and `isOpaque = false`
- `backgroundColor = .clear` for transparent background
- `ignoresMouseEvents = true` during idle state
- SwiftUI animation with `.easeInOut` for breathing
- Timer-based blink trigger with randomized interval

#### Testing
- Unit: `MascotAnimator` state transitions
- Unit: `MascotManager` position persistence
- Integration: Window renders on screen correctly
- Manual: Visual verification of animations
- Screenshot: Capture mascot in idle state

---

### v1.0: Mascot Break Reminders - Mascot Comes Alive

**Status**: TODO

#### Scope
- Mascot reacts when break time arrives
- Becomes interactive (no longer click-through) during break reminders
- Animations: jumps up, waves arms, speech bubble with message
- Speech bubble shows break message ("Time to rest your eyes!")
- After break is acknowledged, mascot returns to idle
- Mascot supplements (not replaces) notification system

#### Deliverables
- [ ] `MascotBreakAnimator` - break-time animation sequences
- [ ] `SpeechBubbleView` (SwiftUI) - comic-style speech bubble
- [ ] Jump animation (translateY bounce, 0.5s)
- [ ] Wave animation (arm rotation, repeating)
- [ ] Integration with `BreakScheduler` - mascot reacts to break events
- [ ] `ignoresMouseEvents = false` during break reminder
- [ ] Tap mascot to acknowledge break / snooze

#### Acceptance Criteria
- When micro-break triggers, mascot jumps and waves
- Speech bubble appears with break message
- Speech bubble auto-dismisses after 10 seconds if no interaction
- Tapping mascot during reminder shows snooze/start-break options
- Mascot returns to idle after break is taken or snoozed
- Animation is smooth and delightful, not jarring
- Works alongside existing notification system (dual notification)

#### Testing
- Unit: Break animation trigger logic
- Unit: Speech bubble content generation
- Integration: `BreakScheduler` -> `MascotBreakAnimator` pipeline
- Manual: Visual verification of break animations
- Screenshot: Capture mascot in break-reminder state

---

### v1.1: Mascot Interactions - Click, Hover, Drag

**Status**: TODO

#### Scope
- Click mascot to see quick stats (today's score, breaks taken, time to next break)
- Hover shows tooltip with encouraging message
- Drag to reposition anywhere on screen
- Double-click to open popover/preferences
- Right-click context menu (hide, preferences, about)

#### Deliverables
- [ ] `MascotInteractionHandler` - gesture recognizer management
- [ ] Quick stats mini-popover (small, non-intrusive)
- [ ] Drag-to-reposition with snap-to-edge behavior
- [ ] Hover tooltip with rotating encouraging messages
- [ ] Right-click context menu
- [ ] Position persistence after drag
- [ ] Smooth transition: idle (click-through) -> interactive (hoverable)

#### Acceptance Criteria
- Single click shows mini stats popover near mascot
- Hover displays tooltip after 0.5s delay
- Drag works smoothly, mascot snaps to nearest screen edge on release
- Double-click opens main popover or preferences
- Right-click shows context menu with relevant options
- Mascot becomes interactive on mouse proximity (~20px radius)
- Returns to click-through when mouse moves away

#### Testing
- Unit: Snap-to-edge position calculation
- Unit: Proximity detection logic
- Integration: All gesture interactions work
- Manual: Drag, click, hover, right-click verification

---

### v1.2: Mascot Expressions & Moods

**Status**: TODO

#### Scope
- Mascot changes expression based on user's eye health behavior
- Happy face: good break compliance (score 80+)
- Neutral face: okay compliance (score 40-79)
- Worried face: poor compliance, long continuous use (score < 40)
- Sleepy face: late night usage (after 10 PM)
- Celebratory: when user takes a break voluntarily
- Sad: when emergency override is used

#### Deliverables
- [ ] `MascotMoodEngine` - determines mood from health data
- [ ] 6 expression states with artwork variants
- [ ] Smooth transition animations between expressions
- [ ] Mood changes trigger small animation (e.g., sparkles for happy)
- [ ] Mood history tracking (for fun stats)

#### Acceptance Criteria
- Mascot expression matches current health score range
- Expression transitions are smooth (crossfade, 0.3s)
- Sleepy expression activates after 10 PM regardless of score
- Celebratory animation plays on voluntary break
- Sad expression + tear animation on emergency override
- Mood updates within 5 seconds of score change

#### Testing
- Unit: `MascotMoodEngine` score-to-mood mapping
- Unit: Time-of-day mood override logic
- Integration: Score changes -> expression updates
- Manual: Visual verification of all 6 expressions
- Screenshot: Capture each expression state

---

## Phase 4: Enhancement (v1.3 - v1.7)

### v1.3: Eye Exercise Animations with Mascot

**Status**: TODO

#### Scope
- Guided eye exercise routines during breaks
- Mascot demonstrates the exercises (looks left, right, up, down, circles)
- 3 exercise routines: quick (20s), standard (60s), full (180s)
- Follow-the-dot pattern with mascot's eyes leading
- Progress indicator during exercise

#### Deliverables
- [ ] `EyeExerciseEngine` - exercise routine definitions
- [ ] `ExerciseAnimationView` (SwiftUI) - guided dot movement
- [ ] Mascot eye-tracking animation (eyes follow the exercise dot)
- [ ] Exercise selection UI (quick/standard/full)
- [ ] Completion celebration animation
- [ ] Exercise history tracking

#### Acceptance Criteria
- 3 distinct exercise routines with different durations
- Mascot's eyes follow the exercise pattern
- Smooth dot movement at comfortable pace
- Progress indicator shows exercise completion
- Celebration animation on completion (mascot claps/sparkles)
- Exercise counts toward break quality score

#### Testing
- Unit: Exercise routine timing and patterns
- Unit: Exercise completion tracking
- Integration: Exercise -> score impact
- Manual: Follow exercises, verify comfort

---

### v1.4: Medical Tips Carousel

**Status**: TODO

#### Scope
- Rotating ophthalmological tips from curated medical sources
- Tips shown in break overlay and mascot speech bubbles
- 50+ tips covering: eye strain, nutrition, environment, habits
- Category-based rotation (don't repeat same category consecutively)
- Tip of the day in daily report

#### Deliverables
- [ ] `MedicalTipsRepository` - curated tips database (JSON)
- [ ] `TipRotationEngine` - smart rotation with category awareness
- [ ] Tip display in break overlays
- [ ] Mascot speech bubble tip delivery
- [ ] "Tip of the Day" in daily report
- [ ] Tip bookmarking

#### Acceptance Criteria
- 50+ unique medical tips available
- Tips rotate without immediate repetition
- Tips are medically accurate (sourced from AAO, NEI, etc.)
- Tips display in break overlay and mascot speech bubble
- Tip of the Day appears in daily report
- User can bookmark favorite tips

#### Testing
- Unit: Tip rotation logic (no consecutive repeats)
- Unit: Category distribution
- Integration: Tips appear in correct contexts
- Manual: Read tips for accuracy review

---

### v1.5: Late Night Guardian (10 PM+ Mode)

**Status**: TODO

#### Scope
- Special mode activating after 10 PM (configurable)
- Warmer, gentler reminder tone
- Mascot gets sleepy (yawning, droopy eyes)
- Shortened break intervals (15 min instead of 20)
- "Time to sleep" escalation at midnight, 1 AM, 2 AM
- Blue light awareness notification

#### Deliverables
- [ ] `LateNightGuardian` - time-based mode activation
- [ ] Sleepy mascot animations (yawn, droopy eyes, nightcap)
- [ ] Warmer notification copy ("Your eyes need rest, it's getting late...")
- [ ] Progressive "time to sleep" escalation
- [ ] Configurable activation time in preferences
- [ ] Blue light reminder integration

#### Acceptance Criteria
- Mode activates at configured time (default 10 PM)
- Mascot switches to sleepy expression
- Break intervals shorten to 15 min
- Escalation at midnight: gentle, 1 AM: moderate, 2 AM: strong
- User can disable late night mode in preferences
- Mode deactivates at configured morning time (default 6 AM)

#### Testing
- Unit: Time-based activation logic
- Unit: Escalation level progression
- Integration: Mode switch -> interval change
- Manual: Test at configured late night time

---

### v1.6: Color Balance Suggestions

**Status**: TODO

#### Scope
- Analyze current screen color palette
- Suggest eye-friendly color adjustments
- Recommend Dark Mode when ambient is dim (time-based heuristic)
- Integration with macOS appearance settings
- Color temperature awareness

#### Deliverables
- [ ] `ColorAnalyzer` - screen color sampling (CGWindowListCreateImage)
- [ ] `ColorSuggestionEngine` - generate recommendations
- [ ] Suggestion notification with one-click apply
- [ ] Dark Mode toggle suggestion based on time of day
- [ ] Color contrast checker

#### Acceptance Criteria
- Color analysis runs periodically (every 30 min)
- Suggestions are actionable and non-intrusive
- Dark Mode suggestion appears at sunset time
- User can dismiss suggestions permanently per-type
- Privacy: no screenshot data is stored

#### Testing
- Unit: Color analysis algorithms
- Unit: Suggestion generation logic
- Integration: Periodic analysis runs correctly
- Manual: Verify suggestion relevance

---

### v1.7: Dashboard View + Historical Charts

**Status**: TODO

#### Scope
- Dashboard popover or separate window
- Today's detailed breakdown with charts
- 7-day health score trend line
- 7-day screen time bar chart
- Break compliance trend
- SwiftUI Charts (macOS 14+)

#### Deliverables
- [ ] `DashboardView` (SwiftUI) - main dashboard layout
- [ ] `HealthScoreChart` - 7-day line chart
- [ ] `ScreenTimeChart` - 7-day bar chart
- [ ] `BreakComplianceChart` - compliance percentage trend
- [ ] `HistoricalDataStore` - persist daily summaries (SQLite or JSON)
- [ ] Data retention: 90 days (configurable)

#### Acceptance Criteria
- Dashboard shows today's score with breakdown
- 7-day charts render with actual historical data
- Empty state handled gracefully for first-time users
- Charts use Swift Charts framework
- Data persists across app restarts
- Historical data retained per configured retention

#### Testing
- Unit: Historical data storage and retrieval
- Unit: Chart data transformation
- Integration: Charts render with sample data
- Manual: Visual verification of chart accuracy

---

## Phase 5: Intelligence (v1.8 - v2.0)

### v1.8: Sound Effects + Nature Sounds During Breaks

**Status**: TODO

#### Scope
- Subtle notification chimes (break due, break complete)
- Nature sound playback during breaks (rain, forest, ocean, birds)
- Volume control independent of system volume
- Configurable in preferences (on/off, volume, sound selection)
- Respects macOS Focus/Do Not Disturb

#### Deliverables
- [ ] `SoundManager` - AVFoundation-based audio playback
- [ ] 4+ nature sound loops (bundled, royalty-free)
- [ ] Notification chime sounds
- [ ] Sound preferences UI
- [ ] Focus mode integration

#### Acceptance Criteria
- Chimes play on break trigger and completion
- Nature sounds loop during break duration
- Sounds respect mute toggle in preferences
- Volume slider works independently
- Sounds stop immediately when break ends
- No audio artifacts or pops

#### Testing
- Unit: `SoundManager` state machine
- Integration: Sounds play at correct events
- Manual: Audio quality verification

---

### v1.9: LLM Integration - Personalized Health Analysis (Claude API)

**Status**: TODO

#### Scope
- Claude API integration for personalized health insights
- Weekly health analysis based on accumulated data
- Natural language tips tailored to user's patterns
- Conversational mascot (ask the mascot health questions)
- Privacy-first: only aggregated stats sent, never raw data

#### Deliverables
- [ ] `ClaudeAPIClient` - Anthropic SDK integration
- [ ] `HealthAnalyzer` - prepares anonymized usage summary
- [ ] Weekly analysis report (LLM-generated section)
- [ ] Conversational mascot interface (text input near mascot)
- [ ] API key management in Keychain
- [ ] Offline fallback (pre-written tips when no API)

#### Acceptance Criteria
- Weekly analysis generated from 7-day usage data
- Analysis is personalized and actionable
- API key stored securely in Keychain
- Graceful fallback when offline or no API key
- No raw timestamps or personal data sent to API
- Response displayed in mascot speech bubble or report

#### Testing
- Unit: Data anonymization logic
- Unit: API client error handling
- Integration: End-to-end analysis generation (mock API)
- Manual: Verify analysis relevance

---

### v2.0: ML Adaptive Timing - Learn User's Optimal Break Patterns

**Status**: TODO

#### Scope
- On-device Core ML model learns user's patterns
- Predicts optimal break timing based on:
  - Time of day productivity patterns
  - Break compliance history
  - Session duration patterns
  - Day of week variations
- Suggests personalized break schedule
- Adjusts intervals automatically (with user consent)

#### Deliverables
- [ ] `PatternLearner` - Core ML tabular regression model
- [ ] `BreakPredictor` - predicts optimal next break time
- [ ] Training data collection (30-day minimum before activation)
- [ ] "Smart Timing" toggle in preferences
- [ ] Model retraining on weekly schedule
- [ ] Prediction explanation in mascot tooltip

#### Acceptance Criteria
- Model trains only on-device (no cloud training)
- Requires 30+ days of data before activation
- Predictions stay within reasonable bounds (10-40 min intervals)
- User can toggle smart timing on/off
- Model improves over time (measured by break compliance)
- Clear explanation of why a break is suggested at this time

#### Testing
- Unit: Feature extraction from historical data
- Unit: Prediction bounds enforcement
- Integration: Model training and inference pipeline
- Manual: Verify predictions feel reasonable after 30 days

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
| Screenshots | Auto-capture visual verification for UI changes |

### Version Tagging

```
git tag -a v0.1 -m "Project skeleton + basic timer + menu bar icon"
git tag -a v0.2 -m "Pipeline wiring + bug fixes + tests + Logger"
git tag -a v0.3 -m "20-20-20 micro-break notifications"
...
git tag -a v1.0 -m "Mascot break reminders"
...
git tag -a v2.0 -m "ML adaptive timing"
```

### Rollback Strategy

If an iteration introduces regressions:
1. Identify failing tests
2. Fix forward if possible (< 10 min)
3. Revert to previous version tag if fix is complex
4. Document regression cause in iteration notes

---

## Dependency Graph

```
                    CORE
v0.1 ── v0.2 ── v0.3 ── v0.4 ── v0.5
                  │         │       │
                  │         │       ▼
                  │         │     SCORE & REPORTS
                  │         │     v0.6 ── v0.7 ── v0.8
                  │         │       │                │
                  │         │       │                ▼
                  │         │       │              MASCOT (USER PRIORITY)
                  │         ▼       │       v0.9 ── v1.0 ── v1.1 ── v1.2
                  │       v0.4      │         │       │               │
                  │     (overlay    │         │       │               ▼
                  │      tech)      │         │       │          ENHANCEMENT
                  │         │       │         │       │     v1.3 ── v1.4 ── v1.5
                  │         │       │         │       │       │               │
                  │         │       │         │       │       │               ▼
                  │         │       │         │       │       │     v1.6 ── v1.7
                  │         │       │         │       │       │               │
                  │         │       │         │       │       │               ▼
                  │         │       │         │       │       │          INTELLIGENCE
                  │         │       │         │       │       │     v1.8 ── v1.9 ── v2.0
                  │         │       │         │       │       │
                  └─────────┴───────┴─────────┴───────┴───────┘
                         Linear dependency chain
```

**Critical paths**:
- Core: v0.1 -> v0.2 -> v0.3 (timer -> pipeline -> notifications)
- Score: v0.3 -> v0.6 (break data -> scoring)
- Mascot: v0.8 -> v0.9 (preferences -> mascot settings)
- Intelligence: v0.6 + v1.2 -> v1.9 (score data + mascot -> LLM analysis)

---

*Document version: 2.0*
*Last updated: 2026-04-14*
*Author: PM Agent*
*Supersedes: iteration-plan.md (v1)*
