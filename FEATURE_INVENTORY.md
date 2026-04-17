# EyeGuard - Comprehensive Feature Inventory

**Project Location**: `/Users/mengxionghan/.superset/projects/Tmp/eye-guard`  
**Language**: Swift 6.0 (strict concurrency)  
**Platform**: macOS 14.0+  
**Architecture**: Protocol-oriented with dependency injection  
**Test Framework**: Swift Testing  

---

## 1. PROJECT STRUCTURE

### Source Organization (49 Swift files total)
```
EyeGuard/Sources/
├── AI/                    # LLM integration & insights
│   ├── InsightGenerator.swift
│   └── LLMService.swift
├── Analysis/              # Color analysis engine
│   ├── ColorAnalyzer.swift
│   └── ColorSuggestionView.swift
├── App/                   # Application lifecycle & UI
│   ├── AppDelegate.swift
│   ├── EyeGuardApp.swift
│   ├── MenuBarView.swift
│   ├── PreferencesView.swift
│   ├── PreferencesWindowController.swift
│   └── UserPreferencesManager.swift
├── Audio/                 # Sound effects & ambient audio
│   └── SoundManager.swift
├── Dashboard/             # Analytics & visualization
│   ├── DashboardView.swift
│   ├── DashboardWindowController.swift
│   └── HistoryManager.swift
├── Exercises/             # Eye exercise routines
│   ├── ExerciseSessionView.swift
│   ├── ExerciseView.swift
│   └── EyeExercise.swift
├── Mascot/                # Floating character system
│   ├── MascotAnimations.swift
│   ├── MascotContainerView.swift
│   ├── MascotState.swift
│   ├── MascotStateSync.swift
│   ├── MascotView.swift
│   ├── MascotViewModel.swift
│   ├── MascotWindowController.swift
│   └── SpeechBubbleView.swift
├── Models/                # Core data models
│   └── Models.swift
├── Monitoring/            # Activity tracking
│   └── ActivityMonitor.swift
├── Notifications/         # Break notification system
│   ├── BreakOverlayView.swift
│   ├── FullScreenOverlayView.swift
│   ├── NotificationManager.swift
│   └── OverlayWindow.swift
├── Persistence/           # Data storage
│   └── DataPersistenceManager.swift
├── Protocols/             # Dependency injection interfaces
│   ├── ActivityMonitoring.swift
│   ├── ColorAnalyzing.swift
│   ├── NotificationSending.swift
│   ├── ReportDataProviding.swift
│   └── SoundPlaying.swift
├── Reporting/             # Reports & health scoring
│   ├── DailyReportGenerator.swift
│   ├── HealthScoreCalculator.swift
│   └── ReportDataProvider.swift
├── Scheduling/            # Break scheduling engine
│   ├── BreakScheduler.swift
│   └── BreakType.swift
├── Tips/                  # Medical tips database
│   ├── EyeHealthTip.swift
│   ├── TipBubbleView.swift
│   └── TipDatabase.swift
└── Utils/                 # Utilities & constants
    ├── Constants.swift
    ├── Logging.swift
    ├── NightModeManager.swift
    └── TimeFormatting.swift
```

### Test Coverage (13 test files)
- AIInsightTests.swift
- BreakSchedulerTests.swift
- ColorAnalyzerTests.swift
- DailyReportGeneratorTests.swift
- DashboardTests.swift
- DataPersistenceTests.swift
- EyeGuardTests.swift
- HealthScoreCalculatorTests.swift
- NightModeManagerTests.swift
- NotificationManagerTests.swift
- OverlayWindowTests.swift
- PreferencesTests.swift
- SoundManagerTests.swift

---

## 2. BREAK SYSTEM (Medical Guidelines-Based)

### Overview
Three-tier break scheduling following medical guidelines:
- **Source Code**: `BreakScheduler.swift`, `BreakType.swift`
- **Implementation**: @Observable @MainActor actor with 1-second tick loop
- **Data Models**: `Models.swift` (BreakEvent, UsageSession, HealthScore)

### Break Types & Scheduling

| Break Type | Interval | Duration | Medical Source | Rule Description |
|-----------|----------|----------|----------------|------------------|
| **Micro** | 20 min | 20 sec | AAO (American Academy of Ophthalmology) | 20-20-20 Rule: Look 20ft away for 20 sec |
| **Macro** | 60 min | 5 min | OSHA (Occupational Safety & Health) | Hourly break every hour |
| **Mandatory** | 120 min | 15 min | EU Screen Equipment Directive | Forced break every 2 hours |

### Key Features

#### 1. **Hierarchical Break Reset** (H5/BUG-001)
When a break is taken, appropriate timers are reset:
- **Micro taken**: Only micro timer resets
- **Macro taken**: Macro + micro timers reset
- **Mandatory taken**: All three timers reset

#### 2. **Per-Break-Type Elapsed Tracking** (H5)
- Separate `elapsedPerType` dictionary tracks each break type independently
- Prevents micro-break interference with macro/mandatory scheduling
- Enables accurate timer calculations across all three types

#### 3. **Double-Fire Prevention** (BUG-003)
- Maintains `lastNotifiedCycle` per break type
- Only fires notification when crossing into a new cycle
- Prevents duplicate notifications at boundary conditions

#### 4. **Idle Detection Integration** (H1)
- Polls ActivityMonitor every 5 ticks (5 seconds)
- When idle detected: resets micro-timer (user is resting)
- When activity resumes: resets session duration
- Prevents penalizing users for natural screen breaks

#### 5. **Daily Rollover** (Midnight Reset)
- Checks date daily via Calendar.current
- Resets all counters at midnight
- Maintains yesterday's data for trending

#### 6. **Session Tracking**
- `sessionStartTime`: When current continuous session started
- `currentSessionDuration`: Tracks elapsed time in session
- `longestContinuousSession`: Records peak continuous usage
- `totalScreenTimeToday`: Accumulates across all sessions

#### 7. **Data Persistence** (Every 5 minutes)
- Async save to JSON via DataPersistenceManager
- Survives app crashes/restarts
- Restores break events and screen time on app launch

