import Foundation
import CoreGraphics

enum GestureDirection: String, CaseIterable {
    case up        // ↑
    case down      // ↓
    case left      // ←
    case right     // →
    case upLeft    // ↖
    case upRight   // ↗
    case downLeft  // ↙
    case downRight // ↘

    static func from(vector: CGVector, threshold: CGFloat = 20) -> GestureDirection? {
        let magnitude = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        guard magnitude >= threshold else { return nil }

        let angle = atan2(-vector.dy, vector.dx) // Negative dy because iOS y-axis is inverted
        let degrees = angle * 180 / .pi

        // Normalize to 0-360
        let normalizedDegrees = degrees < 0 ? degrees + 360 : degrees

        // 8 directions with 45-degree sectors
        switch normalizedDegrees {
        case 337.5...360, 0..<22.5:
            return .right
        case 22.5..<67.5:
            return .upRight
        case 67.5..<112.5:
            return .up
        case 112.5..<157.5:
            return .upLeft
        case 157.5..<202.5:
            return .left
        case 202.5..<247.5:
            return .downLeft
        case 247.5..<292.5:
            return .down
        case 292.5..<337.5:
            return .downRight
        default:
            return .right
        }
    }

    var symbol: String {
        switch self {
        case .up: return "↑"
        case .down: return "↓"
        case .left: return "←"
        case .right: return "→"
        case .upLeft: return "↖"
        case .upRight: return "↗"
        case .downLeft: return "↙"
        case .downRight: return "↘"
        }
    }

    var isCardinal: Bool {
        switch self {
        case .up, .down, .left, .right: return true
        default: return false
        }
    }

    var isDiagonal: Bool {
        !isCardinal
    }

    /// Check if two directions are adjacent (e.g., up and upRight are adjacent)
    func isAdjacentTo(_ other: GestureDirection) -> Bool {
        let adjacencyMap: [GestureDirection: Set<GestureDirection>] = [
            .up: [.upLeft, .upRight],
            .down: [.downLeft, .downRight],
            .left: [.upLeft, .downLeft],
            .right: [.upRight, .downRight],
            .upLeft: [.up, .left],
            .upRight: [.up, .right],
            .downLeft: [.down, .left],
            .downRight: [.down, .right]
        ]
        return adjacencyMap[self]?.contains(other) ?? false
    }
}
