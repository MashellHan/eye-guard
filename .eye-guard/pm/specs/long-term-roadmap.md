# EyeGuard Long-Term Feature Roadmap

> Beyond v1.0 - The vision for EyeGuard as a comprehensive eye health platform.

---

## Phase 2: Enhanced Experience (v1.1 - v2.0)

Target: 3-6 months post v1.0 launch

### 2.1 Eye Guard Mascot / Sprite

**Priority**: High | **Effort**: Medium | **Impact**: High (engagement & delight)

A cute animated character that lives on the screen edge and comes alive during break time. The mascot serves as a friendly, non-intrusive companion that makes eye health habits enjoyable.

**Implementation**:
- Built with SpriteKit or SwiftUI animations
- Lives in a small transparent window anchored to screen edge (configurable position)
- Idle state: subtle breathing animation, occasional blink
- Break time: walks across screen edge, does stretches, waves at user
- Post-break: celebrates with confetti/sparkle animation

**Mascot behaviors**:
| Trigger | Animation | Duration |
|---------|-----------|----------|
| App launch | Peek-in from edge, wave | 2s |
| Approaching break time | Yawn, stretch | 1s |
| Break triggered | Walk to center, point at eyes | 3s |
| Break taken | Happy dance, thumbs up | 2s |
| Break skipped | Sad face, droopy eyes | 1s |
| Good daily score (80+) | Party hat, confetti | 3s |
| 120+ min continuous | Alarmed, waving frantically | loop |

**Customization**:
- Multiple mascot characters to choose from (owl, cat, panda, robot)
- Enable/disable mascot independently from break reminders
- Size: small (32px), medium (48px), large (64px)
- Transparency control

### 2.2 Eye Exercise Animations

**Priority**: High | **Effort**: High | **Impact**: High (core health value)

Full animated eye exercise routines (inspired by traditional eye exercises) presented as guided sessions during breaks.

**Exercise Library**:

1. **Directional Gaze (30s)**
   - Animated dot moves: up, hold 3s, down, hold 3s, left, hold 3s, right, hold 3s
   - User follows dot with eyes only (head still)
   - Visual guide with arrow indicators

2. **Focus Near/Far (60s)**
   - Animated object alternates between "near" (large, detailed) and "far" (small, simple)
   - User shifts focus between thumb (near) and distant object (far)
   - Timer for each focal distance: 5s near, 5s far, repeat 6x

3. **Circular Eye Movement (30s)**
   - Dot traces clockwise circle, user follows
   - Then counterclockwise
   - Smooth animation with speed control

4. **Palm Warming Exercise (60s)**
   - Illustrated instructions: rub palms together, cup over closed eyes
   - Countdown timer with soothing background
   - Audio narration option

5. **Guided Full Routine (3-5 min)**
   - Combines all exercises in sequence
   - Background music / ambient sounds
   - Audio coaching with voice narration
   - Progress bar through the routine

**Technical approach**:
- SwiftUI Canvas for smooth 60fps animations
- Lottie integration for complex character animations
- Audio: AVFoundation for narration and ambient sounds
- Exercise data as JSON configs for easy addition of new exercises

### 2.3 Color Balance Suggestions

**Priority**: Medium | **Effort**: Medium | **Impact**: Medium

Analyzes the dominant colors on the user's screen and suggests complementary colors to look at during breaks for visual balance and reduced eye strain.

**How it works**:
1. During active use, periodically capture screen color profile (every 5 min)
   - Uses `CGWindowListCreateImage` with low-res capture
   - Extract dominant color palette (top 3 colors)
   - Track color exposure over the session
2. During breaks, suggest complementary viewing:
   - "You've been looking at predominantly blue content for 2 hours"
   - "Try looking at warm colors (green plants, warm-toned artwork) during your break"
   - Display a soothing complementary color gradient as break background

**Color recommendations**:
| Screen Dominant | Suggestion | Reasoning |
|-----------------|------------|-----------|
| Blue/White (code editors, docs) | Green, warm earth tones | Relaxes ciliary muscle, reduces blue light afterimage |
| Red/Orange (design work) | Cool blues, greens | Balances warm color fatigue |
| High contrast (B&W) | Muted pastels, nature greens | Reduces contrast fatigue |
| Mixed/balanced | Nature scenes, sky colors | General relaxation |