#### 8. **Notification Triggering**
- Calls NotificationManager.notify() with break type and health score
- Stores callbacks for break taken/skipped actions
- Integrated with three-tier escalation system

### Constants
```swift
enum EyeGuardConstants {
    // Intervals
    static let microBreakInterval = 20 * 60           // 20 minutes
    static let macroBreakInterval = 60 * 60           // 60 minutes
    static let mandatoryBreakInterval = 120 * 60      // 120 minutes
    
    // Durations
    static let microBreakDuration = 20                // 20 seconds
    static let macroBreakDuration = 5 * 60            // 5 minutes
    static let mandatoryBreakDuration = 15 * 60       // 15 minutes
    
    // Idle threshold
    static let idleThreshold = 30                     // 30 seconds
    
    // Escalation delays
    static let tier1EscalationDelay = 2 * 60          // 2 minutes
    static let tier2EscalationDelay = 5 * 60          // 5 minutes
    
    // Max snooze
    static let maxSnoozeDuration = 5 * 60             // 5 minutes
}
```

---

## 3. NOTIFICATION SYSTEM (3-Tier Escalation)

### Architecture
**Source Files**: `NotificationManager.swift`, `OverlayWindow.swift`, `BreakOverlayView.swift`, `FullScreenOverlayView.swift`

### Notification Tiers

#### **Tier 1: Gentle (macOS UserNotification)**
- **Display**: System banner notification
- **Delay**: Immediate (when break due)
- **Dismissible**: Yes
- **Content**: Break type name + medical rule description
- **Sound**: Default system sound
- **Implementation**: `UNUserNotificationCenter`

```
┌─────────────────────────────────────┐
│ Time for a Micro Break              │
│ 20-20-20 Rule: Every 20 min...     │
└─────────────────────────────────────┘
```

#### **Tier 2: Firm (Floating Overlay Window)**
- **Display**: Semi-transparent floating window, 30-sec countdown
- **Trigger**: After 2 minutes if Tier 1 ignored
- **Buttons**: "Take Break Now", "Skip Break", "Snooze"
- **Content**: Break type icon, health score gauge, rule reminder
- **Window**: Stays on top, non-modal
- **Implementation**: `OverlayWindowController`, custom SwiftUI overlay view

```
┌──────────────────────┐
│ 🏃 Take Your Break!  │
│ ⏱ 00:30              │
│ Score: 87/100        │
│ [Take] [Skip] [Snooze]
└──────────────────────┘
```

#### **Tier 3: Mandatory (Full-Screen Overlay)**
- **Trigger**: After 5 minutes if Mandatory break ignored
- **Display**: Full-screen overlay, darkened background
- **Buttons**: "Complete Break" (required to dismiss)
- **Content**: Large eye health message, exercise suggestion, score
- **Duration**: Forces attention
- **Implementation**: `FullScreenOverlayView` with keyboard/mouse event capture

```
╔════════════════════════════════════════╗
║      Your eyes need a break! 👁️        ║
║   Mandatory 15-minute break due       ║
║   You've been working for 2+ hours    ║
║       Current Score: 72/100           ║
║                                        ║
║    [Complete Break] [Eye Exercise]    ║
╚════════════════════════════════════════╝
```

### Escalation Flow

```
Break Due
   ↓
Tier 1: System Notification + Play break start sound
   ↓
User ignores for 2 minutes
   ↓
Tier 2: Floating overlay appears + countdown starts
   ↓
User ignores for 5 more minutes (Mandatory break only)
   ↓
Tier 3: Full-screen overlay blocks all interaction
   ↓
Timeout after 5 more minutes → auto-skip recorded
```

### Callback System (H4)
- Stores `onTakenCallback` and `onSkippedCallback` during notification lifecycle
- Invoked when user acknowledges or timeout occurs
- Prevents callback loss if user ignores multiple tiers
- Cleared after invocation to prevent memory leaks

### Snooze Feature (BUG-006)
- Snoozes notification for configurable duration (default 5 min)
- Creates Task to reschedule break notification after snooze
- Dismisses all visible overlays during snooze
- Calls `onDue` callback when snooze expires

### Sound Integration (v1.6)
- Plays `onBreakStart()` when Tier 1 sent (uses SoundManager)
- Plays `onBreakComplete()` when user takes break
- Respects mute and volume settings

---

## 4. MASCOT SYSTEM (护眼精灵 - Eye Guard Spirit)

### Overview
**Source Files**: All files in `Mascot/` directory (8 files)

A floating, draggable SwiftUI character that serves as the app's personality and provides contextual feedback.

### Visual Design

#### **Body & Anatomy**
- **Base**: Round eyeball (64×64 pt body, ~80×90 pt with limbs)
- **Components**:
  - Eyeball body (white with subtle blue radial gradient)
  - Iris (colored, state-dependent)
  - Pupil (black with highlights)
  - Eyelids (skin-toned, for blink/sleep)
  - Blush cheeks (pink, opacity varies by emotion)
  - Eyebrows (6 distinct shapes)
  - Mouth (7 variations)
  - Arms (two thin rectangles with hands)
  - Legs (two vertical lines)
  - Expression extras (exclamation marks, etc.)

#### **Iris Colors by State**
| State | Color | Hex RGB |
|-------|-------|---------|
| Idle | Blue | (0.3, 0.55, 0.9) |
| Happy | Green | (0.3, 0.8, 0.4) |
| Concerned | Yellow | (0.9, 0.75, 0.2) |
| Alerting | Red | (0.9, 0.3, 0.25) |
| Sleeping | Purple | (0.5, 0.5, 0.75) |
| Exercising | Teal | (0.2, 0.7, 0.7) |
| Celebrating | Purple | (0.7, 0.4, 0.85) |

#### **Eyebrow Shapes**
1. **HappyBrow**: Gentle upward curve (happy, celebrating)
2. **ConcernedBrow**: Angled downward toward center (worried)
3. **RaisedBrow**: High arch (surprised/alert)
4. **FocusedBrow**: Slightly angled (exercising)
5. **Default**: EmptyView for other states

