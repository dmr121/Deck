//
//  SwipePhysics.swift
//  tinder test
//
//  Created by David Rozmajzl on 2/3/26.
//

import SwiftUI

/// Internal structure responsible for calculating drag vectors, escape vectors, and swipe intent.
///
/// - Note: This is an internal helper and is not exposed to the public API.
internal struct SwipePhysics {
    let viewSize: CGSize
    
    /// Calculates the "escape" vector. When a user releases a card past the threshold,
    /// this calculates where the card should fly off to ensure it leaves the screen completely.
    func projectEscapeVector(from offset: CGSize) -> CGSize {
        let diag = sqrt(pow(viewSize.width, 2) + pow(viewSize.height, 2))
        let mag = max(sqrt(pow(offset.width, 2) + pow(offset.height, 2)), 1.0)
        return CGSize(width: offset.width * (diag * 1.5 / mag), height: offset.height * (diag * 1.5 / mag))
    }
    
    /// Calculates a target point off-screen for a programmatic swipe (e.g., button press).
    func targetPoint(for dir: SwipeDirection) -> CGSize {
        let d = max(viewSize.width, viewSize.height) * 2.0
        switch dir {
        case .left: return CGSize(width: -d, height: -50)
        case .right: return CGSize(width: d, height: -50)
        case .up: return CGSize(width: 0, height: -d)
        case .down: return CGSize(width: 0, height: d)
        }
    }
    
    /// Determines the intent of a swipe based on the current drag offset.
    ///
    /// - Returns: A `SwipeDirection` if the offset exceeds the `DeckConfiguration.swipeThreshold`, otherwise `nil`.
    func determineDirection(from o: CGSize) -> SwipeDirection? {
        if abs(o.width) > abs(o.height) {
            return abs(o.width) > DeckConfiguration.swipeThreshold ? (o.width > 0 ? .right : .left) : nil
        } else {
            return abs(o.height) > DeckConfiguration.swipeThreshold ? (o.height > 0 ? .down : .up) : nil
        }
    }
    
    /// Determines the active direction for showing overlays while dragging.
    ///
    /// This is more sensitive than `determineDirection` to provide immediate visual feedback.
    static func activeDirection(for o: CGSize) -> SwipeDirection? {
        guard abs(o.width) > 5 || abs(o.height) > 5 else { return nil }
        return abs(o.width) > abs(o.height) ? (o.width > 0 ? .right : .left) : (o.height > 0 ? .down : .up)
    }
    
    /// Calculates the opacity of the overlay based on how far the card has been dragged relative to the threshold.
    static func opacity(for o: CGSize, threshold: CGFloat) -> Double {
        min(Double(max(abs(o.width), abs(o.height)) / threshold), 1.0)
    }
}