**Privacy**: All color analysis is local. No screenshots stored. Only aggregate color data retained.

### 2.4 Medical Tips Notifications

**Priority**: Medium | **Effort**: Low | **Impact**: Medium

Rotating evidence-based tips from ophthalmological guidelines, delivered as part of break notifications or as standalone educational moments.

**Tip Categories**:

1. **Blink Rate**
   - "Your blink rate drops by 60% when focusing on screens. Practice conscious blinking."
   - "Try the 'blink slowly 10 times' exercise to refresh your tear film."

2. **Monitor Setup**
   - "Your monitor should be 20-26 inches from your eyes (arm's length)."
   - "The top of your screen should be at or slightly below eye level."
   - "Tilt your monitor slightly back (10-20 degrees) to reduce glare."

3. **Lighting**
   - "Ambient light should be about half the brightness of your screen."
   - "Avoid overhead lights that reflect directly on your screen."
   - "Use indirect/diffused lighting to reduce glare and eye strain."

4. **Humidity & Environment**
   - "Dry air worsens eye strain. Consider a humidifier if humidity is below 40%."
   - "Direct air from heating/cooling vents can dry your eyes. Redirect vents away."

5. **Nutrition**
   - "Omega-3 fatty acids (fish, flaxseed) support tear film health."
   - "Vitamin A (carrots, sweet potatoes) is essential for eye health."
   - "Stay hydrated - dehydration directly affects tear production."

6. **General Eye Health**
   - "Annual eye exams can detect issues early, even without symptoms."
   - "Blue light filtering is most important in the 2 hours before sleep."
   - "Outdoor time (2+ hours/day) reduces myopia progression in young people."

**Delivery**:
- One tip per break notification (rotated, no repeats within 7 days)
- Tips shown in Tier 2 overlay and daily report
- Tips sourced from: AAO, WHO, National Eye Institute (NEI)

### 2.5 Late Night Guardian

**Priority**: High | **Effort**: Medium | **Impact**: High

Special enhanced protection mode that activates after 10 PM (configurable) with stronger reminders, warmer tone, and sleep-awareness.

**Activation**: Automatic after configured time (default: 10:00 PM)

**Changes when active**:
| Aspect | Normal Mode | Late Night Mode |
|--------|-------------|-----------------|
| Micro-break interval | 20 min | 15 min |
| Notification tone | Neutral | Warm, concerned |
| Message style | "Time for a break!" | "It's late. Your eyes need extra rest." |
| Tier escalation speed | 2 ignored → Tier 2 | 1 ignored → Tier 2 |
| Mandatory break threshold | 120 min | 90 min |
| Break overlay color | Dark blue | Warm amber |
| Additional prompts | None | "Consider winding down for the night" |

**Late Night specific messages**:
- "It's 11:30 PM. Screen use before bed can disrupt your sleep cycle."
- "Blue light exposure at night suppresses melatonin. Consider stopping soon."
- "Your eyes have been working for 12 hours today. They deserve rest."
- "Tip: If you must work late, maximize Night Shift/True Tone settings."

**Late Night Dashboard**:
- Track late-night usage patterns over time
- Weekly summary: "You used your screen past 10 PM on 4/7 nights this week"
- Trend analysis: "Your late-night usage has increased 20% this month"

**Configurable**:
- Activation time (default: 10 PM)
- Deactivation time (default: 6 AM)
- Intensity level: gentle / moderate / strict
- Enable/disable independently

---

## Phase 3: Intelligence (v2.0 - v3.0)

Target: 6-12 months post v1.0

### 3.1 LLM Integration

**Priority**: High | **Effort**: High | **Impact**: Very High

Connect to Claude API (or local LLM via Ollama/LM Studio) for personalized, context-aware eye health assistance.

**Features**:

1. **Personalized Break Suggestions**
   - LLM analyzes usage patterns and generates contextual break recommendations
   - "You tend to skip breaks between 2-4 PM. Try setting a physical reminder."
   - "Your best eye health days correlate with morning outdoor walks."

