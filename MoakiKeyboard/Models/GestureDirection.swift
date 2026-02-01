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

        // 8 directions with adjusted sectors (narrower diagonals for ㅣ, ㅡ)
        switch normalizedDegrees {
        case 330...360, 0..<30:
            return .right
        case 30..<60:
            return .upRight
        case 60..<120:
            return .up
        case 120..<150:
            return .upLeft
        case 150..<210:
            return .left
        case 210..<240:
            return .downLeft
        case 240..<300:
            return .down
        case 300..<330:
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
