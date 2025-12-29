import SpriteKit

enum CatState {
    case walking
    case idle
    case interacting
    case jumping
    case sleeping
}

class CatNode: SKSpriteNode {
    var state: CatState = .idle

    // Movement - synced to animation
    // 8 frames at 0.1s = 0.8s per cycle, 2 steps per cycle
    // Stride ~50px, so speed = 50px / 0.8s = 62.5px/s
    private var walkSpeed: CGFloat = 35 // slower for better sync
    private var direction: CGFloat = 1 // 1 = right, -1 = left
    private var currentSurface: WindowSurface?

    // Vertical bob for natural walk
    private var bobPhase: CGFloat = 0
    private var baseY: CGFloat = 0

    // Textures
    private var walkingTextures: [SKTexture] = []
    private var idleTexture: SKTexture?
    private var petTexture: SKTexture?
    private var scratchTexture: SKTexture?
    private var eatTexture: SKTexture?
    private var jumpTexture: SKTexture?
    private var sleepTexture: SKTexture?

    // Idle detection
    private var lastIdleCheck: Date = Date()
    private var isSystemIdle: Bool = false

    init() {
        super.init(texture: nil, color: .clear, size: CGSize(width: 100, height: 100))

        loadTextures()

        self.texture = walkingTextures.first
        self.size = self.texture?.size() ?? CGSize(width: 100, height: 100)
        self.anchorPoint = CGPoint(x: 0.5, y: 0)
        self.setScale(0.4)  // Production size - cat ~115px tall
        self.name = "cat"
    }

