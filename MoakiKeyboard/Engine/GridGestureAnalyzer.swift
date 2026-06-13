import Foundation
import CoreGraphics

/// Shared interface so the keyboard can switch recognition strategies at runtime.
protocol GestureRecognizing: AnyObject {
    func reset()
    func addPoint(_ point: CGPoint)
    func getDirections() -> [GestureDirection]
    func getStartPoint() -> CGPoint?
    func finalizeGesture() -> [GestureDirection]
}

// The existing angle-sector analyzer already satisfies the interface.
extension GestureAnalyzer: GestureRecognizing {}

/// Grid / axis-decomposition based gesture analyzer.
///
/// Uses the same multi-stroke pipeline as `GestureAnalyzer`, but classifies each
/// segment by decomposing the movement into horizontal/vertical components instead
/// of fixed angle sectors. A segment is treated as a *diagonal* (↗ ↘ ↖ ↙) only when
/// the minor axis is at least `diagonalRatio` of the major axis; otherwise it snaps
/// to the dominant cardinal. This keeps cardinals (ㅏㅓㅗㅜ) forgiving and stops
/// diagonals (ㅣ ↗ / ㅡ ↘) from stealing them — the main source of mis-types.
final class GridGestureAnalyzer: GestureRecognizing {
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
    private let diagonalRatio: CGFloat

    init(threshold: CGFloat = KeyboardMetrics.gestureThreshold,
         reversalThreshold: CGFloat = KeyboardMetrics.reversalThreshold,
         directionChangeThreshold: CGFloat = KeyboardMetrics.directionChangeThreshold,
         diagonalRatio: CGFloat = KeyboardMetrics.diagonalRatio) {
        self.threshold = threshold
        self.reversalThreshold = reversalThreshold
        self.directionChangeThreshold = directionChangeThreshold
        self.diagonalRatio = diagonalRatio
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

    func getDirections() -> [GestureDirection] { directions }

    func getStartPoint() -> CGPoint? { touchPoints.first }

    private func analyzeLatestMovement() {
        guard touchPoints.count >= 2 else { return }

        let referencePoint = lastDirectionChangePoint ?? touchPoints.first!
        let currentPoint = touchPoints.last!

        let vector = CGVector(dx: currentPoint.x - referencePoint.x,
                              dy: currentPoint.y - referencePoint.y)
        let magnitude = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)

        var newDirection = classify(vector: vector, threshold: threshold)

        // If the standard threshold fails, allow an opposite reversal at a lower threshold.
        if newDirection == nil, let lastDirection = directions.last, magnitude >= reversalThreshold {
            if let candidate = classify(vector: vector, threshold: reversalThreshold),
               candidate.isOpposite(to: lastDirection) {
                newDirection = candidate
            }
        }

        guard let newDirection else { return }

        if let lastDirection = directions.last {
            if newDirection != lastDirection {
                if magnitude >= directionChangeThreshold || (newDirection.isOpposite(to: lastDirection) && magnitude >= reversalThreshold) {
                    directions.append(newDirection)
                    directionMagnitudes.append(magnitude)
                    lastDirectionChangePoint = currentPoint
                }
            }
        } else {
            directions.append(newDirection)
            directionMagnitudes.append(magnitude)
            lastDirectionChangePoint = currentPoint
        }
    }

    /// Classify a movement vector by axis decomposition.
    /// iOS y-axis is inverted, so negative dy means "up".
    private func classify(vector: CGVector, threshold: CGFloat) -> GestureDirection? {
        let ax = abs(vector.dx)
        let ay = abs(vector.dy)
        let magnitude = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        guard magnitude >= threshold else { return nil }

        let major = max(ax, ay)
        guard major > 0 else { return nil }
        let ratio = min(ax, ay) / major

        let horizontal: GestureDirection = vector.dx >= 0 ? .right : .left
        let vertical: GestureDirection = vector.dy < 0 ? .up : .down

        if ratio >= diagonalRatio {
            switch (vertical, horizontal) {
            case (.up, .right): return .upRight
            case (.up, .left): return .upLeft
            case (.down, .right): return .downRight
            case (.down, .left): return .downLeft
            default: return nil
            }
        }
        return ax >= ay ? horizontal : vertical
    }

    func finalizeGesture() -> [GestureDirection] {
        let segments = zip(directions, directionMagnitudes).map {
            DirectionSegment(direction: $0.0, magnitude: $0.1)
        }
        return normalizeSegments(segments).map { $0.direction }
    }

    // MARK: - Normalization (ported verbatim from GestureAnalyzer)

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
                if index > 1 { index -= 1 }
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

extension GridGestureAnalyzer {
    var directionString: String { directions.map { $0.symbol }.joined() }
    var hasGesture: Bool { !directions.isEmpty }
}
