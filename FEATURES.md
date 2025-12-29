# Cats on Screen - Feature Roadmap

> One-time purchase. Native Swift. Privacy-first. No Electron garbage.

## Current State (v0.1)
- [x] Walking animation (8-frame cycle)
- [x] Idle/sitting state
- [x] Pet interaction
- [x] Scratch interaction
- [x] Feed interaction
- [x] Context menu for actions

---

## v1.0 - Launch MVP

### Core Polish
- [ ] **Smooth click-through** - Only intercept clicks directly on cat sprite
- [ ] **Menu bar icon** - Quick access, quit, preferences
- [ ] **Launch at login** - Optional startup item
- [ ] **Multiple cat breeds** - 3-4 variants (tabby, black, orange, tuxedo)

### Killer Differentiators
- [ ] **Window parkour** - Cat walks ON TOP of windows, jumps between them
  - Use `CGWindowListCopyWindowInfo` for window edges
  - Cat detects gaps, leaps across
- [ ] **Idle mood system** - Cat behavior changes based on system idle time
  - Active user → playful, running
  - 5+ min idle → sleepy, napping
  - Night (system dark mode) → curled up sleeping

### Audio (Optional)
- [ ] Subtle purring when petted
- [ ] Soft meow on feed
- [ ] Muted by default, toggle in prefs

---

## v1.1 - Multi-Cat Update

- [ ] **Cat herd mode** - 2-5 cats roaming together
  - Simple flocking/boid behavior
  - Cats interact with each other (play, chase, nap together)
- [ ] **Name your cats** - Hover tooltip shows name
- [ ] **Individual personalities** - Lazy cat, hyper cat, shy cat

---

## v1.2 - macOS Integration

- [ ] **Do Not Disturb awareness** - Cats hide/sleep during Focus modes
- [ ] **Notification reactions** - Cat perks up when notification arrives
- [ ] **Productivity mode** - Cat works at tiny laptop while you're in Xcode/VS Code
  - Looks disappointed if you open Twitter/Reddit
- [ ] **Drag file interaction** - Drop file on cat, it bats it away or purrs

---

## v2.0 - Expansion Packs (Optional Revenue)

- [ ] **Seasonal hats** - Halloween, Christmas, etc ($1.99)
- [ ] **New breeds** - Siamese, Persian, Maine Coon ($2.99)
- [ ] **Furniture** - Cat bed, scratching post, food bowl ($1.99)

---

## Technical Requirements

| Metric | Target |
|--------|--------|
| CPU (idle) | <0.5% |
| CPU (animating) | <2% |
| RAM | <30MB |
| Binary size | <10MB |
| Min macOS | 11.0 (Big Sur) |

---

## Pricing Strategy

**Launch:** $4.99-$6.99 one-time
**Positioning:** "Buy once, pet forever"
**Trial:** 7-day free trial via App Store

---

## Marketing Hooks

1. **"Not Electron"** - Benchmark video showing CPU vs competitors
2. **"No subscription"** - Direct callout to Docko's $10/mo
3. **"Privacy-first"** - Zero analytics, zero cloud, zero tracking
4. **"Native Mac citizen"** - Respects Focus modes, integrates with OS

---

## Launch Channels

1. Reddit r/MacApps (proven: 170 upvotes on competitor post)
2. Product Hunt
3. Hacker News "Show HN"
4. TikTok/Reels - Cat during Zoom calls
5. r/cats crosspost (massive audience)
