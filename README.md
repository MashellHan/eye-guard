# EyeGuard

Medical-grade eye health guardian for macOS. Smart screen time monitoring with evidence-based break reminders following the AAO 20-20-20 rule.

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

### Mascot (护眼精灵)
- **Floating Character**: Draggable, always-on-top companion
- **7 Emotional States**: Idle, happy, concerned, alerting, sleeping, exercising, celebrating
- **Mouse Tracking**: Pupils follow your cursor
- **Speech Bubbles**: Contextual tips, break reminders, AI insights
- **Right-Click Menu**: Quick access to breaks, exercises, tips, dashboard

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

- **AAO 20-20-20 Rule**: Every 20 min, look 20 feet away for 20 seconds
- **OSHA**: Regular breaks for computer workers (hourly)
- **EU Screen Equipment Directive**: Mandatory breaks every 2 hours
- **WHO**: Regular breaks and ergonomic positioning
- **NIOSH**: Eye strain prevention guidelines
- Break intervals based on peer-reviewed Computer Vision Syndrome research

## Tech Stack

- Swift 6.0 with strict concurrency
- SwiftUI + AppKit (menu bar, floating windows)
- SwiftUI Charts (dashboard visualization)
- Swift Testing framework
- os.Logger for structured logging
- Protocol-oriented architecture with dependency injection

## License

MIT
