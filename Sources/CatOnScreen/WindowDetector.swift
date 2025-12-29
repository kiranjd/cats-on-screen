import Cocoa
import CoreGraphics

struct WindowSurface {
    let rect: CGRect
    let name: String
    let ownerName: String

    // Top edge where cat can walk
    var walkableY: CGFloat {
        return rect.maxY
    }

    var minX: CGFloat { rect.minX }
    var maxX: CGFloat { rect.maxX }
}

class WindowDetector {
    static let shared = WindowDetector()

    private var cachedSurfaces: [WindowSurface] = []
    private var lastUpdate: Date = .distantPast
    private let cacheInterval: TimeInterval = 0.5 // Update every 500ms

    // Apps to ignore (our own window, menubar, dock, etc)
    private let ignoredApps = [
        "CatOnScreen",
        "Dock",
        "Window Server",
        "SystemUIServer",
        "Control Center",
        "Notification Center"
    ]

    func getWalkableSurfaces() -> [WindowSurface] {
        let now = Date()
        if now.timeIntervalSince(lastUpdate) > cacheInterval {
            updateSurfaces()
            lastUpdate = now
        }
        return cachedSurfaces
    }

    private func updateSurfaces() {
        cachedSurfaces = []

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return
        }

        for windowInfo in windowList {
            guard let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
                  !ignoredApps.contains(ownerName) else {
                continue
            }

            // Skip windows that are too small or off-screen
            guard let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = boundsDict["X"],
                  let y = boundsDict["Y"],
                  let width = boundsDict["Width"],
                  let height = boundsDict["Height"] else {
                continue
            }

            // Filter out tiny windows (menus, tooltips, etc)
            guard width > 100 && height > 50 else { continue }

            // Convert from CGWindow coordinate system (origin top-left of MAIN DISPLAY)
            // to screen coordinate system (origin bottom-left)
            // CGWindowListCopyWindowInfo uses the coordinate space where (0,0) is the
            // top-left corner of the PRIMARY display, Y increases downward
            // SpriteKit/NSWindow uses a coordinate space where (0,0) is the
            // bottom-left corner of the PRIMARY display, Y increases upward
            guard let mainScreen = NSScreen.main else { continue }
            let screenHeight = mainScreen.frame.height

            // The window's TOP edge in CGWindow coords is at 'y'
            // In screen coords, that becomes: screenHeight - y
            // The window's BOTTOM edge in screen coords is: screenHeight - y - height
            let bottomInScreenCoords = screenHeight - y - height

            let rect = CGRect(x: x, y: bottomInScreenCoords, width: width, height: height)

            let windowName = windowInfo[kCGWindowName as String] as? String ?? "Window"

            let surface = WindowSurface(rect: rect, name: windowName, ownerName: ownerName)
            cachedSurfaces.append(surface)
        }

        // Sort by Y position (highest first) for pathfinding
        cachedSurfaces.sort { $0.walkableY > $1.walkableY }
    }

    // Find the surface at or below a given point
    func findSurfaceBelow(point: CGPoint) -> WindowSurface? {
        let surfaces = getWalkableSurfaces()

        // Find surfaces where the point's X is within bounds
        // and the surface top is at or below the point
        let candidates = surfaces.filter { surface in
            point.x >= surface.minX &&
            point.x <= surface.maxX &&
            surface.walkableY <= point.y + 5 // Small tolerance
        }

        // Return the highest one (closest to the cat)
        return candidates.first
    }

    // Find next surface to jump to (gap detection)
    func findNextSurface(from currentX: CGFloat, currentY: CGFloat, direction: CGFloat) -> WindowSurface? {
        let surfaces = getWalkableSurfaces()

        // Look for surfaces roughly at the same height that are in the movement direction
        let tolerance: CGFloat = 100 // Can jump to surfaces within 100px height difference

        let candidates = surfaces.filter { surface in
            let heightDiff = abs(surface.walkableY - currentY)
            let inDirection = direction > 0 ?
                surface.minX > currentX :
                surface.maxX < currentX
            return heightDiff < tolerance && inDirection
        }

        // Return closest one in the direction of movement
        if direction > 0 {
            return candidates.min { $0.minX < $1.minX }
        } else {
            return candidates.max { $0.maxX < $1.maxX }
        }
    }

    // Check if there's a gap at the current position
    func isGapAt(x: CGFloat, y: CGFloat) -> Bool {
        let surfaces = getWalkableSurfaces()
        let tolerance: CGFloat = 5

        return !surfaces.contains { surface in
            x >= surface.minX &&
            x <= surface.maxX &&
            abs(surface.walkableY - y) < tolerance
        }
    }

    // Get the floor level (bottom of screen, above dock)
    var floorLevel: CGFloat {
        return 75 // Above the dock
    }
}
