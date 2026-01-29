import Foundation
import CoreGraphics

class GestureAnalyzer {
    private var touchPoints: [CGPoint] = []
    private var directions: [GestureDirection] = []
    private var lastDirectionChangePoint: CGPoint?

    private let threshold: CGFloat
    private let directionChangeThreshold: CGFloat

    init(threshold: CGFloat = KeyboardMetrics.gestureThreshold,
         directionChangeThreshold: CGFloat = KeyboardMetrics.directionChangeThreshold) {
        self.threshold = threshold
        self.directionChangeThreshold = directionChangeThreshold
    }

    func reset() {
        touchPoints.removeAll()
        directions.removeAll()
        lastDirectionChangePoint = nil
    }

    func addPoint(_ point: CGPoint) {
        touchPoints.append(point)
        analyzeLatestMovement()
    }

    func getDirections() -> [GestureDirection] {
        return directions
    }

    func getStartPoint() -> CGPoint? {
        return touchPoints.first
    }

    private func analyzeLatestMovement() {
        guard touchPoints.count >= 2 else { return }

        let referencePoint = lastDirectionChangePoint ?? touchPoints.first!
        let currentPoint = touchPoints.last!

        let vector = CGVector(
            dx: currentPoint.x - referencePoint.x,
            dy: currentPoint.y - referencePoint.y
        )

        guard let newDirection = GestureDirection.from(vector: vector, threshold: threshold) else {
            return
        }

        // Check if this is a new direction or continuation
        if let lastDirection = directions.last {
            // Only add if direction changed
            if newDirection != lastDirection {
                // Make sure we've moved enough from the last direction change
                let distance = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
                if distance >= directionChangeThreshold {
                    directions.append(newDirection)
                    lastDirectionChangePoint = currentPoint
                }
            }
        } else {
            // First direction
            directions.append(newDirection)
            lastDirectionChangePoint = currentPoint
        }
    }

    func finalizeGesture() -> [GestureDirection] {
        return filterIntermediateDiagonals(directions)
    }

    /// Remove intermediate diagonals that appear between two cardinal directions during direction transitions
    /// For example: [.up, .upRight, .right] → [.up, .right]
    /// But preserve intentional diagonal inputs like [.upLeft] → [.upLeft] for ㅣ
    private func filterIntermediateDiagonals(_ dirs: [GestureDirection]) -> [GestureDirection] {
        guard dirs.count >= 3 else { return dirs }

        var filtered: [GestureDirection] = []

        for (index, dir) in dirs.enumerated() {
            let isFirst = index == 0
            let isLast = index == dirs.count - 1

            // First and last directions are always kept
            if isFirst || isLast {
                // Exception: if last is cardinal and previous is an adjacent diagonal,
                // handle trailing noise
                if isLast && dir.isCardinal && !filtered.isEmpty {
                    if let last = filtered.last, last.isDiagonal && last.isAdjacentTo(dir) {
                        // But if that diagonal is the first direction, keep it (intentional input)
                        if filtered.count == 1 {
                            // Keep first diagonal, discard trailing cardinal
                            continue
                        }
                        filtered.removeLast()
                    }
                }
                filtered.append(dir)
                continue
            }

            // Middle directions: skip diagonals between two cardinals
            let prev = dirs[index - 1]
            let next = dirs[index + 1]

            if dir.isDiagonal && prev.isCardinal && next.isCardinal {
                // Intermediate diagonal is transition noise → skip
                continue
            }

            filtered.append(dir)
        }

        return filtered
    }
}

// Extension to help with gesture visualization
extension GestureAnalyzer {
    var directionString: String {
        directions.map { $0.symbol }.joined()
    }

    var hasGesture: Bool {
        !directions.isEmpty
    }
}
