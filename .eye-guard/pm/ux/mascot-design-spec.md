# EyeGuard Mascot Design Specification

> The mascot ("精灵" / Guardian Spirit) is the heart of EyeGuard's personality.
> It is a CORE feature, not decorative -- it is the primary way users interact with break reminders.

---

## Character Design

### Identity
- **Name**: Blinky (暂定, can be user-renamed)
- **Species**: A friendly, round eye-themed creature -- part eyeball, part fairy
- **Personality**: Caring, playful, slightly clumsy, always watching out for you
- **Size**: ~64x64 points (Retina: 128x128 pixels)
- **Color palette**: Soft blue iris (#6BAAED), white sclera (#FAFAFA), rosy cheeks (#FFB5B5)

### Anatomy
```
        ┌─────────┐
       │  ╭───╮  │     <- Tiny antenna/sparkle on top
       │ │  ●  │ │     <- Large expressive iris (can move)
       │ │     │ │
       │  ╰───╯  │     <- Lower eyelid (blinks)
        └─────────┘
          ╱    ╲        <- Tiny stubby legs
         ╱      ╲
        🦶      🦶      <- Round feet
```

### ASCII Art Concept -- All States

#### 1. Idle (Default)
```
         ✧
      ╭──────╮
     │ ╭────╮ │
     │ │ ◉  │ │    <- Iris centered, calm
     │ │    │ │
     │ ╰────╯ │
      ╰──────╯
       ╱    ╲
      ○      ○
```
- Gentle scale pulse: 1.0 -> 1.03 -> 1.0 (3s cycle)
- Iris drifts slightly left/right occasionally
- Blink every 4-6 seconds (randomized)

#### 2. Blinking
```
         ✧
      ╭──────╮
     │ ╭────╮ │
     │ │────│ │    <- Eyelid closes to a line
     │ │    │ │
     │ ╰────╯ │
      ╰──────╯
       ╱    ╲
      ○      ○
```
- Duration: 150ms close, 100ms open
- Single or double blink

#### 3. Break Reminder (Alert!)
```
      ❗✧❗
      ╭──────╮
  ╭  │ ╭────╮ │  ╮    <- Arms raised, waving
  │  │ │ ◉! │ │  │
  ╰  │ │    │ │  ╯
     │ ╰────╯ │
      ╰──────╯         <- Bouncing up and down
       ╱    ╲
      ○  ⬆⬇  ○

   ╭──────────────────╮
   │ Time to rest     │
   │ your eyes! 👀    │ <- Speech bubble
   ╰──────────────────╯
```
- Jump animation: translateY -10pt, bounce back (0.5s, spring)
- Arms wave left/right (rotation ±15°, 0.3s cycle)
- Speech bubble fades in from bottom
- Exclamation marks pulse

#### 4. During Break (Exercising)
```
         ✧
      ╭──────╮
     │ ╭────╮ │
     │ │  ◉→│ │    <- Eyes following exercise direction
     │ │    │ │
     │ ╰────╯ │
      ╰──────╯
       ╱    ╲
      ○      ○
        ↔           <- Gentle sway
```
- Iris follows the exercise dot pattern
- Body sways gently side to side
- Encouraging expression (slight smile curve below iris)

#### 5. Happy (Good Compliance, Score 80+)
```
       ✨ ✧ ✨
      ╭──────╮
     │ ╭────╮ │
     │ │ ◠◡ │ │    <- Squinty happy eyes
     │ │    │ │
     │ ╰────╯ │
      ╰──────╯
       ╱    ╲
      ○      ○
         🎵
```
- Sparkle particles around head
- Slight side-to-side dance
- Musical note floats up occasionally
- Rosy cheeks more visible

#### 6. Worried (Long Continuous Use, Score < 40)
```
         ✧
      ╭──────╮
     │ ╭────╮ │
     │ │ ◉  │ │    <- Wide eye, concerned
     │ │ ~ ~│ │    <- Wavy mouth
     │ ╰────╯ │
      ╰──────╯
       ╱    ╲
      ○      ○
        💧          <- Sweat drop
```
- Sweat drop animation (appears, slides down, fades)
- Slight trembling (0.5pt jitter)
- Eye wider than normal

#### 7. Sleepy (Late Night, After 10 PM)
```
       💤
      ╭──────╮
     │ ╭────╮ │
     │ │ —  │ │    <- Half-closed eyes
     │ │  ○ │ │    <- Yawning mouth
     │ ╰────╯ │
      ╰──────╯
       ╱    ╲
      ○      ○
```
- ZZZ bubbles float up
- Slow nodding animation (head droops, snaps back)
- Occasional yawn (mouth opens wide, 1s)
- Eyelids at half-mast
- Nightcap appears after 11 PM 🧢

#### 8. Sad (Emergency Override Used)
```
         ✧
      ╭──────╮
     │ ╭────╮ │
     │ │ ◉  │ │    <- Looking down
     │ │ ︵ │ │    <- Frown
     │ ╰────╯ │
      ╰──────╯
       ╱    ╲
      ○      ○
      💧         <- Tear drop
```
- Single tear rolls down
- Slumped posture (slight downward offset)
- Returns to neutral after 30 seconds

#### 9. Celebratory (User Takes Voluntary Break)
```
     🎉 ✧ 🎉
      ╭──────╮
  ╭  │ ╭────╮ │  ╮    <- Arms up in celebration
  │  │ │ ★★ │ │  │    <- Star eyes
  ╰  │ │    │ │  ╯
     │ ╰────╯ │
      ╰──────╯
       ╱    ╲          <- Jumping
      ○  ⬆   ○
```
- Confetti particles burst
- Jump higher than break reminder jump
- Star eyes sparkle
- Plays for 2 seconds, then returns to happy state

---

## Screen Positioning

### Default Position
- Bottom-right corner of primary screen
- 20pt margin from screen edges
- Sits "on" the bottom edge (feet touching edge)

### User Repositioning
- Drag anywhere on screen
- On release: snap to nearest screen edge (top, bottom, left, right)
- Snap animation: spring physics, 0.3s
- Position persisted in UserDefaults

### Multi-Display
- Mascot lives on primary display by default
- Can be dragged to secondary display
- Remembers which display it was on

### Edge Behavior
```
Bottom edge (default):
┌─────────────────────────────────┐
│                                 │
│                                 │
│                                 │
│                           ╭──╮  │
└───────────────────────────┤🔵├──┘
                            ╰──╯

Right edge:
┌─────────────────────────────────┐
│                                 │
│                           ╭──╮──│
│                           │🔵│  │
│                           ╰──╯──│
└─────────────────────────────────┘

Top edge:
                            ╭──╮
┌───────────────────────────┤🔵├──┐
│                           ╰──╯  │
│                                 │
└─────────────────────────────────┘
```

---

## Interaction Model

### Idle State (Default)
- `ignoresMouseEvents = true` -- user can click through mascot
- Mascot is purely visual, non-intrusive
- Breathing + blink animations only

### Proximity Activation
- When mouse cursor enters ~30pt radius around mascot:
  - `ignoresMouseEvents = false`
  - Subtle glow/highlight appears
  - Mascot turns to "look at" cursor
- When mouse exits radius:
  - 0.5s delay, then `ignoresMouseEvents = true`
  - Glow fades

### Click Interactions
| Action | Result |
|--------|--------|
| Single click | Mini stats popover (score, breaks, next break) |
| Double click | Open main EyeGuard popover |
| Right click | Context menu (Hide, Preferences, About, Quit) |
| Drag | Reposition mascot |

### Break-Time Interactions
| Action | Result |
|--------|--------|
| Tap mascot | Show break options (Start Break / Snooze 5 min) |
| Ignore 10s | Speech bubble auto-dismisses, mascot returns to gentle wave |
| Start break | Mascot enters exercise-along mode |
| Snooze | Mascot nods sadly, returns to idle |

---

## Speech Bubble Design

### Visual Style
```
╭─────────────────────────╮
│  Time to rest your      │
│  eyes! Look away for    │
│  20 seconds 👀          │
╰────────────┬────────────╯
             ╰── (tail points to mascot)
```

- Background: white with 90% opacity, rounded corners (12pt radius)
- Border: 1pt, soft gray (#E0E0E0)
- Text: System font, 13pt, dark gray (#333333)
- Shadow: soft drop shadow (4pt blur, 10% opacity)
- Max width: 220pt
- Tail: triangular, points toward mascot

### Animation
- Fade in: 0.3s ease-out
- Float up from mascot: translateY -5pt during fade in
- Auto-dismiss: fade out after 10s (unless hovered)
- Hover: pauses auto-dismiss timer

### Content Types
1. **Break reminder**: "Time to rest your eyes! 👀"
2. **Medical tip**: "Did you know? Blinking spreads tears that nourish your cornea."
3. **Encouragement**: "Great job! You've taken 5 breaks today! 🌟"
4. **Late night**: "It's getting late... your eyes need sleep too 😴"
5. **Stats**: "Score: 85 | Breaks: 5/6 | Next: 4:32"

---

## Technical Implementation

### Architecture
```
MascotManager (coordinator)
├── MascotWindow (NSWindow, floating)
│   └── MascotView (SwiftUI)
│       ├── MascotSprite (character rendering)
│       ├── SpeechBubbleView (message overlay)
│       └── ParticleEffectView (sparkles, confetti)
├── MascotAnimator (animation state machine)
│   ├── IdleAnimator (breathing, blinking)
│   ├── BreakAnimator (jump, wave)
│   ├── ExerciseAnimator (eye tracking)
│   └── MoodAnimator (expression transitions)
├── MascotMoodEngine (determines current mood)
├── MascotInteractionHandler (gestures, proximity)
└── MascotPositionManager (edge snapping, persistence)
```

### NSWindow Configuration
```swift
// MascotWindow setup
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 80, height: 80),
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
)
window.level = .floating
window.isOpaque = false
window.backgroundColor = .clear
window.hasShadow = false
window.collectionBehavior = [.canJoinAllSpaces, .stationary]
window.ignoresMouseEvents = true  // Toggle for interactions
```

### Animation Specs

| Animation | Duration | Easing | Repeat |
|-----------|----------|--------|--------|
| Breathing (scale) | 3.0s | easeInOut | forever |
| Blink | 0.25s | easeInOut | timer-triggered |
| Jump (break alert) | 0.5s | spring(0.6) | 3x then stop |
| Wave (arms) | 0.3s/cycle | easeInOut | while alerting |
| Speech bubble in | 0.3s | easeOut | once |
| Speech bubble out | 0.2s | easeIn | once |
| Expression change | 0.3s | easeInOut | once (crossfade) |
| Sparkle particles | 0.5s each | linear | while happy |
| Tear drop | 1.5s | easeIn (gravity) | once |
| ZZZ float | 2.0s | easeOut | while sleepy |
| Confetti burst | 2.0s | decelerate | once |

### Performance Budget
- Idle animations: < 0.5% CPU
- Active animations (break alert): < 2% CPU
- Memory for all mascot assets: < 5 MB
- Frame rate: 60fps for all animations
- Battery impact: negligible in idle state

### Rendering Approach
- **Option A (Preferred)**: SwiftUI shapes + animations
  - Pros: Native, resolution-independent, easy to animate
  - Cons: Complex shapes may be verbose
- **Option B (Fallback)**: Asset catalog with Lottie-style frame animation
  - Pros: Designer-friendly, pixel-perfect
  - Cons: Larger bundle size, less dynamic

**Decision**: Start with SwiftUI shapes for v0.9. Evaluate Lottie for complex expressions in v1.2.

### Character Rendering (SwiftUI Shapes)
```
Body:    Circle (filled white, blue stroke)
Iris:    Circle (filled #6BAAED) with offset for gaze direction
Pupil:   Circle (filled black, smaller) inside iris
Eyelid:  Capsule shape, animated height for blink
Cheeks:  Two small circles (filled #FFB5B5, 30% opacity)
Legs:    Two small ellipses below body
Arms:    Two rounded rectangles, rotation-animated
Antenna: Small star shape on top, subtle glow
```

---

## Accessibility

- VoiceOver: "EyeGuard mascot. Current mood: happy. Score: 85."
- Reduced motion: Disable all animations, show static expressions only
- High contrast: Thicker outlines, higher opacity
- VoiceOver announcement on break reminder: "Break time. Mascot is reminding you to rest your eyes."
- Keyboard: Space to interact, Escape to dismiss speech bubble

---

## Future Possibilities (Post v2.0)

- **Wardrobe**: User can customize mascot with hats, accessories
- **Seasonal themes**: Holiday outfits (Santa hat, pumpkin, etc.)
- **Multiple mascots**: Choose from a cast of characters
- **Pet system**: Mascot grows happier/healthier with good habits over time
- **Widget**: macOS widget showing mascot + score
- **Stickers**: Export mascot as iMessage sticker pack

---

*Document version: 1.0*
*Last updated: 2026-04-14*
*Author: PM Agent*
*Related: [iteration-plan-v2.md](../specs/iteration-plan-v2.md)*
