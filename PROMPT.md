# Cats on Screen - Engineering Loop

You are an engineer building the cats-on-screen macOS app. Work iteratively.

## Current Sprint: Window Parkour MVP

### Your Tasks (in order)

1. **Verify cat is walking on windows** (not just floor)
   - Run the app: `swift build && swift run`
   - Open Finder windows at different positions
   - Cat should walk ON TOP of window title bars
   - Cat should jump between windows with arc trajectory

2. **Fix any issues you find**
   - Check WindowDetector.swift coordinate math
   - Check CatNode.swift jump logic
   - Increase jump frequency for testing (currently 1-in-200 is too rare)

3. **Test and iterate**
   - Build, run, observe
   - Fix bugs
   - Repeat

### Success Criteria

When ALL of these work:
- [ ] Cat walks on window title bars (not just desktop floor)
- [ ] Cat jumps between windows with visible arc
- [ ] Cat falls to floor when no window below
- [ ] No crashes, no freezes

Output this when done:
```
<promise>WINDOW PARKOUR COMPLETE</promise>
```

### Commands

```bash
# Build and run
cd ~/things/cats-on-screen
swift build && swift run

# Kill app
pkill -f CatOnScreen

# Check logs
swift build 2>&1
```

### Key Files

- `Sources/CatOnScreen/WindowDetector.swift` - Window detection via CGWindowList
- `Sources/CatOnScreen/CatNode.swift` - Cat movement, jumping, states
- `Sources/CatOnScreen/CatScene.swift` - SpriteKit scene, update loop

### Current Issues (from QA)

1. Jump frequency too low (1-in-200 chance) - hard to observe
2. Missing cat_jumping.png and cat_sleeping.png assets
3. Need to verify coordinate flip math for multi-monitor

DO NOT ask questions. Just build, test, fix, repeat.