#### **Mouth Variations**
1. **HappyMouth**: Wide arc smile
2. **SleepMouth**: Gentle horizontal curve
3. **Determined Line**: Straight line (exercising)
4. **Worry "O"**: Small circle (concerned)
5. **Surprise "O"**: Larger ellipse (alerting)

#### **Special Effects**
- **Sleeping "zzz"**: Three "z" characters in descending size
- **Celebration Sparkles**: ✨⭐ emoji scattered around
- **Sparkle Highlight**: White circle that follows pupil subtly

### Seven Emotional States (MascotState enum)

| State | Trigger | Expression | Animation |
|-------|---------|-----------|-----------|
| **Idle** | Resting state | Neutral gaze, gentle blinking | Slow breathing effect |
| **Happy** | Good break compliance | Smiling, rosy cheeks | Soft bounce, wave arms |
| **Concerned** | Long usage without breaks | Worried frown, less blush | Slow sway side-to-side |
| **Alerting** | Break time notification | Surprised eyes, exclamation marks | Fast bounce, attention-grabbing |
| **Sleeping** | Night mode (after 10 PM) | Closed eyes with "zzz" | Gentle floating motion |
| **Exercising** | During active break | Focused expression | Eyes follow exercise pattern |
| **Celebrating** | Break completed | Huge smile, sparkles | Bounce with sparkle effects |

### Animations & Interactions

#### **Pupil Tracking** (Mouse Following)
- Pupils track cursor position within a bounded offset
- Offset: ±20-30 pt from center
- Updates on mouse move events
- Smooth interpolation for natural motion

#### **Exercise Patterns** (EyeExercise Integration)
Each exercise provides a pupil movement pattern:
- **lookAround**: Sequential movement (up→down→left→right→diagonals)
- **nearFar**: Simulated via pupil scaling (near = large, far = small)
- **circularMotion**: Smooth circular path (clockwise then counter-clockwise)
- **palmWarming**: Minimal movement (eyes closed)
- **rapidBlink**: Centered, blinking animation only

#### **Bounce Animation** (bounceOffset)
- Applied to entire character via `.offset(y: bounceOffset)`
- Used for alerting and celebrating states
- Smooth sine-wave motion

#### **Wave Animation** (waveAngle in radians)
- Arms rotate based on waveAngle
- Left arm: `-20 + waveAngle * 0.5` degrees
- Right arm: `20 - waveAngle * 0.5` degrees
- Creates friendly greeting effect

### Integration with Speech Bubbles
- **SpeechBubbleView**: Displays tips, insights, reminders
- **Triangle pointer**: Points to mascot mouth
- **Content**: Bilingual (English + Chinese)
- **Auto-rotate**: New tip every 30 minutes
- **Context**: Changes based on time, score, break events

### Window Management (MascotWindowController)
- **Always-on-top**: NSWindow level = .floating
- **Draggable**: Click and drag to reposition
- **Resizable**: Maintains aspect ratio
- **Right-click menu**: Quick access to breaks, exercises, tips, dashboard
- **Close button**: Hides but doesn't quit app

### State Synchronization (MascotStateSync)
- Subscribes to BreakScheduler state changes
- Automatically updates mascot state based on:
  - Health score (happy if > 80, concerned if < 50)
  - Break-in-progress (transitions to exercising)
  - Time of day (transitions to sleeping after 10 PM)
  - Active break type (drives exercise animation)
  - Idle detection (affects message rotation)

---

## 5. EYE EXERCISES (眼保健操)

### Overview
**Source Files**: `EyeExercise.swift`, `ExerciseView.swift`, `ExerciseSessionView.swift`

Five guided routines combining medical guidelines with visual animations.

### Exercise Types

#### **1. Look Around (上下左右看)**
- **Duration**: 40 seconds
- **Steps**: 9 directions (up, down, left, right, 4 diagonals, center)
- **Hold time**: 3 seconds per direction
- **Purpose**: Reduce accommodation strain, exercise ciliary muscles
- **Mascot animation**: Pupil moves to each direction

#### **2. Near-Far Focus (远近调焦)**
- **Duration**: 30 seconds
- **Cycles**: 5 repetitions of near→far→near
- **Instructions**: Thumb 6 inches away, focus near for 3 sec, then focus on distant object (20+ feet)
- **Purpose**: Ciliary muscle relaxation, accommodation training
- **Mascot animation**: Pupil scaling (small for far, large for near)

#### **3. Circular Motion (转圈)**
- **Duration**: 30 seconds
- **Steps**: 5 clockwise circles + pause + 5 counter-clockwise circles
- **Purpose**: Extraocular muscle exercise, stress relief
- **Mascot animation**: Continuous circular pupil path, 12 steps per circle

#### **4. Palm Warming (掌心热敷)**
- **Duration**: 30 seconds
- **Instructions**: Rub palms, cup over closed eyes, deep breathing
- **Purpose**: Warm compress relaxation, ciliary muscle tension relief
- **Mascot animation**: Eyes closed (blinking state), minimal movement

#### **5. Rapid Blink (快速眨眼)**
- **Duration**: 20 seconds
- **Steps**: 20 quick blinks, pause after 10
- **Purpose**: Tear film refresh, reduce dry eye
- **Mascot animation**: Rapid blink effect centered, no pupil movement

### UI Components
- **ExerciseView**: Shows single exercise with animated instructions
- **ExerciseSessionView**: Multi-exercise session controller
- **Progress tracking**: Step counter and timer
- **Celebration**: Mascot celebrates when exercise completes

---

## 6. MEDICAL TIPS DATABASE (25 Evidence-Based Tips)

### Overview
**Source Files**: `TipDatabase.swift`, `EyeHealthTip.swift`, `TipBubbleView.swift`

Static database of 25 bilingual eye health tips from medical organizations.

### Tip Distribution by Category

| Category | Tips | Example |
|----------|------|---------|
| **Tear Film & Blinking** | 2 | Blink 20x to refresh, use artificial tears |
| **Screen Distance & Ergonomics** | 5 | Keep screen 20-26", position below eye level, sit upright |
| **Lighting & Environment** | 6 | Adjust glare, maintain 30-65% humidity, avoid dark rooms |
| **Blue Light & Night** | 2 | Use Night Shift after sunset, reduce brightness |
| **Outdoor Time** | 2 | 20+ min daily for adults, 2+ hours for children |
| **Nutrition** | 3 | Omega-3, leafy greens (lutein/zeaxanthin), hydration |
| **Breaks & Movement** | 2 | 5-min break hourly, stretch neck/shoulders |
| **Prevention** | 2 | Annual eye exams, UV protection |
| **General Health** | 1 | Avoid eye rubbing |

