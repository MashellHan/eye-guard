# EyeGuard

Medical-grade eye health guardian for macOS. Smart screen time monitoring with evidence-based break reminders following the AAO 20-20-20 rule.

## Screenshots

### 阿普 (Mascot)
<!-- Replace with actual screenshot: the cute mint-green creature mascot floating on desktop -->
![阿普 - EyeGuard Mascot](screenshots/mascot.png)

### Break Reminder Overlay
<!-- Replace with actual screenshot: full-screen semi-transparent overlay with mascot, countdown ring, and health tip -->
![Break Reminder](screenshots/break-overlay.png)

### Menu Bar
<!-- Replace with actual screenshot: menu bar popover with health score, timer, and controls -->
![Menu Bar](screenshots/menubar.png)

## Display Modes

Eye Guard ships with **two mutually-exclusive display surfaces**. Pick the one that matches your workflow — switch anytime from the menu-bar picker, and your choice persists across launches.

### Apu Mascot (default)

The original mint-green creature that lives in the corner of your screen, reacts to your break cadence, and floats a speech bubble with health tips. Best when you want a warm, always-visible companion.

### Dynamic Notch (Island-merge, new in v4.0)

Inspired by [MioIsland](https://github.com/MioMioOS/MioIsland), the Notch mode reuses the MacBook's camera-housing area as a glanceable status surface.

- **Collapsed state**: a small color-coded status dot (green → yellow → red as your continuous-use time climbs past 10 / 15 / 20 minutes) next to the current `MM:SS` timer.
- **Expanded state** (hover or click): today's health score, countdown to the next break, and a **Break Now** button.
- **Pop banner**: pre-break alerts appear as a typewriter-animated banner sliding out of the notch instead of a separate overlay window.
- **Preferences**: horizontal offset (±30pt), hover-activation speed (instant / fast / normal / slow), and an opt-in software notch on external monitors.

All underlying business logic — `BreakScheduler`, `ActivityMonitor`, eye-exercise sessions, tips, dashboard, health score — is shared between both modes. Notch is a pure view layer, not a rewrite.

See `.island_merge/phases/*.md` for the phased rewrite plan and `CHANGELOG.md` for the v4.0 entry.

## Features

### Core Protection
- **20-20-20 Rule**: Micro-breaks every 20 minutes (look 20ft away for 20 seconds)
- **Hourly Macro-Breaks**: 5-minute breaks every hour (OSHA guidelines)
- **Mandatory Breaks**: 15-minute breaks every 2 hours (EU directive)
- **3-Tier Notification Escalation**: System notification -> Floating overlay -> Full-screen overlay
- **Idle Detection**: Auto-pauses timers when you step away
- **Smart Snooze**: 5-minute snooze with auto-resume

### Health Monitoring
- **Real-time Health Score** (0-100): Break compliance, continuous use discipline, screen time, break quality
- **Score Trend Tracking**: Improving, stable, or declining indicators
- **Daily Markdown Reports**: Auto-generated with hourly breakdown, compliance stats, and recommendations
- **Data Persistence**: JSON-based daily data with app restart continuity

### Dashboard & Analytics
- **Interactive Dashboard**: Today, History, and Breakdown tabs
- **SwiftUI Charts**: Daily screen time bar charts + health score trend lines
- **7/30 Day History**: Historical data visualization from daily JSON files
- **Pie Chart Breakdown**: Score component visualization

### Mascot — 阿普 (Apu)
- **Floating Character**: Draggable, always-on-top companion
- **Cute Creature Design**: Mint-green body, bean eyes, blush cheeks, tiny legs
- **5 Emotional States**: Idle, concerned, alerting, resting, celebrating
- **Mouse Tracking**: Eyes follow your cursor
- **Speech Bubbles**: Contextual tips, break reminders, AI insights
- **Hand Gestures**: Eye-rubbing, looking far, eye exercises
- **Right-Click Menu**: Quick access to breaks, exercises, tips, dashboard, quit

### Eye Exercises (眼保健操)
- **5 Guided Routines**: Focus shifting, figure-8, circle rotation, distance gazing, palming
- **Animated Instructions**: Step-by-step visual guidance
- **Progress Tracking**: Exercise completion with mascot celebration

### Medical Tips
- **25 Evidence-Based Tips**: Sourced from AAO, WHO, NIOSH, and peer-reviewed research
- **Bilingual Support**: English titles with Chinese descriptions
- **Tip Rotation**: New tip every 30 minutes via mascot speech bubble
- **Daily Tip of the Day**: Featured in daily reports

### Late Night Guardian (v1.4)
- **Night Mode Detection**: Auto-activates after 10 PM
- **Sleep Reminders**: Periodic gentle reminders to rest
- **Night-Time Styling**: Warm amber tints for reduced stimulation
- **Screen Time Tracking**: Night-specific usage monitoring

### Color Balance (v1.5)
- **Screen Color Analysis**: Periodic sampling of dominant screen colors
- **Complementary Color Suggestions**: Recommends balancing colors to reduce strain
- **Color History Tracking**: Hourly color family trends

### Sound Effects (v1.6)
- **Break Notifications**: Audio alerts for break reminders
- **Ambient Nature Sounds**: Ocean, rain, forest, wind during breaks
- **Celebration Sounds**: Audio feedback for completed breaks
- **Volume Control**: Adjustable volume with mute option

### AI Insights (v1.8)
- **LLM-Ready Architecture**: Protocol-based design with LocalLLMService and ClaudeLLMService placeholder
- **Rule-Based Insight Engine**: Smart analysis without external API dependency
- **Daily Report Insights**: AI-generated analysis section in Markdown reports
- **Mascot Insights**: Periodic AI insights via speech bubble (every 2 hours)
- **Menu Bar Summary**: Contextual insight in popover
- **Hourly Pattern Analysis**: Best/worst hour identification

### Performance (v1.9)
- **Optimized Timer**: Heavy operations on 5-second cadence, UI on 1-second
- **Static DateFormatters**: Shared instances eliminate repeated allocations
- **Reusable Calculators**: Single HealthScoreCalculator instance per scheduler
- **Launch Time Tracking**: Monitors startup performance (<1s target)

### Reminder Modes (v2.4)
- **Gentle / Aggressive / Strict / Custom**: Preset notification intensity levels
- **Aggressive (Default)**: Floating popup for micro/macro breaks, full-screen for mandatory
- **Mode-Aware Dismiss Policy**: Skippable, Postpone Only, or Mandatory per break type
- **Break Absorption**: When multiple breaks align, highest priority fires, others reset silently
- **Postpone System**: Delay breaks up to 2 times (5 min each) for Postpone Only policy

### Preferences
- **Customizable Intervals**: Adjust break timing to your workflow
- **Toggle Break Types**: Enable/disable micro, macro, or mandatory breaks
- **Sound Settings**: Enable/disable notification and ambient sounds
- **Notification Escalation**: Configure escalation behavior

## Build

```bash
# Build and run
swift build
swift run EyeGuard

# Run tests
swift test

# Build app bundle
bash scripts/build-app.sh

# Launch app
open EyeGuard.app
```

## Requirements

- macOS 14.0 (Sonoma) or later
- Accessibility permissions (for activity monitoring)
- Notification permissions (for break reminders)

## Architecture

```
EyeGuard/Sources/
├── AI/                 # LLM service protocol + insight generator
├── Analysis/           # Color analysis engine
├── App/                # App entry, menu bar, preferences
├── Audio/              # Sound effects and ambient audio
├── Dashboard/          # Analytics dashboard with Charts
├── Exercises/          # Guided eye exercise routines
├── Mascot/             # Floating mascot character
├── Models/             # Core data models
├── Monitoring/         # Activity monitor (keyboard/mouse)
├── Notifications/      # 3-tier notification system
├── Persistence/        # JSON data persistence
├── Protocols/          # Dependency injection protocols
├── Reporting/          # Daily report generation + health score
├── Scheduling/         # Break scheduler engine
├── Tips/               # Medical tip database
└── Utils/              # Constants, logging, formatting
```

## Medical Basis

EyeGuard uses three types of breaks targeting different physiological systems. Even if you rest your eyes every 20 minutes, a 120-minute mandatory break is still necessary because each break type serves a distinct purpose.

### Why Three Break Types?

| Break Type | Interval | Duration | Physiological Target | Source |
|------------|----------|----------|---------------------|--------|
| **Micro Break** | 20 min | 20 sec | Ciliary muscle accommodation spasm (near-focus fatigue) | AAO 20-20-20 Rule (Jeffrey Anshel) |
| **Macro Break** | 60 min | 5 min | Musculoskeletal strain, RSI, postural fatigue | OSHA Computer Workstation Guidelines |
| **Mandatory Break** | 120 min | 15 min | Deep vein thrombosis risk, systemic circulation, cognitive reset | EU Directive 90/270/EEC, NIOSH |

- **Micro breaks** relax the ciliary muscles in your eyes. Looking 20 feet away lets the lens flatten, reducing accommodation strain. This prevents digital eye strain (Computer Vision Syndrome).
- **Macro breaks** address your whole body. After an hour, your neck, shoulders, and back need movement. Static posture leads to repetitive strain injuries that 20 seconds of distance gazing cannot fix.
- **Mandatory breaks** protect against prolonged sitting risks. After 2+ hours of continuous computer use, blood pooling in the legs increases DVT risk, and cognitive performance degrades. A 15-minute break allows systemic circulation recovery and mental reset.

### Reminder Modes

EyeGuard offers preset reminder modes (like "Typical/Custom" in software installers):

| Setting | Gentle | Aggressive (Default) | Strict |
|---------|--------|---------------------|--------|
| Micro notification | System banner | Floating popup | Full screen |
| Micro dismiss | Skippable | Skippable | Mandatory |
| Macro notification | Floating popup | Floating popup | Full screen |
| Macro dismiss | Skippable | Skippable | Postpone only (2x) |
| Mandatory notification | Full screen | Full screen | Full screen |
| Mandatory dismiss | Skippable | Postpone only (2x) | Mandatory |
| Escalation | Tiered (2m then 5m) | Direct (no wait) | Direct |

- **Gentle**: For users who want minimal interruption. All breaks can be freely skipped.
- **Aggressive** (recommended): Prominent floating popups appear immediately. Mandatory breaks can only be postponed twice.
- **Strict**: Maximum enforcement. Full-screen overlays for all breaks. Mandatory breaks cannot be dismissed.
- **Custom**: Configure each break type's notification tier and dismiss policy individually.

### References

- American Academy of Ophthalmology (AAO): 20-20-20 Rule
- OSHA: Computer Workstation Guidelines (regular hourly breaks)
- EU Screen Equipment Directive 90/270/EEC (mandatory breaks every 2 hours)
- WHO: Regular breaks and ergonomic positioning
- NIOSH: Eye strain prevention guidelines
- Cornell University Ergonomics: Computer Vision Syndrome research

## Tech Stack

- Swift 6.0 with strict concurrency
- SwiftUI + AppKit (menu bar, floating windows)
- SwiftUI Charts (dashboard visualization)
- Swift Testing framework
- os.Logger for structured logging
- Protocol-oriented architecture with dependency injection

## License

MIT
