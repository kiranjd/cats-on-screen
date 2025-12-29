import Cocoa

// MARK: - Activity Hierarchy
// Parent States: Walking, Running, Sitting
// Sitting Activities: sitdown, yarn, belly, wave, front

enum MovementMode {
    case walking
    case running
}

enum SittingActivity: String, CaseIterable {
    case sitdown   // Sit and scratch nose
    case yarn      // Play with yarn ball
    case belly     // Belly rub / roll
    case wave      // Wave paw
    case front     // Face user (the money shot!)
}

enum AppCatState {
    case moving(MovementMode)
    case sitting(SittingActivity)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var catWindow: NSWindow!
    var statusItem: NSStatusItem!
    var catImageView: NSImageView!

    // MARK: - Animation Frames
    // Movement frames (direction-aware)
    var walkingFrames: (left: [NSImage], right: [NSImage]) = ([], [])
    var runningFrames: (left: [NSImage], right: [NSImage]) = ([], [])

    // Sitting activity frames (direction-aware, except front which is symmetric)
    var sittingFrames: [SittingActivity: (left: [NSImage], right: [NSImage])] = [:]

    // MARK: - State
    var state: AppCatState = .moving(.walking)
    var direction: CGFloat = 1  // 1 = right, -1 = left
    var currentFrame: Int = 0

    var animationTimer: Timer?
    var movementTimer: Timer?

    var distanceWalked: CGFloat = 0
    var distanceSinceRunCheck: CGFloat = 0
    var activitiesThisTrip: Int = 0
    let baseSpeed: CGFloat = 1.0

    // Golden frames for cuteness (indices into front frames)
    // F4: big eyes, F5: eyes closed, F6: eyes open, F7: wink
    // F2, F3: head tilt
    let goldenFramesBigEyes = [4, 6, 4]      // Big eyes sequence
    let goldenFramesBlink = [4, 5, 4]        // Blink sequence
    let goldenFramesWink = [6, 7, 6]         // Wink sequence
    let goldenFramesCurious = [0, 2, 3, 2]   // Head tilt sequence

    // MARK: - Image Helpers

    /// Crossfade to new image - use for state/activity transitions
    func setImageWithCrossfade(_ newImage: NSImage, duration: TimeInterval = 0.15) {
        guard let layer = catImageView.layer else {
            catImageView.image = newImage
            return
        }

        let transition = CATransition()
        transition.type = .fade
        transition.duration = duration
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(transition, forKey: "crossfade")
        catImageView.image = newImage
    }

    func flipImageHorizontally(_ image: NSImage) -> NSImage {
        let flipped = NSImage(size: image.size)
        flipped.lockFocus()
        let transform = NSAffineTransform()
        transform.translateX(by: image.size.width, yBy: 0)
        transform.scaleX(by: -1, yBy: 1)
        transform.concat()
        image.draw(at: .zero, from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1.0)
        flipped.unlockFocus()
        return flipped
    }

    func loadFrames(prefix: String, count: Int) -> (left: [NSImage], right: [NSImage]) {
        var left: [NSImage] = []
        var right: [NSImage] = []

        for i in 0..<count {
            let name = "\(prefix)_\(i)"
            var image: NSImage?

            if let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Assets") {
                image = NSImage(contentsOf: url)
            }
            if image == nil, let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets") {
                image = NSImage(contentsOf: url)
            }

