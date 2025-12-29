import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var catWindow: NSWindow!
    var statusItem: NSStatusItem!
    var catImageView: NSImageView!
    var walkingFramesLeft: [NSImage] = []   // Original sprites (cat faces left)
    var walkingFramesRight: [NSImage] = []  // Flipped sprites (cat faces right)
    var currentFrame: Int = 0
    var animationTimer: Timer?
    var movementTimer: Timer?
    var direction: CGFloat = 1  // 1 = right, -1 = left
    var speed: CGFloat = 1.0    // pixels per frame at 60fps (slower)

    // Flip image horizontally for direction change
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("🐱🐱🐱 CAT APP STARTING 🐱🐱🐱")

        // Load walking frames (original sprites face LEFT)
        NSLog("🐱 Bundle.main path: \(Bundle.main.bundlePath)")
        NSLog("🐱 Bundle.main resourcePath: \(Bundle.main.resourcePath ?? "nil")")

        for i in 0...7 {
            var image: NSImage?
            let name = "cat_walking_\(i)"

            // Try Bundle.module (SwiftPM)
            if let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Assets") {
                NSLog("🐱 Found \(name) via Bundle.module: \(url.path)")
                image = NSImage(contentsOf: url)
            }

            // Try Bundle.main with Assets subdirectory (app bundle)
            if image == nil, let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Assets") {
                NSLog("🐱 Found \(name) via Bundle.main/Assets: \(url.path)")
                image = NSImage(contentsOf: url)
            }

            // Try direct path as fallback
            if image == nil, let resourcePath = Bundle.main.resourcePath {
                let directPath = "\(resourcePath)/Assets/\(name).png"
                if FileManager.default.fileExists(atPath: directPath) {
                    NSLog("🐱 Found \(name) via direct path: \(directPath)")
                    image = NSImage(contentsOfFile: directPath)
                }
            }

            if let img = image {
                walkingFramesLeft.append(img)
                walkingFramesRight.append(flipImageHorizontally(img))
            } else {
                NSLog("⚠️ FAILED to load: \(name)")
            }
        }
        NSLog("🐱 Loaded \(walkingFramesLeft.count) walking frames")

        guard !walkingFramesLeft.isEmpty else {
            NSLog("🐱 ERROR: No frames loaded!")
            return
        }

        // Cat size
        let catSize = NSSize(width: 120, height: 120)

        // Create a small borderless window just for the cat
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

        // Create image view - start with right-facing since direction = 1
        catImageView = NSImageView(frame: NSRect(origin: .zero, size: catSize))
        catImageView.image = walkingFramesRight[0]
        catImageView.imageScaling = .scaleProportionallyUpOrDown
        catWindow.contentView = catImageView

        // Position at bottom of screen - right on the edge
        if let screen = NSScreen.main {
            let x: CGFloat = 100
            let y: CGFloat = -16  // Push down to eliminate gap
            catWindow.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Show window
        catWindow.orderFrontRegardless()
        NSLog("🐱 Window shown at: \(catWindow.frame)")

        // Start animation
        startAnimation()

        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Setup menu bar
        setupMenuBar()
    }

    func currentFrames() -> [NSImage] {
        return direction > 0 ? walkingFramesRight : walkingFramesLeft
    }

    func startAnimation() {
        // Frame animation - use direction-aware frames
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let frames = self.currentFrames()
            guard !frames.isEmpty else { return }
            self.currentFrame = (self.currentFrame + 1) % frames.count
            self.catImageView.image = frames[self.currentFrame]
        }

        // Movement
        movementTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.moveCat()
        }

        NSLog("🐱 Animation started")
    }

    func stopAnimation() {
        animationTimer?.invalidate()
        movementTimer?.invalidate()
    }

    func moveCat() {
        guard let screen = NSScreen.main else { return }

        var origin = catWindow.frame.origin
        origin.x += speed * direction

        // Screen wrap
        if origin.x > screen.frame.width {
            origin.x = -catWindow.frame.width
        } else if origin.x < -catWindow.frame.width {
            origin.x = screen.frame.width
        }

        catWindow.setFrameOrigin(origin)
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
            startAnimation()
        }
    }

    @objc func quitApp() {
        stopAnimation()
        NSApp.terminate(nil)
    }
}