2. **Smart Health Analysis**
   - Weekly/monthly health trend analysis with natural language explanation
   - "Your eye health score has improved 12% this month. Key factors: better micro-break compliance and reduced late-night usage."
   - Identify patterns the user might not notice

3. **Natural Language Reports**
   - Transform raw data into readable, personalized daily/weekly summaries
   - Conversational tone with actionable insights
   - Compare to previous periods and highlight trends

4. **"Ask Your Eye Health Assistant" Chat**
   - In-app chat interface to ask questions about eye health
   - Context-aware: has access to user's usage data (local only)
   - "Why do my eyes feel dry in the afternoon?" → personalized answer based on their break patterns and environment tips

**Architecture**:
- Primary: Claude API with structured prompts
- Fallback: Local LLM (Ollama with Llama/Mistral) for offline use
- Privacy: Usage data stays local. Only anonymized patterns sent to API
- Cost: Estimated ~$0.01-0.05/day per user at typical usage

### 3.2 ML-Based Adaptive Timing

**Priority**: Medium | **Effort**: High | **Impact**: High

Machine learning model that learns the user's optimal break intervals based on their behavior, productivity patterns, and compliance history.

**How it works**:
1. Collect data over 2+ weeks:
   - Break compliance by time of day
   - Session lengths before voluntary breaks
   - Notification dismissal patterns
   - Natural break patterns (when user takes breaks unprompted)
2. Train on-device Core ML model to predict:
   - Optimal micro-break interval for each hour of the day
   - Best macro-break timing based on focus patterns
   - Likelihood of compliance for a given notification time
3. Adjust intervals dynamically:
   - If user naturally breaks every 25 min at 10 AM, set micro-break to 25 min
   - If user always ignores 20-min micro-break at 3 PM, try 15-min or different notification style

**Guardrails**:
- Never exceed medically recommended maximums (30 min micro, 90 min macro)
- Never go below medically recommended minimums (15 min micro, 45 min macro)
- User can override and lock intervals manually

### 3.3 Webcam Posture & Distance Detection

**Priority**: Low | **Effort**: Very High | **Impact**: Medium

Use the Mac's built-in camera with Vision framework to detect if the user is sitting too close to the screen or has poor posture.

**Detection capabilities**:
- Face distance from screen (too close = < 20 inches)
- Head tilt angle (neck strain indicator)
- Slouching detection (shoulder position)

**Implementation**:
- Apple Vision framework for face detection and landmark analysis
- On-device processing only (no images stored or transmitted)
- Camera access clearly communicated and optional
- Processing: 1 frame every 30 seconds (minimal resource use)

**Alerts**:
- "You seem to be leaning closer to the screen. Try sitting back."
- "Your head is tilted - this can cause neck strain."

**Privacy**:
- Explicit opt-in required
- Camera indicator light always visible when active
- No images stored - only distance/angle measurements
- Can be disabled anytime

---

## Phase 4: Ecosystem (v3.0+)

Target: 12+ months post v1.0

### 4.1 iOS / watchOS Companion App

**Priority**: High | **Effort**: Very High | **Impact**: Very High

Extend EyeGuard to iPhone and Apple Watch for a complete cross-device eye health ecosystem.

**iOS App**:
- Dashboard showing Mac screen time data synced via iCloud
- Historical charts and trends (weekly, monthly, yearly)
- Configure Mac app settings remotely
- Push notifications when Mac detects extended use (if away from Mac)
- Standalone iPhone screen time monitoring

**watchOS App**:
- Haptic break reminders on wrist (especially useful when AirPods/headphones block notification sounds)
- Complication showing current session time / health score
- "Breathe"-style eye exercise guided sessions
- Quick glance at today's score

**Sync**:
- iCloud CloudKit for data sync
- Shared `EyeGuardHealth` data model
- Real-time sync for active session status

### 4.2 Apple Health Integration

**Priority**: Medium | **Effort**: Medium | **Impact**: Medium

Export eye health data to Apple Health for holistic health tracking.

