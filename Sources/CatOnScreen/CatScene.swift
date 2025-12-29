import SpriteKit

class CatScene: SKScene {
    var catNode: CatNode!
    private var lastUpdateTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.allowsTransparency = true

        // Initialize cat node
        catNode = CatNode()
        addChild(catNode)

        // Debug: print cat info
        print("🐱 Cat created at position: \(catNode.position)")
        print("🐱 Cat size: \(catNode.size)")
        print("🐱 Cat texture: \(catNode.texture?.description ?? "nil")")
        print("🐱 Scene size: \(self.size)")

        // Start walking
        catNode.startWalking()
        print("🐱 Cat started walking, new position: \(catNode.position)")
    }

    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime == 0 ? 0.016 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        catNode.update(deltaTime: deltaTime)
        
        // Dynamic click-through handling
        updateWindowClickThrough()
    }
    
    func updateWindowClickThrough() {
        guard let window = view?.window else { return }
        
        let location = NSEvent.mouseLocation
        // Convert screen coordinates to window coordinates
        let windowPoint = window.convertPoint(fromScreen: location)
        // Convert window coordinates to scene coordinates
        let scenePoint = convertPoint(fromView: windowPoint)
        
        // Check if mouse is over the cat
        if catNode.contains(scenePoint) {
            if window.ignoresMouseEvents {
                window.ignoresMouseEvents = false
            }
        } else {
            if !window.ignoresMouseEvents {
                window.ignoresMouseEvents = true
            }
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        if catNode.contains(location), let view = self.view {
            catNode.handleTap(with: event, in: view)
        }
    }
}
