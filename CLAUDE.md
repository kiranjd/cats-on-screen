# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Desktop cat that walks on your windows. Native Swift. One-time purchase. Ships fast.

Differentiators vs competitors (Docko, CozyPet, DeskPet):
- Walks ON TOP of actual windows (not just wallpaper)
- $5 once, forever (no subscription)
- <0.5% CPU (native, not Electron)
- Zero tracking, zero cloud

## Commands

```bash
# Build and run (development)
swift build && swift run

# Build release + create .app bundle
./build.sh
# Then: open CatOnScreen.app

# Build release only
swift build -c release
```

## Architecture

### Rendering Stack
```
CatApp.swift → AppDelegate → OverlayWindow → SKView → CatScene → CatNode
```

- **OverlayWindow** (`NSPanel`): Transparent fullscreen overlay that floats above all windows. Uses `ignoresMouseEvents` dynamically—clicks pass through except when mouse is directly over the cat.
- **CatScene** (`SKScene`): SpriteKit scene with transparent background. Updates cat position at 60fps, handles click-through toggle.
- **CatNode** (`SKSpriteNode`): The cat sprite. Manages state machine (walking/idle/jumping/sleeping/interacting), texture animations, and movement physics.

### Window Detection
**WindowDetector** (singleton): Polls `CGWindowListCopyWindowInfo` every 500ms to get window rects. Handles coordinate conversion between CGWindow (origin top-left, Y down) and SpriteKit (origin bottom-left, Y up).

Key methods:
- `getWalkableSurfaces()` → cached list of window top edges
- `findSurfaceBelow(point:)` → find window to walk on
- `findNextSurface(from:currentY:direction:)` → gap detection for jumping

### Cat State Machine
```
walking → idle (via tap)
walking → jumping (edge detected)
walking → sleeping (5min system idle)
jumping → walking (landed)
sleeping → walking (user activity)
idle → interacting (menu selection)
interacting → walking (action complete)
```

### Click-Through Behavior
In `CatScene.updateWindowClickThrough()`:
- Every frame: check if mouse is over cat sprite
- Over cat: `ignoresMouseEvents = false` (cat is clickable)
- Not over cat: `ignoresMouseEvents = true` (clicks pass to windows below)

## Asset Files

Located in `Sources/CatOnScreen/Resources/Assets/`:

| Asset | Status |
|-------|--------|
| cat_walking_0-6.png | Done (7 frames) |
| cat_sitting.png | Done |
| cat_being_petted.png | Done |
| cat_scratching.png | Done |
| cat_eating.png | Done |
| cat_sleeping.png | Done |
| cat_jumping.png | Done |
| menubar_icon.png | TODO |
| cat_black_*.png | TODO |
| cat_orange_*.png | TODO |

## Ship Order

### Phase 1: MVP
1. Window walking (done - cat pathfinds across window title bars)
2. Menu bar app (TODO)
3. Click-through fix (done)
4. 3 cat breeds (TODO - palette swaps)

### Phase 2: Polish
5. Idle mood (done - sleeps after 5min idle)
6. Sound effects (TODO)
7. Do Not Disturb awareness (TODO)

### Phase 3: Multiplier
8. Multi-cat (2-5 cats with flocking)
9. Window jump physics (done - arc trajectory)

## Rules

- **Ship > Perfect** - Working code beats planning
- **Native only** - No web views, no Electron patterns
- **Performance matters** - Profile before adding features
- **Privacy sacred** - Zero analytics, zero network calls
- **One file at a time** - Don't refactor everything, just fix what's broken

When in doubt: make the cat cuter and ship it.