**Data exported**:
- Daily eye health score (custom HKQuantityType)
- Total screen time (hours)
- Break compliance percentage
- Number of breaks taken
- Continuous use sessions

**Benefits**:
- Correlate eye health with sleep, exercise, and other health metrics
- Third-party health apps can access the data
- Siri Shortcuts integration: "Hey Siri, how are my eyes today?"

### 4.3 Gamification System

**Priority**: Medium | **Effort**: Medium | **Impact**: High (retention)

Streak tracking, achievements, and optional social features to make eye health habits stick.

**Streaks**:
- Daily streak: consecutive days with score 70+
- Perfect break streak: consecutive breaks taken on time
- Early bird streak: no screen time before configured morning routine complete

**Achievements (badges)**:
| Badge | Requirement |
|-------|-------------|
| First Steps | Complete first day with EyeGuard |
| Week Warrior | 7-day streak |
| Month Master | 30-day streak |
| Perfect Day | Score 100/100 |
| Break Champion | 50 consecutive breaks taken |
| Night Owl Reformed | 7 days no screen after 10 PM |
| Eye Exercise Pro | Complete 100 guided exercises |
| Distance Master | 30 days of good posture (Phase 3) |

**Leaderboards (opt-in)**:
- Anonymous weekly leaderboard
- Friends leaderboard (via Game Center or invite links)
- Team leaderboard (for workplaces)

### 4.4 Family Sharing

**Priority**: Low | **Effort**: High | **Impact**: Medium

Monitor and support family members' eye health, especially children.

**Features**:
- Parent dashboard: see all family members' daily scores
- Child mode: stricter defaults, no override option
- Family weekly report
- Shared achievements and encouragement
- Screen time budgets per family member
- Integration with macOS Screen Time parental controls

**Privacy**:
- Explicit consent required from all family members
- Children under 13: parent consent required
- Data stays within iCloud Family Sharing group
- Each member controls their own sharing preferences

---

## Roadmap Timeline Summary

```
2026 Q3-Q4: v1.0 Release (MVP complete)
             │
2027 Q1:     ├── v1.1: Mascot + Eye Exercise Basics
             │
2027 Q2:     ├── v1.5: Late Night Guardian + Medical Tips
             │
2027 Q3:     ├── v2.0: Color Balance + LLM Integration
             │
2027 Q4:     ├── v2.5: Adaptive Timing + Full Exercise Library
             │
2028 Q1:     ├── v3.0: Webcam Detection + iOS Companion
             │
2028 Q2:     ├── v3.5: watchOS + Health Integration
             │
2028 Q3+:    └── v4.0: Gamification + Family Sharing
```

---

## Prioritization Framework

Features are prioritized using ICE scoring:

| Feature | Impact (1-10) | Confidence (1-10) | Ease (1-10) | Score |
|---------|---------------|-------------------|-------------|-------|
| Mascot/Sprite | 8 | 9 | 7 | 504 |
| Eye Exercises | 9 | 9 | 5 | 405 |
| Late Night Guardian | 8 | 8 | 8 | 512 |
| Medical Tips | 6 | 9 | 9 | 486 |
| Color Balance | 5 | 6 | 6 | 180 |
| LLM Integration | 9 | 7 | 4 | 252 |
| Adaptive Timing | 7 | 5 | 3 | 105 |
| Webcam Detection | 6 | 4 | 2 | 48 |
| iOS/watchOS | 9 | 8 | 2 | 144 |
| Health Integration | 5 | 8 | 6 | 240 |
| Gamification | 7 | 7 | 5 | 245 |
| Family Sharing | 5 | 5 | 2 | 50 |

**Recommended build order** (by ICE score):
1. Late Night Guardian (512)
2. Mascot/Sprite (504)
3. Medical Tips (486)
4. Eye Exercise Animations (405)
5. LLM Integration (252)
6. Gamification (245)
7. Health Integration (240)
8. Color Balance (180)
9. iOS/watchOS (144)
10. Adaptive Timing (105)
11. Family Sharing (50)
12. Webcam Detection (48)

---

*Document version: 0.1*
*Last updated: 2026-04-14*
*Author: PM Agent*
