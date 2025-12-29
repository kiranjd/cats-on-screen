import Cocoa

class SimpleCatView: NSImageView {
    private var walkingFrames: [NSImage] = []
    private var currentFrame: Int = 0
    private var animationTimer: Timer?
    private var movementTimer: Timer?

    private var direction: CGFloat = 1  // 1 = right, -1 = left
    private var speed: CGFloat = 2  // pixels per frame

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        // Load walking frames
        for i in 0...7 {
            if let url = Bundle.module.url(forResource: "cat_walking_\(i)", withExtension: "png", subdirectory: "Assets"),
               let image = NSImage(contentsOf: url) {
                walkingFrames.append(image)
            }
        }

        NSLog("🐱 SimpleCatView: Loaded \(walkingFrames.count) frames")

        if let firstFrame = walkingFrames.first {
            self.image = firstFrame
            self.imageScaling = .scaleProportionallyUpOrDown
        }

        // Note: Don't set wantsLayer for transparent windows
    }

    func startAnimating() {
        NSLog("🐱 Starting animation")

        // Frame animation (walk cycle)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.nextFrame()
        }

        // Movement
        movementTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.move()
        }
    }

    func stopAnimating() {
        animationTimer?.invalidate()
        movementTimer?.invalidate()
    }

    private func nextFrame() {
        guard !walkingFrames.isEmpty else { return }
        currentFrame = (currentFrame + 1) % walkingFrames.count
        self.image = walkingFrames[currentFrame]
    }

    private func move() {
        guard let superview = self.superview else { return }

        var newX = self.frame.origin.x + (speed * direction)

        // Screen wrap
        if newX > superview.bounds.width {
            newX = -self.frame.width
        } else if newX < -self.frame.width {
            newX = superview.bounds.width
        }

        self.frame.origin.x = newX

        // Note: Flipping handled elsewhere (for now, cat always walks right)
    }
}