### Tip Data Structure
```swift
struct EyeHealthTip {
    let id: Int (1-25)
    let title: String
    let titleChinese: String
    let description: String
    let descriptionChinese: String
    let source: String (AAO, WHO, OSHA, etc.)
    let icon: String (SF Symbol)
}
```

### Tip Retrieval Methods
1. **Random Tip**: `TipDatabase.randomTip()`
2. **Tip of the Day**: `tipOfTheDay(for:)` — deterministic based on calendar day
3. **Next Tip**: `nextTip(after:)` — sequential navigation

### Tip Rotation in App
- **Mascot speech bubble**: Changes tip every 30 minutes
- **Daily reports**: Featured as "Tip of the Day" section
- **Preferences**: User can browse all tips
- **UI**: Both English and Chinese displayed

---

## 7. HEALTH SCORE ENGINE (0-100 Composite Score)

### Overview
**Source Files**: `HealthScoreCalculator.swift`, `Models.swift`

Calculates daily eye health on a 0-100 scale based on four weighted components.

### Score Components

| Component | Max Points | Weight | What It Measures |
|-----------|-----------|--------|------------------|
| **Break Compliance** | 40 | 40% | % of scheduled breaks taken |
| **Continuous Use Discipline** | 30 | 30% | Avoidance of long unbroken sessions |
| **Total Screen Time** | 20 | 20% | Daily hours vs 8-hour recommendation |
| **Break Quality** | 10 | 10% | Actual duration vs recommended duration |
| **TOTAL** | **100** | — | Composite health score |

### Calculation Details

#### **1. Break Compliance (40 pts)**
```
Score = (breaks_taken / total_breaks_scheduled) × 40
100% compliance = 40 pts
50% compliance = 20 pts
0% compliance = 0 pts
```

#### **2. Continuous Use Discipline (30 pts)**
```
Scenario 1: Longest session ≤ 20 min (micro interval)
→ 30 pts (perfect)

Scenario 2: 20 min < Longest session ≤ 120 min
→ Linear interpolation from 30 to 0
→ Formula: (1 - (session - 20min) / (120min - 20min)) × 30

Scenario 3: Longest session > 120 min
→ 0 pts (exceeded mandatory break threshold)
```

#### **3. Screen Time Score (20 pts)** [BUG-004 Fixed]
```
Recommended max: 8 hours/day

Screen Time < 4 hours:
→ 20 pts (full score)

4 hours < Screen Time < 8 hours:
→ Linear: 20 × (1 - (time - 4h) / 4h × 0.5)
→ At 8h: 10 pts (half score)

Screen Time ≥ 8 hours:
→ 20 × 0.5 × (1 - min((time - 8h) / 8h, 1))
→ At 16h: 0 pts (no score)
```

#### **4. Break Quality (10 pts)**
```
For each taken break:
quality = min(actual_duration / recommended_duration, 1.0)

Average quality = sum(qualities) / num_taken_breaks

Score = average_quality × 10
100% quality = 10 pts
50% quality = 5 pts
0% quality = 0 pts
```

### Trend Calculation (ScoreTrend enum)
```
Compare current score vs average of last 5 scores:

difference = current_score - average_previous_scores

if difference > 3.0 → .improving (↑)
if difference < -3.0 → .declining (↓)
else → .stable (→)
```

### Extended Breakdown (HealthScoreBreakdown)
Includes:
- Per-component scores with explanations
- Trend direction and symbol
- Human-readable summary text (e.g., "Your eye health is excellent and improving!")
- Component-specific guidance

---

## 8. NIGHT MODE / LATE NIGHT GUARDIAN (深夜提醒)

### Overview
**Source Files**: `NightModeManager.swift`

Special mode activating after 10 PM with warmer messaging and more aggressive break reminders.

### Configuration
```swift
var nightStartHour: Int       // Default: 22 (10 PM)
var nightEndHour: Int         // Default: 6 (6 AM)
let nightBreakMultiplier: 0.5 // Breaks occur 2x more often
```

### Night Mode Features

#### **Activation**
- Time-based check: `isNightHour(hour)` every 5 seconds
- Handles midnight crossover (22:00 → 06:00 spans midnight)
- Tracks `nightActivationCount` per day

#### **Mascot Styling**
- Transitions to `.sleeping` state (eyes closed, "zzz" floating)
- Speech bubbles use warmer, amber-tinted colors
- Messages shift from functional to encouraging rest

