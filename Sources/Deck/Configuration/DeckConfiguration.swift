//
//  DeckConfiguration.swift
//  tinder test
//
//  Created by David Rozmajzl on 2/3/26.
//

import SwiftUI

/// A configuration container for customizing the physics, animations, and interactions of the `Deck`.
///
/// You can modify these static properties to globally alter the feel of the deck.
///
/// **Example Usage:**
/// ```swift
/// // Make swipes require more distance
/// DeckConfiguration.swipeThreshold = 200.0
///
/// // Disable the ability to undo via tap
/// DeckConfiguration.tapToUndo = false
/// ```
public class DeckConfiguration {
    
    // MARK: - Physics
    
    /// The minimum distance (in points) a user must drag a card before it is considered a "swipe" upon release.
    ///
    /// If the drag distance is less than this threshold when released, the card will snap back to the center.
    /// - Default: `150.0`
    public static let swipeThreshold: CGFloat = 110.0
    
    /// The maximum rotation angle a card reaches when dragged to the edge of the screen.
    /// - Default: `15 degrees`
    public static let maxRotationAngle: Angle = .degrees(10)
    
    /// Controls how quickly the card rotates relative to the horizontal drag distance.
    ///
    /// A lower number results in faster rotation.
    /// - Default: `15.0`
    public static let rotationFactor: CGFloat = 15.0
    
    // MARK: - Animation
    
    /// The animation used when a card is swiped off the screen.
    /// - Default: A spring animation with high damping.
    public static let flightAnimation: Animation = .spring(response: 0.55, dampingFraction: 0.8)
    
    /// The animation used when a card snaps back to the center (drag cancelled) or when an undo occurs.
    /// - Default: A spring animation.
    public static let resetAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.7)
    
    /// The animation used for showing/hiding the detail overlay.
    /// - Default: `easeInOut(duration: 0.2)`
    public static let detailFadeAnimation: Animation = .easeInOut(duration: 0.2)
    
    // MARK: - Logic
    
    /// The maximum number of cards rendered in the deck at one time.
    ///
    /// Keeping this number low (e.g., 3-5) improves performance significantly.
    /// - Default: `3`
    public static let visibleCount: Int = 3
    
    /// The set of directions the user is allowed to swipe.
    ///
    /// This acts as the global default. You can override this per-deck using the `.swipeDirections()` modifier.
    /// - Default: `[.left, .right, .up, .down]`
    public static let allowedDirections: Set<SwipeDirection> = [.left, .right, .up, .down]
    
    /// The delay (in seconds) after a card is swiped before the system creates the next card's logic.
    /// - Default: `0.05`
    public static let swipeThrottleDelay: TimeInterval = 0.05
    
    // MARK: - Interactions
    
    /// Determines if tapping the top card triggers an "Undo" action.
    /// - Default: `true`
    public static let tapToUndo: Bool = true
    
    /// The minimum time interval (in seconds) required between button presses (Swipe/Undo) to prevent glitches.
    /// - Default: `0.2`
    public static let buttonActionInterval: TimeInterval = 0.1
    
    /// The duration the user must hold a card before the `detail` view fades in.
    /// - Default: `0.5`
    public static let detailDragDelay: TimeInterval = 0.5
}
