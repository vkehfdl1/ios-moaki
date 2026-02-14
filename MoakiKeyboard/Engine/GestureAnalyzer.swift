import Foundation
import CoreGraphics

class GestureAnalyzer {
    private struct DirectionSegment {
        var direction: GestureDirection
        var magnitude: CGFloat
    }

    private var touchPoints: [CGPoint] = []
    private var directions: [GestureDirection] = []
    private var directionMagnitudes: [CGFloat] = []
    private var lastDirectionChangePoint: CGPoint?

    private let threshold: CGFloat
    private let reversalThreshold: CGFloat
    private let directionChangeThreshold: CGFloat

    init(threshold: CGFloat = KeyboardMetrics.gestureThreshold,
         reversalThreshold: CGFloat = KeyboardMetrics.reversalThreshold,
         directionChangeThreshold: CGFloat = KeyboardMetrics.directionChangeThreshold) {
        self.threshold = threshold
        self.reversalThreshold = reversalThreshold
        self.directionChangeThreshold = directionChangeThreshold
    }

    func reset() {
        touchPoints.removeAll()
        directions.removeAll()
        directionMagnitudes.removeAll()
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

        let magnitude = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)

        // Try detecting direction with standard threshold first
        var newDirection = GestureDirection.from(vector: vector, threshold: threshold)

        // If standard threshold fails, try lower reversal threshold for opposite directions
        if newDirection == nil, let lastDirection = directions.last, magnitude >= reversalThreshold {
            if let candidate = GestureDirection.from(vector: vector, threshold: reversalThreshold),
               candidate.isOpposite(to: lastDirection) {
                newDirection = candidate
            }
        }

        guard let newDirection else { return }

        // Check if this is a new direction or continuation
        if let lastDirection = directions.last {
            // Only add if direction changed
            if newDirection != lastDirection {
                // Make sure we've moved enough from the last direction change
                if magnitude >= directionChangeThreshold || (newDirection.isOpposite(to: lastDirection) && magnitude >= reversalThreshold) {
                    directions.append(newDirection)
                    directionMagnitudes.append(magnitude)
                    lastDirectionChangePoint = currentPoint
                }
            }
        } else {
            // First direction
            directions.append(newDirection)
            directionMagnitudes.append(magnitude)
            lastDirectionChangePoint = currentPoint
        }
    }

    func finalizeGesture() -> [GestureDirection] {
        let segments = zip(directions, directionMagnitudes).map {
            DirectionSegment(direction: $0.0, magnitude: $0.1)
        }
        return normalizeSegments(segments).map { $0.direction }
    }

    /// Keep intentional turns for 3-stroke gestures (important for ㅙ/ㅞ),
    /// while removing duplicate and jitter-only segments.
    private func normalizeSegments(_ segments: [DirectionSegment]) -> [DirectionSegment] {
        guard !segments.isEmpty else { return [] }

        var collapsed = collapseConsecutiveDuplicates(segments)
        collapsed = collapseTinyOscillations(collapsed)
        collapsed = trimTinyLeadingAndTrailingNoise(collapsed)
        return collapsed
    }

    private func collapseConsecutiveDuplicates(_ segments: [DirectionSegment]) -> [DirectionSegment] {
        guard !segments.isEmpty else { return [] }

        var result: [DirectionSegment] = [segments[0]]
        for segment in segments.dropFirst() {
            if segment.direction == result.last?.direction {
                if segment.magnitude > (result.last?.magnitude ?? 0) {
                    result[result.count - 1].magnitude = segment.magnitude
                }
                continue
            }
            result.append(segment)
        }
        return result
    }

    private func collapseTinyOscillations(_ segments: [DirectionSegment]) -> [DirectionSegment] {
        guard segments.count >= 3 else { return segments }

        var result = segments
        var index = 1

        let jitterMagnitudeCap = max(reversalThreshold, directionChangeThreshold * 0.8)
        let jitterRatio: CGFloat = 0.75

        while index < result.count - 1 {
            let previous = result[index - 1]
            let current = result[index]
            let next = result[index + 1]

            let returnsToPrevious = previous.direction == next.direction
            let isAdjacentJitter = current.direction.isAdjacentTo(previous.direction)
            let isTinySegment = current.magnitude <= jitterMagnitudeCap ||
                current.magnitude <= min(previous.magnitude, next.magnitude) * jitterRatio

            if returnsToPrevious && isAdjacentJitter && isTinySegment {
                result[index - 1].magnitude = max(previous.magnitude, next.magnitude)
                result.remove(at: index + 1)
                result.remove(at: index)
                if index > 1 {
                    index -= 1
                }
                continue
            }

            index += 1
        }

        return result
    }

    private func trimTinyLeadingAndTrailingNoise(_ segments: [DirectionSegment]) -> [DirectionSegment] {
        guard segments.count > 1 else { return segments }

        var result = segments
        let edgeNoiseCap = max(reversalThreshold, directionChangeThreshold * 0.8)

        if let first = result.first, let second = result.dropFirst().first {
            if first.magnitude <= edgeNoiseCap && first.direction.isAdjacentTo(second.direction) {
                result.removeFirst()
            }
        }

        if result.count > 1, let last = result.last, let previous = result.dropLast().last {
            if last.magnitude <= edgeNoiseCap && last.direction.isAdjacentTo(previous.direction) {
                result.removeLast()
            }
        }

        return result
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
