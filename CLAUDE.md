# Cats on Screen

**Desktop cat that walks on your windows. Native Swift. One-time purchase. Ships fast.**

## The Pitch

Docko charges $10/mo for a dock pet. CozyPet is pixel art fluff. DeskPet is free garbage.

We're building the premium native Mac cat that:
- Walks ON TOP of your actual windows (not just wallpaper)
- Costs $5 once, forever
- Uses <0.5% CPU (not Electron trash)
- Zero tracking, zero cloud, zero bullshit

## Current State

Working prototype:
- 8-frame walk cycle
- Pet/scratch/feed interactions
- Walks above dock

## Ship Order (DO THIS)

### Phase 1: MVP (THIS WEEK)

1. **Window walking** - Cat walks on window title bars
   - `CGWindowListCopyWindowInfo` to get window rects
   - Cat pathfinds across visible windows
   - Jumps gaps between windows

2. **Menu bar app** - Proper Mac citizen
   - Menu bar icon (cat face)
   - Quit, Preferences, Hide Cat
   - Launch at login toggle

3. **Click-through fix** - Don't block user clicks
   - `ignoresMouseEvents = true` except on cat sprite
   - Only intercept when mouse directly over cat

4. **3 cat breeds** - Ship variety
   - Tabby (current)
   - Black cat
   - Orange cat
   - Same animations, palette swap

### Phase 2: Polish (NEXT WEEK)

5. **Idle mood** - Cat gets sleepy
   - Track `CGEventSource.secondsSinceLastEventType`
   - 5min idle → cat naps
   - User returns → cat wakes, stretches

6. **Sound effects** - Optional, muted default
   - Purr on pet
   - Meow on feed
   - Prefs toggle

7. **Do Not Disturb** - Respect Focus modes
   - Cat hides during Focus
   - Returns when Focus ends

### Phase 3: Multiplier (WEEK 3)

8. **Multi-cat** - 2-5 cats
   - Simple flocking behavior
   - Cats interact (chase, nap together)

9. **Window jump physics** - Cat leaps between windows
   - Arc trajectory
   - Landing animation

## Tech Stack

```
/Sources/CatOnScreen/
├── main.swift           # Entry point
├── AppDelegate.swift    # Menu bar, lifecycle
├── CatWindow.swift      # Overlay window
├── CatScene.swift       # SpriteKit scene
├── CatNode.swift        # Cat sprite + animations
├── WindowDetector.swift # CGWindowList integration
└── Resources/Assets/    # Textures
```

## Commands

```bash
# Build and run
cd ~/things/cats-on-screen
swift build && swift run

# Build release
swift build -c release
```

## Art Assets Needed

Located in `Sources/CatOnScreen/Resources/Assets/`:

| Asset | Status |
|-------|--------|
| cat_walking_0-7.png | Done |
| cat_sitting.png | Done |
| cat_being_petted.png | Done |
| cat_scratching.png | Done |
| cat_eating.png | Done |
| cat_sleeping.png | TODO |
| cat_jumping.png | TODO |
| cat_landing.png | TODO |
| menubar_icon.png | TODO |
| cat_black_*.png | TODO |
| cat_orange_*.png | TODO |

## Pricing

- **$4.99** one-time on Mac App Store
- 7-day free trial
- No IAP, no subscription, no bullshit

## Launch Plan

1. Ship MVP to TestFlight
2. Post on r/MacApps with video
3. Product Hunt launch
4. Done

## Rules for Claude

- **Ship > Perfect** - Working code beats planning
- **Native only** - No web views, no Electron patterns
- **Performance matters** - Profile before adding features
- **Privacy sacred** - Zero analytics, zero network calls
- **One file at a time** - Don't refactor everything, just fix what's broken

When in doubt: make the cat cuter and ship it.