#### **Night-Themed Messages** (8 variants + 3 break-specific)
Night Messages examples:
- 🌙 "已经很晚了，该休息了" (It's late, time to rest)
- ⭐ "眼睛需要好好睡一觉" (Your eyes need good sleep)
- 🌜 "屏幕时间太长了，早点休息吧" (Too much screen time, rest early)

Break Messages examples:
- 🌙 "深夜了还在用眼，赶紧休息20秒" (Late night — rest 20 seconds now)
- ⭐ "夜里眼睛更容易疲劳，快休息" (Eyes tire faster at night — take a break)

#### **Tracking**
- `nightScreenTime`: Total screen time during night hours
- `nightActivationCount`: How many times night mode activated
- `currentNightSessionStart`: Timestamp of current night session

#### **Daily Reset**
- Resets all night stats at midnight

---

## 9. COLOR BALANCE / SCREEN COLOR ANALYSIS (v1.5)

### Overview
**Source Files**: `ColorAnalyzer.swift`, `ColorSuggestionView.swift`

Periodically analyzes dominant screen colors and suggests complementary colors to reduce strain.

### Color Families (7 types)
```
enum ColorFamily: String {
    case blue, red, green, yellow, purple, orange, neutral
}
```

### Analysis Method
- **Capture**: `CGWindowListCreateImage` (lightweight, no ML)
- **Sampling**: Every 50th pixel in grid pattern (efficient)
- **Frequency**: Every 5 minutes
- **Processing**: RGB → HSL → Hue classification (0-360°)

#### **Hue Range Classification**
| Range | Color |
|-------|-------|
| 0-15° | Red |
| 15-45° | Orange |
| 45-75° | Yellow |
| 75-165° | Green |
| 165-260° | Blue |
| 260-330° | Purple |
| 330-360° | Red |
| Saturation < 0.15 | Neutral (gray/black/white) |

### Complementary Color Mapping
| Detected | Suggested |
|----------|-----------|
| Blue | Green |
| Red | Green |
| Green | Blue |
| Yellow | Purple |
| Purple | Yellow |
| Orange | Blue |
| Neutral | Green (default) |

### Suggestion Messages (Chinese + emoji)
Each color family has 3 curated suggestions:
- Blue → "看了很多蓝色屏幕，试试看看绿色植物吧" 🌿
- Red → "屏幕偏红色调，看看绿色植物平衡一下" 🌿
- Warm tones → "暖色看久了，望望远处的冷色调景物" 🏔️

### State Tracking
- `colorHistory`: Last 12 analyses (1 hour @ 5-min intervals)
- `mostFrequentRecentColor()`: Dominant color from history
- `analysisCount`: Total analyses performed today

---

## 10. SOUND EFFECTS & AMBIENT AUDIO (v1.6)

### Overview
**Source Files**: `SoundManager.swift`

Manages break notifications, celebration sounds, and procedurally-generated ambient audio during breaks.

### Sound Types

#### **System Sounds (via NSSound)**
| Type | Sound Name | When |
|------|-----------|------|
| Break Start | "Tink" | When break notification sent |
| Break Complete | "Hero" | When user completes break |
| Tip Rotation | "Pop" | When new tip displayed |
| Alert | "Sosumi" | For escalated notifications |

#### **Ambient Presets** (Generated via AVAudioEngine)
Each with unique procedural generation:

1. **Rain 🌧️**
   - Low-pass filtered white noise
   - Simulates gentle rainfall pattern
   - Relaxing, subtle

2. **Ocean Waves 🌊**
   - Slowly modulated noise (0.08 Hz)
   - Sine wave envelope
   - Peaceful oceanic feel

3. **Forest Birds 🌲**
   - Base frequency 1200 Hz with modulation ±400 Hz
   - Sparse chirp envelope (thresholded > 0.95)
   - Natural forest atmosphere

4. **Gentle Wind 🍃**
   - Band-pass filtered noise with slow modulation
   - Breeze-like volume envelope
   - Subtle and calming

5. **Silence 🔇**
   - No audio output

### Sound Manager State
```swift
var volume: Float              // 0.0 – 1.0 (persisted in UserDefaults)
var isMuted: Bool             // Persisted in UserDefaults
var selectedAmbientPreset     // Currently selected ambient sound
var isAmbientPlaying: Bool    // Whether ambient sound is active
```

### Audio Engine (AVAudioEngine)
- Creates source nodes with custom rendering callback
- Generates samples in real-time (no audio files needed)
- Attaches to main mixer for playback
- Cleanup on stop (detach nodes, stop engine)

### Integration with Breaks
```
Break starts:
→ play(.breakStart)
→ wait 1 second
→ startAmbient()

Break ends:
→ stopAmbient()
→ play(.breakComplete)
```

---

## 11. DASHBOARD & CHARTS (Analytics)

### Overview
**Source Files**: `DashboardView.swift`, `DashboardWindowController.swift`, `HistoryManager.swift`

Interactive analytics dashboard with SwiftUI Charts integration (macOS 14+).

### Dashboard Tabs

#### **Tab 1: Today**
- **Health Score Gauge**: Circular progress ring (0-100), color-coded
  - Green: 80-100
  - Yellow: 50-79
  - Orange: 30-49
  - Red: 0-29
- **Summary Text**: "Your eye health is excellent and improving!"
- **Stats Grid** (3 columns):
  - Breaks Taken (checkmark icon, green)
  - Breaks Skipped (X icon, red)
  - Screen Time (clock icon, blue)
  - Longest Session (timer, orange)
  - Current Health Score (gauge)
  - Sessions Count (folder)
- **Component Breakdown**: Per-component scores with small bar charts

#### **Tab 2: History**
- **Time Range Selector**: 7 Days or 30 Days
- **Dual-Axis Chart**:
  - **BarMark**: Daily total screen time (blue bars)
  - **LineMark**: Daily health score trend (red line)
- **Data Source**: Historical JSON files from `~/EyeGuard/data/`
- **Loaded Asynchronously**: Via HistoryManager

#### **Tab 3: Breakdown**
- **Pie-Style Chart**: Component score proportions
  - Break Compliance (40 pts) — largest
  - Continuous Use (30 pts)
  - Screen Time (20 pts)
  - Break Quality (10 pts)
- **Donut style**: Inner label shows total score
- **Legend**: Component names and current values

### Data Model (HistoryManager)
```swift
struct DailySummary {
    let date: Date
    let screenTime: TimeInterval
    let healthScore: Int
    let breaksTaken: Int
    let breaksScheduled: Int
}
```

### History Loading
- Scans `~/EyeGuard/data/` for JSON files
- Parses and aggregates daily data
- Sorts chronologically
- Loaded on dashboard open (async via Task)

---

## 12. DAILY REPORTS (Markdown Generation)

### Overview
**Source Files**: `DailyReportGenerator.swift`, `ReportDataProvider.swift`

Generates comprehensive daily Markdown reports auto-saved to `~/EyeGuard/reports/YYYY-MM-DD.md`.

### Report Sections

#### **1. Header & Summary**
```markdown
# 🟢 EyeGuard Daily Report
> Monday, April 15, 2026

| Metric | Value |
|--------|-------|
| Total Screen Time | 7h 32m |
| Health Score | 87/100 🟢 |
| Breaks Taken | 24 / 26 |
| Sessions | 3 |
| Longest Session | 1h 15m |
```

#### **2. Score Breakdown** (Visual bars)
```markdown
| Component | Score | Max | Bar |
|-----------|-------|-----|-----|
| Break Compliance | 38 | 40 | ████████░░ |
| Continuous Use Discipline | 25 | 30 | ████████░░░ |
| Screen Time | 18 | 20 | █████████░ |
| Break Quality | 9 | 10 | █████████░ |
| **Total** | **87** | **100** | ██████████ |
```

#### **3. Hourly Breakdown Table**
```markdown
| Hour | Breaks Taken | Breaks Skipped | Activity |
|------|-------------|----------------|----------|
| 09:00 | 3 | 0 | ✅✅✅ |
| 10:00 | 2 | 1 | ✅✅❌ |
| 14:00 | 4 | 0 | ✅✅✅✅ |
```

#### **4. Break Compliance**
```markdown
| Metric | Value |
|--------|-------|
| Breaks Suggested | 26 |
| Breaks Taken | 24 |
| Breaks Skipped | 2 |
| Compliance Rate | 92% |

### By Type
| Type | Taken | Skipped | Rate |
|------|-------|---------|------|
| Micro Break | 16 | 0 | 100% |
| Macro Break | 7 | 1 | 87% |
| Mandatory Break | 1 | 1 | 50% |
```

#### **5. Longest Continuous Session**
```markdown
**Duration**: 1 hour 15 minutes

⚠️ Your longest session was 75 minutes. 
Consider taking more frequent breaks. 
Try to stay under 20 minutes for optimal eye health.
```

#### **6. Personalized Recommendations**
Generated based on score components:
- ✅ Excellent (complements)
- 🟡 Suggestions (improvement areas)
- 🔴 Critical alerts (major issues)

#### **7. Detailed Break Log**
```markdown
| # | Time | Type | Status | Duration |
|---|------|------|--------|----------|
| 1 | 09:15 | Micro Break | ✅ Taken | 22 sec |
| 2 | 09:35 | Micro Break | ✅ Taken | 20 sec |
| 3 | 09:55 | Micro Break | ❌ Skipped | — |
```

#### **8. AI Insights** (v1.8)
- LLM-generated analysis or rule-based fallback
- Pattern insights about best/worst hours
- Actionable recommendations

#### **9. Tip of the Day**
Featured tip with source attribution (AAO, WHO, OSHA, etc.)

#### **10. Footer**
- Generation timestamp
- File path reference

### File I/O
- **Path**: `~/EyeGuard/reports/YYYY-MM-DD.md`
- **Encoding**: UTF-8
- **Atomic write**: Prevents corruption on crash
- **Async**: All I/O runs on background thread

### Auto-Generation
- Option to auto-generate on quit (UserDefaults: `autoGenerateDailyReport`)
- Manual generation via menu bar "Generate Report" button
- Opens reports folder in Finder after generation

---

## 13. LLM INTEGRATION & AI INSIGHTS (v1.8)

### Overview
**Source Files**: `InsightGenerator.swift`, `LLMService.swift`

Protocol-based architecture enabling rule-based insights with LLM-ready fallback.

### Architecture

#### **Protocols**
```swift
protocol LLMAnalyzing {
    func analyzeUsagePattern(data: DailyReport) async throws -> String
}
```

#### **Service Factory Pattern**
```swift
enum LLMServiceFactory {
    static func createService() -> any LLMAnalyzing {
        // Returns LocalLLMService (rule-based) by default
        // Can be swapped to ClaudeLLMService when API key configured
    }
}
```

### Insight Types

#### **1. Daily Report Insights**
- **Source**: DailyReport structure (scores, screen time, breaks)
- **Output**: Markdown-formatted insight section
- **Method**: `generateReportInsights(report:)`
- **Example**:
  ```
  Screen time: 7.5 hours. Within healthy range.
  Health score: 87/100. Break compliance: 92%.
  Great performance today!
  ```

#### **2. Mascot Speech Bubble Insights**
- **Frequency**: Every 2 hours
- **Character limit**: <50 chars for UI fit
- **Context**: Current screen time, breaks taken, health score, hour of day
- **Time-based logic**:
  - 14:00-16:00 (afternoon): Suggest afternoon slump avoidance
  - 17:00+ (evening): Suggest wind-down/Night Shift
- **Score-based logic**:
  - Score < 50: Low score warning
  - Compliance < 50%: Break compliance reminder
  - Compliance ≥ 90%: Praise
- **Screen time milestones**: "6h so far. Consider a longer break."

#### **3. Menu Bar Popover Insight**
- **Single line**: "🤖 Score 87 · 7.5h screen · Great job!"
- **Format**: Score · Screen Time · Status
- **Method**: `generateMenuBarInsight(healthScore:screenTime:breakCompliance:)`

#### **4. Comparison Insights** (Day-over-day)
- **Compares**: Today vs Yesterday
- **Metrics**:
  - Screen time delta
  - Score delta
  - Compliance delta
- **Example**: "Screen time is down 0.5h from yesterday — nice!"

#### **5. Hourly Pattern Analysis**
- **Best hour**: Hour with highest break compliance
- **Worst hour**: Hour with lowest break compliance
- **Format**: "10:00 (4/4 breaks taken)" vs "14:00 (1/3 breaks taken)"

### Rule-Based Fallback (LocalLLMService)
When LLM service unavailable or fails:
```
Screen time: <hours>h. 
  ✓ Within healthy range (< 8h)
  ⚠ Approaching limit (6-8h)
  ✗ Over limit (> 8h)

Health score: <score>/100. 
Break compliance: <%>%.

<Score-based recommendation>
```

### LLM-Ready Placeholders
- **ClaudeLLMService**: Placeholder for Anthropic Claude API integration
- **Configuration**: Via environment variable or `.env` file
- **Benefits**: Enhanced personalization, deeper pattern analysis

---

## 14. ACTIVITY MONITORING (Screen Time & Idle Detection)

### Overview
**Source Files**: `ActivityMonitor.swift` (Actor-based), `ActivityMonitoring.swift` (Protocol)

Tracks user input and screen lock state to detect idle periods and pause break timers.

### Activity Monitoring (Actor)

#### **State Tracking**
```swift
actor ActivityMonitor {
    var lastActivityTimestamp: Date      // Last recorded input
    var isIdle: Bool                     // Current idle state
    var isMonitoring: Bool               // Monitoring active
    var isScreenLocked: Bool             // Screen locked state
    var timeSinceLastActivity: TimeInterval
}
```

#### **Idle Detection**
- **Threshold**: 30 seconds of no input activity
- **Check frequency**: Every 5 seconds (polling loop)
- **Transition**: Marks `isIdle = true` when threshold exceeded
- **Reset**: Clears idle state when activity detected

#### **Screen Lock Detection** (BUG-005 Related)
- **Method**: DistributedNotificationCenter observers
- **Notifications monitored**:
  - `com.apple.screenIsLocked`
  - `com.apple.screenIsUnlocked`
- **Behavior**:
  - Screen locked → `isIdle = true`, break timers pause
  - Screen unlocked → `isIdle = false`, timers resume
- **Implementation**: `ScreenLockObserver` NSObject wrapper

#### **Activity Recording**
- **Method**: Called explicitly when activity detected
- **Updates**: `lastActivityTimestamp = .now`
- **Triggers idle state reset**: `isIdle = false`

#### **Daily Rollover** (BUG-005)
- **Check**: Every 5 seconds during idle loop
- **Action**: At midnight, resets all state
- **Purpose**: Prevents idle state carryover to new day

#### **CGEventTap Placeholder**
- **Current**: Idle detection via polling only
- **Future**: CGEventTap for real-time keyboard/mouse events
- **Requirements**:
  - Accessibility permissions
  - Main thread event loop integration
  - Event mask: mouseMoved, keyDown, scrollWheel, mouseDown

### Idle Behavior in BreakScheduler
When idle detected:
```
handleIdleDetected():
  → resetTimersAfterBreak(.micro)  // Micro timer only
  → Log: "Idle detected, micro timer reset."
```

When activity resumes:
```
handleActivityResumed():
  → sessionStartTime = .now        // Restart session timer
  → currentSessionDuration = 0
  → Log: "Activity resumed, session restarted."
```

---

## 15. PREFERENCES & SETTINGS

### Overview
**Source Files**: `UserPreferencesManager.swift`, `PreferencesView.swift`, `PreferencesWindowController.swift`

Customizable settings persisted to UserDefaults.

### User Preferences Structure

```swift
struct UserPreferences: Codable, Sendable {
    // Intervals (seconds)
    var microBreakInterval: TimeInterval
    var macroBreakInterval: TimeInterval
    var mandatoryBreakInterval: TimeInterval
    
    // Durations (seconds)
    var microBreakDuration: TimeInterval
    var macroBreakDuration: TimeInterval
    var mandatoryBreakDuration: TimeInterval
    
    // Feature toggles
    var isMicroBreakEnabled: Bool
    var isMacroBreakEnabled: Bool
    var isMandatoryBreakEnabled: Bool
    var isSoundEnabled: Bool
    var isEscalationEnabled: Bool
}
```

### UserDefaults Keys

| Key | Type | Default |
|-----|------|---------|
| `microBreakIntervalMinutes` | Double | 20 |
| `macroBreakIntervalMinutes` | Double | 60 |
| `mandatoryBreakIntervalMinutes` | Double | 120 |
| `microBreakDurationSeconds` | Double | 20 |
| `macroBreakDurationMinutes` | Double | 5 |
| `mandatoryBreakDurationMinutes` | Double | 15 |
| `isNotificationSoundEnabled` | Bool | true |
| `autoGenerateDailyReport` | Bool | true |
| `launchAtLogin` | Bool | false |
| `soundVolume` | Float | 0.5 |
| `soundMuted` | Bool | false |
| `ambientPreset` | String | "Rain 🌧️" |
| `nightModeStartHour` | Int | 22 |
| `nightModeEndHour` | Int | 6 |

### Preferences UI (SwiftUI)
- **Window Controller**: Manages floating preferences window
- **Tab-based layout**: General, Breaks, Notifications, Sound, Advanced
- **Controls**:
  - Interval/duration sliders with minute/second conversions
  - Toggle switches for break types
  - Dropdown for ambient presets
  - Time picker for night mode hours

### Loading Preferences
```swift
static func load() -> UserPreferences {
    // Reads from UserDefaults
    // Falls back to defaults if not set
    // Converts minutes to seconds for internal use
}
```

---

## 16. MENU BAR & STATUS BAR INTEGRATION

### Overview
**Source Files**: `MenuBarView.swift`, `EyeGuardApp.swift`, `MenuBarLabel.swift`

macOS menu bar presence with live status and quick controls.

### Menu Bar Appearance
- **Title Format**: `👁️ MM:SS` (countdown to next break)
- **When Paused**: `⏸ Paused`
- **Night Mode Indicator**: `🌙` prefix when night mode active
- **Update Frequency**: Every second (reactive to scheduler state)

### Menu Bar Popover Contents

#### **Header Section**
- App name with icon
- Status badge (Active/Paused)

#### **Health Score Section**
- Circular gauge (0-100) with color-coded ring
- Component breakdown (Breaks/Discipline/Time/Quality) with small bars
- Summary text (e.g., "Your eye health is excellent and improving!")

#### **Timer Section**
- Current session duration (MM:SS or HH:MM:SS)
- Next break type icon + name
- Time until next break (MM:SS)

#### **Controls Section** (4 buttons)
- **Pause/Resume**: Toggle button
- **Reset**: Clears current session timer
- **Break Now**: Starts immediate micro-break
- Status-responsive button enabling/disabling

#### **Stats Section**
- Breaks Taken (count)
- Breaks Skipped (count)
- Total Screen Time (formatted: "7h 32m")

#### **AI Insight Section** (v1.8)
- Brain icon + "AI Insight" label
- Contextual insight string (1-2 lines)

#### **Generate Report Button**
- Opens report generation + opens reports folder in Finder

#### **Footer Section** (3 buttons)
- **Dashboard**: Opens analytics window
- **Preferences**: Opens preferences window
- **Quit**: Terminates application

### MenuBarExtra Style
- **Style**: `.window` (floating popover, not menu dropdown)
- **Dismissal**: Clicking outside or clicking menu bar icon again
- **Persistence**: Stays open while interacting

---

## 17. APP LIFECYCLE & BUNDLE CONFIGURATION

### Overview
**Source Files**: `EyeGuardApp.swift`, `AppDelegate.swift`

Application initialization and lifecycle management.

### App Entry Point
```swift
@main
struct EyeGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var scheduler = BreakScheduler()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(scheduler: scheduler)
                .onAppear {
                    // Register scheduler
                    ReportDataProvider.shared.register(scheduler: scheduler)
                    // Launch mascot
                    launchMascot()
                }
        } label: {
            MenuBarLabel(scheduler: scheduler)
        }
    }
}
```

### AppDelegate Responsibilities
```swift
@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var mascotController: MascotWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up app icon/bundle preferences
        // Initialize notification permissions
        // Start monitoring
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // App lives in menu bar, doesn't close
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Generate final report
        // Clean up resources
    }
}
```

### App Bundle Configuration

#### **Info.plist Keys**
```xml
<key>CFBundleIdentifier</key>
<string>com.mengxiong.eyeguard</string>

<key>CFBundleVersion</key>
<string>1.0</string>

<key>CFBundleShortVersionString</key>
<string>1.0</string>

<key>NSMainStoryboardFile</key>
<string></string>

<key>NSRequiresIPhoneOS</key>
<false/>

<key>LSUIElement</key>
<integer>1</integer>  <!-- No dock icon -->

<key>NSLocalizedDescription</key>
<string>Medical-grade eye health guardian for macOS</string>

<key>NSHumanReadableCopyright</key>
<string>© 2026 EyeGuard. MIT License</string>
```

#### **Capabilities**
- ✅ Notification permissions (UserNotifications)
- ✅ Accessibility permissions (CGEventTap)
- ✅ Screen recording (ColorAnalyzer)

#### **Dock Behavior**
- **LSUIElement = 1**: No dock icon, menu bar only
- **No main window**: Can't be activated via Cmd+Tab
- **Access via**: Click menu bar icon

### Launch at Login (v0.8)
- **Configuration**: Stored in UserDefaults (`launchAtLogin`)
- **Method**: SMAppService (ServiceManagement framework)
- **UI**: Toggle in Preferences → General tab
- **Behavior**: Auto-launches on system startup

### Quit-Time Report Generation
- **Trigger**: User quits app (NSApplication.terminate)
- **Report**: Final daily report generated asynchronously
- **Persistence**: Stored to `~/EyeGuard/reports/YYYY-MM-DD.md`
- **Purpose**: Captures final day snapshot even if app closed early

### Performance (v1.9)
- **Launch Time Target**: <1s to menu bar presence
- **Optimizations**:
  - Lazy initialization of heavy services (ColorAnalyzer deferred)
  - Static DateFormatters (no repeated allocations)
  - Reusable HealthScoreCalculator instance
  - Break scheduler starts timer loop on initialization

---

## SUMMARY STATISTICS

### Feature Count
- **Total Swift Files**: 49 (Sources + Tests)
- **Core Features**: 17 major systems
- **Break Types**: 3 (Micro, Macro, Mandatory)
- **Mascot States**: 7 emotional states
- **Eye Exercises**: 5 guided routines
- **Medical Tips**: 25 evidence-based tips
- **Notification Tiers**: 3 escalation levels
- **Sound Presets**: 5 ambient options
- **Color Families**: 7 categories
- **Dashboard Tabs**: 3 (Today, History, Breakdown)
- **Report Sections**: 10+ detailed sections
- **AI Insight Types**: 5 different formats

### Lines of Code (Approximate)
- **Scheduling**: ~533 lines (BreakScheduler.swift)
- **Notifications**: ~310 lines (NotificationManager.swift)
- **Mascot**: ~515 lines (MascotView.swift alone)
- **Color Analysis**: ~341 lines (ColorAnalyzer.swift)
- **Health Scoring**: ~319 lines (HealthScoreCalculator.swift)
- **Daily Reports**: ~483 lines (DailyReportGenerator.swift)
- **Total**: ~5000+ lines of production code

### External Dependencies
- SwiftUI (built-in)
- AppKit (built-in)
- AVFoundation (audio)
- Charts (dashboard visualization, macOS 14+)
- UserNotifications (native notifications)
- os.Logger (structured logging)

### Medical Guidelines Referenced
- AAO (American Academy of Ophthalmology) — 20-20-20 rule
- OSHA (Occupational Safety and Health) — hourly breaks
- EU Screen Equipment Directive — mandatory 2-hour breaks
- WHO (World Health Organization) — outdoor time
- NIOSH — eye strain prevention
- Peer-reviewed research on Computer Vision Syndrome

---

## ARCHITECTURE PATTERNS

### Design Patterns Used
1. **Protocol-Oriented Design**: All major services use protocols for testability
2. **Dependency Injection**: Services injected into consumers, not singletons
3. **Observable/State Management**: @Observable for reactive UI updates
4. **Actor Pattern**: ActivityMonitor uses actor for thread safety
5. **Singleton Pattern**: Shared instances for services (BreakScheduler, NotificationManager, etc.)
6. **Factory Pattern**: LLMServiceFactory creates appropriate service
7. **Enum-Driven State**: MascotState, BreakType, ScoreTrend as enums
8. **Value Types**: Models as Codable structs (Sendable for concurrency)

### Concurrency Model
- **Swift 6 Strict Concurrency**: Enabled throughout
- **@MainActor**: UI-critical services marked for main thread
- **Actors**: ActivityMonitor for thread safety
- **Sendable**: All data crossing isolation boundaries
- **Structured Concurrency**: Task.sleep, async/await, Task groups
- **No [weak self]**: BreakScheduler @MainActor avoids retain cycles

### Testing Strategy
- **Swift Testing Framework**: All tests use @Test macro
- **13 Test Suites**: Covering major systems
- **Mocking**: Via protocol injection
- **Example Tests**: BreakSchedulerTests, HealthScoreCalculatorTests

---

END OF FEATURE INVENTORY