            if let img = image {
                left.append(img)
                right.append(flipImageHorizontally(img))
            }
        }

        NSLog("🐱 Loaded \(left.count) \(prefix) frames")
        return (left, right)
    }

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("🐱🐱🐱 CAT APP STARTING 🐱🐱🐱")

        // Load movement frames
        walkingFrames = loadFrames(prefix: "cat_walking", count: 8)
        runningFrames = loadFrames(prefix: "cat_running", count: 8)

        // Load sitting activity frames
        sittingFrames[.sitdown] = loadFrames(prefix: "cat_sitdown", count: 8)
        sittingFrames[.yarn] = loadFrames(prefix: "cat_yarn", count: 4)
        sittingFrames[.belly] = loadFrames(prefix: "cat_belly", count: 4)
        sittingFrames[.wave] = loadFrames(prefix: "cat_wave", count: 8)
        sittingFrames[.front] = loadFrames(prefix: "cat_front", count: 8)

        guard !walkingFrames.left.isEmpty else {
            NSLog("🐱 ERROR: No walking frames loaded!")
            return
        }

        setupWindow()
        startMoving(.walking)

        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
    }

    func setupWindow() {
        // Window matches 700x550 canvas aspect ratio exactly (no alignment issues)
        let catSize = NSSize(width: 140, height: 110)  // 700:550 = 140:110
        catWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: catSize.width, height: catSize.height),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        catWindow.isOpaque = false
        catWindow.backgroundColor = .clear
        catWindow.hasShadow = false
        catWindow.level = .floating
        catWindow.ignoresMouseEvents = true
        catWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        catImageView = NSImageView(frame: NSRect(origin: .zero, size: catSize))
        catImageView.image = walkingFrames.right[0]
        catImageView.imageScaling = .scaleProportionallyUpOrDown
        catImageView.wantsLayer = true  // Enable layer for crossfade transitions
        catWindow.contentView = catImageView

        // Random start - safe distance from edges, cat fully visible
        if let screen = NSScreen.main {
            direction = Bool.random() ? 1 : -1
            let safeMargin: CGFloat = 200
            let x = direction > 0 ? safeMargin : screen.frame.width - safeMargin - catSize.width
            catWindow.setFrameOrigin(NSPoint(x: x, y: 8))
        }

        catWindow.orderFrontRegardless()
        NSLog("🐱 Window shown")
    }

    // MARK: - Movement State

    func startMoving(_ mode: MovementMode) {
        state = .moving(mode)
        animationTimer?.invalidate()

        let frames = mode == .running ? runningFrames : walkingFrames
        let currentFrames = direction > 0 ? frames.right : frames.left
        let frameInterval = mode == .running ? 0.05 : 0.08

        currentFrame = 0
        // Crossfade into first frame of new movement
        if !currentFrames.isEmpty {
            setImageWithCrossfade(currentFrames[0], duration: 0.12)
        }

        animationTimer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { [weak self] _ in
            guard let self = self, !currentFrames.isEmpty else { return }
            self.currentFrame = (self.currentFrame + 1) % currentFrames.count
            // Crossfade every frame for smooth animation
            self.setImageWithCrossfade(currentFrames[self.currentFrame], duration: frameInterval * 0.8)
        }

        // Start movement if not already moving
        if movementTimer == nil {
            movementTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
                self?.updateMovement()
            }
        }

        NSLog("🐱 Now \(mode == .running ? "running" : "walking")")
    }

    func updateMovement() {
        guard let screen = NSScreen.main else { return }

        // Only move when in moving state
        guard case .moving(let mode) = state else { return }

        let speed = mode == .running ? baseSpeed * 2.5 : baseSpeed
        var origin = catWindow.frame.origin
        origin.x += speed * direction
        distanceWalked += abs(speed)
        distanceSinceRunCheck += abs(speed)

        // Random mode switch (20% chance every 150px, separate counter)
        if distanceSinceRunCheck > 150 && !runningFrames.left.isEmpty {
            distanceSinceRunCheck = 0
            if Int.random(in: 0...4) == 0 {
                let newMode: MovementMode = mode == .walking ? .running : .walking
                startMoving(newMode)
            }
        }

        // Random sit down (only when walking, 35% chance every 180px)
        if mode == .walking && distanceWalked > 180 && activitiesThisTrip < 4 {
            distanceWalked = 0
            if Int.random(in: 0...2) == 0 {
                startSitting()
                return
            }
        }

        // Screen bounds - turn around with safe margin so cat is fully visible
        let safeMargin: CGFloat = 150
        if origin.x > screen.frame.width - safeMargin - catWindow.frame.width {
            origin.x = screen.frame.width - safeMargin - catWindow.frame.width
            catWindow.setFrameOrigin(origin)
            activitiesThisTrip = 0
            distanceWalked = 0
            distanceSinceRunCheck = 0

            // Show cute turn then continue in new direction
            showFrontTurn { [weak self] in
                self?.direction = -1
                self?.startMoving(.walking)
            }
            return
        } else if origin.x < safeMargin {
            origin.x = safeMargin
            catWindow.setFrameOrigin(origin)
            activitiesThisTrip = 0
            distanceWalked = 0
            distanceSinceRunCheck = 0

            // Show cute turn then continue in new direction
            showFrontTurn { [weak self] in
                self?.direction = 1
                self?.startMoving(.walking)
            }
            return
        }

        catWindow.setFrameOrigin(origin)
    }

    func refreshMovementAnimation() {
        guard case .moving(let mode) = state else { return }
        startMoving(mode)
    }

    // MARK: - Front-on Transitions

    /// Sitdown transition frames to bridge height difference (Walk 400px → Sitdown 414px → Front 520px)
    let sitdownBridgeFrames = [0, 1, 2, 3]  // First 4 frames of sitdown for settling
    let sitdownExitFrames = [3, 2, 1, 0]    // Reverse for getting back up

    /// Show cute front-on sequence when turning at screen edges
    /// Uses sitdown as bridge: Walk → Sitdown → Front → Sitdown → completion
    func showFrontTurn(then completion: @escaping () -> Void) {
        guard let frontFrames = sittingFrames[.front]?.left, frontFrames.count > 5,
              let sitdownFrames = sittingFrames[.sitdown] else {
            completion()
            return
        }

        animationTimer?.invalidate()
        state = .sitting(.sitdown)

        // Phase 1: Play sitdown bridge (settling down)
        let bridgeFrames = direction > 0 ? sitdownFrames.right : sitdownFrames.left
        var bridgeIndex = 0

        // Crossfade into first sitdown frame
        if let firstFrame = sitdownBridgeFrames.first, firstFrame < bridgeFrames.count {
            setImageWithCrossfade(bridgeFrames[firstFrame], duration: 0.15)
            bridgeIndex = 1
        }

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            if bridgeIndex < self.sitdownBridgeFrames.count {
                let frameIdx = self.sitdownBridgeFrames[bridgeIndex]
                if frameIdx < bridgeFrames.count {
                    self.setImageWithCrossfade(bridgeFrames[frameIdx], duration: 0.10)
                }
                bridgeIndex += 1
            } else {
                timer.invalidate()
                // Phase 2: Now show the front-on golden frames
                self.playGoldenFrames(frontFrames: frontFrames, then: {
                    // Phase 3: Exit via sitdown (getting back up)
                    self.playSitdownExit(bridgeFrames: bridgeFrames, then: completion)
                })
            }
        }

        NSLog("🐱 Cute turn with crossfade!")
    }

    /// Play the golden frames sequence (big eyes, blink, wink)
    private func playGoldenFrames(frontFrames: [NSImage], then completion: @escaping () -> Void) {
        state = .sitting(.front)

        // Pick a random cute sequence
        let sequences = [goldenFramesBigEyes, goldenFramesBlink, goldenFramesWink]
        let sequence = sequences.randomElement() ?? goldenFramesBigEyes

        var index = 0
        // Crossfade into first golden frame (sitdown → front is the big height change)
        if let firstIdx = sequence.first, firstIdx < frontFrames.count {
            setImageWithCrossfade(frontFrames[firstIdx], duration: 0.2)
            index = 1
        }

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.40, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            if index < sequence.count {
                let frameIdx = sequence[index]
                if frameIdx < frontFrames.count {
                    self.setImageWithCrossfade(frontFrames[frameIdx], duration: 0.35)
                }
                index += 1
            } else {
                timer.invalidate()
                completion()
            }
        }
    }

    /// Play sitdown exit frames (reverse of bridge - cat getting back up)
    private func playSitdownExit(bridgeFrames: [NSImage], then completion: @escaping () -> Void) {
        state = .sitting(.sitdown)

        var exitIndex = 0
        // Crossfade from front back to sitdown (big height change)
        if let firstIdx = sitdownExitFrames.first, firstIdx < bridgeFrames.count {
            setImageWithCrossfade(bridgeFrames[firstIdx], duration: 0.2)
            exitIndex = 1
        }

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            if exitIndex < self.sitdownExitFrames.count {
                let frameIdx = self.sitdownExitFrames[exitIndex]
                if frameIdx < bridgeFrames.count {
                    self.setImageWithCrossfade(bridgeFrames[frameIdx], duration: 0.08)
                }
                exitIndex += 1
            } else {
                timer.invalidate()
                completion()
            }
        }
    }

    /// Show a brief front-on moment between activities
    /// Uses sitdown as bridge for smoother transition
    func showFrontMoment(then completion: @escaping () -> Void) {
        guard let frontFrames = sittingFrames[.front]?.left, frontFrames.count > 5,
              let sitdownFrames = sittingFrames[.sitdown] else {
            completion()
            return
        }

        animationTimer?.invalidate()
        state = .sitting(.sitdown)

        // Phase 1: Quick sitdown bridge (shorter for moments)
        let bridgeFrames = direction > 0 ? sitdownFrames.right : sitdownFrames.left
        let quickBridge = [0, 1, 2]  // Faster bridge for moments
        var bridgeIndex = 0

        // Crossfade into first frame
        if let firstIdx = quickBridge.first, firstIdx < bridgeFrames.count {
            setImageWithCrossfade(bridgeFrames[firstIdx], duration: 0.12)
            bridgeIndex = 1
        }

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            if bridgeIndex < quickBridge.count {
                let frameIdx = quickBridge[bridgeIndex]
                if frameIdx < bridgeFrames.count {
                    self.setImageWithCrossfade(bridgeFrames[frameIdx], duration: 0.08)
                }
                bridgeIndex += 1
            } else {
                timer.invalidate()
                // Phase 2: Show curious/wink sequence
                self.playMomentFrames(frontFrames: frontFrames, then: {
                    // Phase 3: Quick exit
                    self.playQuickExit(bridgeFrames: bridgeFrames, then: completion)
                })
            }
        }
    }

    /// Play moment frames (curious, wink sequences - shorter than turn)
    private func playMomentFrames(frontFrames: [NSImage], then completion: @escaping () -> Void) {
        state = .sitting(.front)

        // Pick curious or wink sequence
        let sequences = [goldenFramesCurious, goldenFramesWink, goldenFramesBlink]
        let sequence = sequences.randomElement() ?? goldenFramesCurious

        var index = 0
        // Crossfade into first frame
        if let firstIdx = sequence.first, firstIdx < frontFrames.count {
            setImageWithCrossfade(frontFrames[firstIdx], duration: 0.18)
            index = 1
        }

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            if index < sequence.count {
                let frameIdx = sequence[index]
                if frameIdx < frontFrames.count {
                    self.setImageWithCrossfade(frontFrames[frameIdx], duration: 0.30)
                }
                index += 1
            } else {
                timer.invalidate()
                completion()
            }
        }
    }

    /// Quick exit for moments (shorter reverse)
    private func playQuickExit(bridgeFrames: [NSImage], then completion: @escaping () -> Void) {
        state = .sitting(.sitdown)

        let quickExit = [2, 1, 0]
        var exitIndex = 0

        // Crossfade into first exit frame
        if let firstIdx = quickExit.first, firstIdx < bridgeFrames.count {
            setImageWithCrossfade(bridgeFrames[firstIdx], duration: 0.12)
            exitIndex = 1
        }

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            if exitIndex < quickExit.count {
                let frameIdx = quickExit[exitIndex]
                if frameIdx < bridgeFrames.count {
                    self.setImageWithCrossfade(bridgeFrames[frameIdx], duration: 0.06)
                }
                exitIndex += 1
            } else {
                timer.invalidate()
                completion()
            }
        }
    }

    // MARK: - Sitting State

    func startSitting() {
        // Pick a random sitting activity
        let availableActivities = SittingActivity.allCases.filter { activity in
            if let frames = sittingFrames[activity] {
                return !frames.left.isEmpty
            }
            return false
        }

        guard let activity = availableActivities.randomElement() else {
            return
        }

        performSittingActivity(activity)
    }

    func performSittingActivity(_ activity: SittingActivity) {
        guard let frames = sittingFrames[activity] else { return }

        // Front-facing doesn't need direction flip (symmetric)
        let currentFrames = activity == .front ? frames.left : (direction > 0 ? frames.right : frames.left)
        guard !currentFrames.isEmpty else { return }

        state = .sitting(activity)
        activitiesThisTrip += 1
        animationTimer?.invalidate()

        var frameIndex = 0
        let loopCount = Int.random(in: 5...9)  // Let the cat take its time (was 3-5)
        var currentLoop = 0
        var pauseFrames = 0  // Number of frames to pause

        // Crossfade into first frame
        if !currentFrames.isEmpty {
            setImageWithCrossfade(currentFrames[0], duration: 0.20)
            frameIndex = 1
        }

        // Much slower, relaxed animation - let the cat enjoy its activities
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.28, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            // Handle multi-frame pauses (cat lingers on cute moments)
            if pauseFrames > 0 {
                pauseFrames -= 1
                return
            }

            if frameIndex < currentFrames.count {
                // Crossfade every frame for smooth dreamy effect
                self.setImageWithCrossfade(currentFrames[frameIndex], duration: 0.22)
                frameIndex += 1

                // 35% chance to pause 1-3 frames on cute moments
                if Int.random(in: 0...2) == 0 {
                    pauseFrames = Int.random(in: 1...3)
                }
            } else {
                currentLoop += 1
                if currentLoop < loopCount {
                    frameIndex = 0  // Loop animation

                    // 50% chance to pause 2-4 frames between loops (cat resting)
                    if Int.random(in: 0...1) == 0 {
                        pauseFrames = Int.random(in: 2...4)
                    }
                } else {
                    timer.invalidate()

                    // 50% chance to show front-on moment before next action
                    let showFrontFirst = Int.random(in: 0...1) == 0 && activity != .front

                    if showFrontFirst {
                        self.showFrontMoment {
                            self.finishActivity()
                        }
                    } else {
                        self.finishActivity()
                    }
                }
            }
        }

        NSLog("🐱 Doing activity: \(activity.rawValue)")
    }

    /// Called after activity ends to decide next action
    private func finishActivity() {
        // Maybe chain another sitting activity (40% chance, was 30%)
        if Int.random(in: 0...4) < 2 && activitiesThisTrip < 5 {
            startSitting()
        } else {
            // Get up and walk
            // 40% chance to change direction
            if Int.random(in: 0...4) < 2 {
                direction *= -1
            }
            startMoving(.walking)
        }
    }

    // MARK: - Controls

    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        movementTimer?.invalidate()
        movementTimer = nil
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Cat")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Cat", action: #selector(toggleCat), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func toggleCat() {
        if catWindow.isVisible {
            catWindow.orderOut(nil)
            stopAnimation()
        } else {
            catWindow.orderFrontRegardless()
            startMoving(.walking)
        }
    }

    @objc func quitApp() {
        stopAnimation()
        NSApp.terminate(nil)
    }
}
