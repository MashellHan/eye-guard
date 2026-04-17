# EyeGuard - Feature Inventory Index

## 📚 Documentation Files

This directory contains comprehensive documentation of all EyeGuard features:

### 1. **FEATURE_INVENTORY.md** (1404 lines)
   - **Complete detailed reference** for all 17 major systems
   - Technical deep-dive into each feature
   - Code examples, formulas, and implementation details
   - Data structures and algorithm explanations
   - File locations and integration points
   
   **Best for:** Architecture reviews, implementation understanding, technical documentation

### 2. **FEATURE_SUMMARY.txt** (13 KB)
   - **Quick reference guide** with visual formatting
   - High-level overview of all features
   - Directory structure and file organization
   - Test coverage summary
   - Technology stack and medical guidelines
   - Notable features highlight
   
   **Best for:** Quick lookups, project overviews, feature lists

## 🎯 The 17 Major Features

| # | Feature | Files | Key Highlights |
|---|---------|-------|-----------------|
| 1 | **Break System** | BreakScheduler.swift, BreakType.swift | 3 break types, hierarchical reset, idle integration |
| 2 | **Notification System** | NotificationManager.swift, OverlayWindow.swift | 3-tier escalation, callbacks, snooze support |
| 3 | **Mascot System** | MascotView.swift, MascotState.swift (8 files) | 7 states, mouse tracking, animations |
| 4 | **Eye Exercises** | EyeExercise.swift, ExerciseView.swift | 5 routines, bilingual, pupil patterns |
| 5 | **Medical Tips** | TipDatabase.swift, EyeHealthTip.swift | 25 tips, bilingual, AAO/WHO/OSHA sourced |
| 6 | **Health Score** | HealthScoreCalculator.swift | 4 components (40+30+20+10=100), trend tracking |
| 7 | **Night Mode** | NightModeManager.swift | Auto after 10 PM, special messages, tracking |
| 8 | **Color Balance** | ColorAnalyzer.swift | 7 color families, complementary suggestions |
| 9 | **Sound System** | SoundManager.swift | System sounds + procedural ambient audio |
| 10 | **Dashboard** | DashboardView.swift, HistoryManager.swift | 3 tabs, charts, 7/30-day history |
| 11 | **Daily Reports** | DailyReportGenerator.swift | Markdown, 10+ sections, recommendations |
| 12 | **LLM Integration** | InsightGenerator.swift, LLMService.swift | Rule-based + LLM-ready, multiple formats |
| 13 | **Activity Monitor** | ActivityMonitor.swift | Idle detection, screen lock, daily rollover |
| 14 | **Preferences** | UserPreferencesManager.swift, PreferencesView.swift | Customizable intervals, toggles, settings |
| 15 | **Menu Bar** | MenuBarView.swift, EyeGuardApp.swift | Countdown, popover, always-on-top |
| 16 | **App Lifecycle** | EyeGuardApp.swift, AppDelegate.swift | MenuBarExtra, bundle config, permissions |
| 17 | **Data Persistence** | DataPersistenceManager.swift | JSON files, 5-min saves, async I/O |

## 📊 Project Statistics

- **Total Swift Files**: 49 (36 source + 13 test)
- **Lines of Code**: ~5,000+ production code
- **Directories**: 18 organized modules
- **Test Suites**: 13 comprehensive test files
- **Architecture**: Protocol-oriented with dependency injection
- **Language**: Swift 6.0 with strict concurrency
- **Platform**: macOS 14.0+

## 🗂️ Module Organization

```
Sources/
├── AI/              (2 files)  - LLM & insights
├── Analysis/        (2 files)  - Color analysis
├── App/             (6 files)  - Lifecycle & UI
├── Audio/           (1 file)   - Sound management
├── Dashboard/       (3 files)  - Analytics
├── Exercises/       (3 files)  - Eye workouts
├── Mascot/          (8 files)  - Floating character
├── Models/          (1 file)   - Data structures
├── Monitoring/      (1 file)   - Activity tracking
├── Notifications/   (4 files)  - Break alerts
├── Persistence/     (1 file)   - Data storage
├── Protocols/       (5 files)  - Interfaces
├── Reporting/       (3 files)  - Reports & scoring
├── Scheduling/      (2 files)  - Break scheduling
├── Tips/            (3 files)  - Medical database
└── Utils/           (4 files)  - Utilities
```

## 🔑 Key Features at a Glance