    private func loadTextures() {
        func getTexture(name: String) -> SKTexture? {
            // Try Bundle.module (SwiftPM resources)
            if let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Assets") {
                if let image = NSImage(contentsOf: url) {
                    return SKTexture(image: image)
                }
            }
            // Try Bundle.main with Assets subdirectory (app bundle)
            if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets") {
                if let image = NSImage(contentsOf: url) {
                    return SKTexture(image: image)
                }
            }
            // Try Bundle.main root (fallback)
            if let url = Bundle.main.url(forResource: name, withExtension: "png") {
                if let image = NSImage(contentsOf: url) {
                    return SKTexture(image: image)
                }
            }
            NSLog("⚠️ Failed to load texture: \(name)")
            return nil
        }

        // Walking frames
        for i in 0...7 {
            if let tex = getTexture(name: "cat_walking_\(i)") {
                walkingTextures.append(tex)
            }
        }
        NSLog("🐱 Loaded \(walkingTextures.count) walking frames")

        if walkingTextures.isEmpty {
            NSLog("⚠️ No walking frames found, trying fallback")
            if let tex = getTexture(name: "cat_walking") {
                walkingTextures.append(tex)
            }
        }

        idleTexture = getTexture(name: "cat_sitting")
        petTexture = getTexture(name: "cat_being_petted")
        scratchTexture = getTexture(name: "cat_scratching")
        eatTexture = getTexture(name: "cat_eating")
        jumpTexture = getTexture(name: "cat_jumping") ?? idleTexture
        sleepTexture = getTexture(name: "cat_sleeping") ?? idleTexture
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Movement

    func startWalking() {
        guard state != .jumping else { return }

        self.removeAction(forKey: "movement")
        self.state = .walking

        // Walking animation
        if !walkingTextures.isEmpty {
            let animateAction = SKAction.animate(with: walkingTextures, timePerFrame: 0.1)
            self.run(SKAction.repeatForever(animateAction), withKey: "walkingAnim")
        }

        // Start on floor if no position set
        if position == .zero {
            baseY = WindowDetector.shared.floorLevel
            position = CGPoint(x: -50, y: baseY)
            direction = 1
        } else {
            baseY = position.y
        }
        bobPhase = 0

        updateFacing()
    }

    private func updateFacing() {
        self.xScale = direction > 0 ? abs(self.xScale) : -abs(self.xScale)
    }

    func update(deltaTime: TimeInterval) {
        guard state == .walking else { return }

        let detector = WindowDetector.shared
        let moveAmount = walkSpeed * CGFloat(deltaTime) * direction

        // Update bob phase (synced to walk animation - 2 bobs per 0.8s cycle)
        bobPhase += CGFloat(deltaTime) * 2 * .pi / 0.4  // 0.4s per bob cycle
        let bobOffset = sin(bobPhase) * 4  // 4 pixel bob amplitude

        // Proposed new position
        var newX = position.x + moveAmount
        var newY = baseY + bobOffset

        // Check for windows to walk on
        if let surface = detector.findSurfaceBelow(point: CGPoint(x: newX, y: baseY + 50)) {
            // Snap to window top
            baseY = surface.walkableY
            newY = baseY + bobOffset
            currentSurface = surface

            // Check if we're about to walk off this window
            let willWalkOff = direction > 0 ?
                newX > surface.maxX - 20 :
                newX < surface.minX + 20

            if willWalkOff {
                // Look for next window to jump to
                if let nextSurface = detector.findNextSurface(from: newX, currentY: newY, direction: direction) {
                    jumpTo(surface: nextSurface)
                    return
                } else {
                    // No window to jump to, turn around or drop to floor
                    if newY > detector.floorLevel + 50 {
                        // Drop down
                        fallToFloor()
                        return
                    } else {
                        // Turn around
                        direction *= -1
                        updateFacing()
                        return
                    }
                }
            }
        } else {
            // Not on any window, walk on floor
            baseY = detector.floorLevel
            newY = baseY + bobOffset
            currentSurface = nil

            // Check if there's a window above we can jump onto (1-in-5 chance - aggressive for testing)
            if Int.random(in: 0...5) == 0 {
                let surfaces = detector.getWalkableSurfaces()
                // Jump to ANY visible window, not just ones directly above
                if let randomSurface = surfaces.filter({ $0.walkableY > newY + 100 }).randomElement() {
                    jumpTo(surface: randomSurface)
                    return
                }
            }
        }

        // Screen bounds check
        let screenWidth = NSScreen.main?.frame.width ?? 800
        if newX > screenWidth + 50 {
            newX = -50
        } else if newX < -50 {
            newX = screenWidth + 50
        }

        position = CGPoint(x: newX, y: newY)

        // Idle check
        checkIdleState()
    }

    // MARK: - Jumping

    private func jumpTo(surface: WindowSurface) {
        state = .jumping
        removeAllActions()

        if let jumpTex = jumpTexture {
            texture = jumpTex
        }

        let targetX = direction > 0 ? surface.minX + 30 : surface.maxX - 30
        let targetY = surface.walkableY

        // Arc jump
        let midY = max(position.y, targetY) + 80
        let duration: TimeInterval = 0.5

        let jumpPath = CGMutablePath()
        jumpPath.move(to: position)
        jumpPath.addQuadCurve(
            to: CGPoint(x: targetX, y: targetY),
            control: CGPoint(x: (position.x + targetX) / 2, y: midY)
        )

        let jumpAction = SKAction.follow(jumpPath, asOffset: false, orientToPath: false, duration: duration)
        let landAction = SKAction.run { [weak self] in
            self?.currentSurface = surface
            self?.startWalking()
        }

        run(SKAction.sequence([jumpAction, landAction]), withKey: "jump")
    }

    private func fallToFloor() {
        state = .jumping
        removeAllActions()

        let targetY = WindowDetector.shared.floorLevel
        let duration: TimeInterval = 0.3

        let fallAction = SKAction.moveTo(y: targetY, duration: duration)
        fallAction.timingMode = .easeIn

        let landAction = SKAction.run { [weak self] in
            self?.currentSurface = nil
            self?.startWalking()
        }

        run(SKAction.sequence([fallAction, landAction]), withKey: "fall")
    }

    // MARK: - Idle Detection

    private func checkIdleState() {
        let now = Date()
        guard now.timeIntervalSince(lastIdleCheck) > 2.0 else { return }
        lastIdleCheck = now

        // Check system idle time
        let idleTime = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .mouseMoved)
        let keyboardIdle = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .keyDown)
        let minIdle = min(idleTime, keyboardIdle)

        if minIdle > 300 && !isSystemIdle { // 5 minutes
            isSystemIdle = true
            goToSleep()
        } else if minIdle < 10 && isSystemIdle {
            isSystemIdle = false
            wakeUp()
        }
    }

    private func goToSleep() {
        removeAllActions()
        state = .sleeping
        texture = sleepTexture

        // Breathing animation
        let breatheIn = SKAction.scaleY(to: 0.52, duration: 1.5)
        let breatheOut = SKAction.scaleY(to: 0.48, duration: 1.5)
        breatheIn.timingMode = .easeInEaseOut
        breatheOut.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([breatheIn, breatheOut])), withKey: "breathing")
    }

    private func wakeUp() {
        removeAllActions()
        // Stretch animation then resume walking
        let stretchUp = SKAction.scaleY(to: 0.55, duration: 0.3)
        let stretchDown = SKAction.scaleY(to: 0.5, duration: 0.2)
        let resume = SKAction.run { [weak self] in
            self?.startWalking()
        }
        run(SKAction.sequence([stretchUp, stretchDown, resume]))
    }

    // MARK: - Interactions

    func handleTap(with event: NSEvent, in view: SKView) {
        guard state != .jumping else { return }

        removeAllActions()
        state = .idle
        texture = idleTexture

        let menu = NSMenu(title: "Cat Actions")
        menu.addItem(withTitle: "Pet", action: #selector(performPet), keyEquivalent: "")
        menu.addItem(withTitle: "Scratch", action: #selector(performScratch), keyEquivalent: "")
        menu.addItem(withTitle: "Feed", action: #selector(performFeed), keyEquivalent: "")

        for item in menu.items {
            item.target = self
        }

        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }

    @objc func performPet() {
        performAction(texture: petTexture, duration: 3.0)
    }

    @objc func performScratch() {
        performAction(texture: scratchTexture, duration: 3.0)
    }

    @objc func performFeed() {
        performAction(texture: eatTexture, duration: 3.0)
    }

    func performAction(texture: SKTexture?, duration: TimeInterval) {
        guard let texture = texture else { return }
        state = .interacting
        self.texture = texture

        let wait = SKAction.wait(forDuration: duration)
        let resume = SKAction.run { [weak self] in
            self?.startWalking()
        }
        run(SKAction.sequence([wait, resume]))
    }
}