✅ **3-Tier Notification Escalation**
- Tier 1: System banner (immediate)
- Tier 2: Floating overlay (2 min delay)
- Tier 3: Full-screen overlay (5 min delay, mandatory only)

✅ **7 Mascot Emotional States**
- Idle, Happy, Concerned, Alerting, Sleeping, Exercising, Celebrating

✅ **5 Eye Exercises**
- Look Around, Near-Far Focus, Circular Motion, Palm Warming, Rapid Blink

✅ **4-Component Health Score (0-100)**
- Break Compliance (40 pts)
- Continuous Use Discipline (30 pts)
- Screen Time Score (20 pts)
- Break Quality (10 pts)

✅ **Medical Basis**
- AAO 20-20-20 rule
- OSHA hourly breaks
- EU 2-hour mandatory breaks
- WHO outdoor time recommendations

✅ **Bilingual Support**
- English + Chinese throughout
- 25 medical tips in both languages
- 8 night messages + 3 break messages

✅ **Procedural Audio**
- Rain, Ocean, Forest, Wind ambient sounds
- No external audio files needed
- AVAudioEngine with real-time synthesis

✅ **Dashboard Analytics**
- Today tab with health gauge
- History tab with 7/30-day charts
- Breakdown tab with component pie chart

✅ **Smart Persistence**
- JSON files survive app crashes
- 5-minute automatic saves
- Daily rollover at midnight

## 🎓 How to Use These Documents

### For Feature Development
1. Read the feature section in **FEATURE_INVENTORY.md**
2. Check the file locations and dependencies
3. Review test cases in the test suite
4. Examine the related source files

### For System Understanding
1. Start with **FEATURE_SUMMARY.txt** for overview
2. Review the directory structure
3. Read the feature section for deep dive
4. Check architecture patterns section

### For Bug Fixes
1. Identify the feature in the 17-feature table
2. Find the related files in the inventory
3. Review the implementation details
4. Check test cases for expected behavior

### For New Features
1. Identify related existing features
2. Review protocols and dependency injection pattern
3. Check models and data structures
4. Plan test coverage using existing test structure

## 📝 Document Locations

```
EyeGuard Project Root/
├── FEATURE_INVENTORY.md    ← Detailed technical reference (1404 lines)
├── FEATURE_SUMMARY.txt     ← Quick visual summary (13 KB)
├── FEATURE_INDEX.md        ← This file (navigation guide)
├── README.md               ← Project overview
└── EyeGuard/Sources/       ← All source code (49 files)
```

## 🔗 Cross-References

### Features by Category

**Eye Health**
- Break System (#1)
- Eye Exercises (#4)
- Medical Tips (#5)
- Health Score (#6)
- Activity Monitor (#13)

**User Experience**
- Mascot System (#3)
- Notifications (#2)
- Sound System (#9)
- Night Mode (#7)

**Analytics & Insights**
- Health Score (#6)
- Dashboard (#10)
- Daily Reports (#11)
- LLM Integration (#12)

**Technical Infrastructure**
- Data Persistence (#17)
- Preferences (#14)
- App Lifecycle (#16)
- Menu Bar (#15)
- Activity Monitor (#13)

**Color & Ambience**
- Color Balance (#8)
- Night Mode (#7)
- Sound System (#9)

## 📞 Quick Navigation

**Need information about...**
- Break scheduling? → Section 2, BreakScheduler.swift
- Notifications? → Section 3, NotificationManager.swift
- Mascot character? → Section 4, MascotView.swift
- Eye exercises? → Section 5, EyeExercise.swift
- Medical tips? → Section 6, TipDatabase.swift
- Health scoring? → Section 7, HealthScoreCalculator.swift
- Night mode? → Section 8, NightModeManager.swift
- Color analysis? → Section 9, ColorAnalyzer.swift
- Sound effects? → Section 10, SoundManager.swift
- Dashboard? → Section 11, DashboardView.swift
- Daily reports? → Section 12, DailyReportGenerator.swift
- AI insights? → Section 13, InsightGenerator.swift
- Activity tracking? → Section 14, ActivityMonitor.swift
- Settings? → Section 15, UserPreferencesManager.swift
- Menu bar? → Section 16, MenuBarView.swift
- App startup? → Section 17, EyeGuardApp.swift
- Data storage? → Section 18, DataPersistenceManager.swift

---

**Last Updated**: April 15, 2026  
**Version**: 1.0  
**Total Features Documented**: 17 major systems + 49 files
