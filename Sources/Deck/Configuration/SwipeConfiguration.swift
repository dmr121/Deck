//
//  SwipeConfiguration.swift
//  tinder test
//
//  Created by David Rozmajzl on 2/3/26.
//

import Foundation

/// Represents the physical direction a card is being swiped or dragged.
///
/// This enum is used to determine:
/// 1. The direction of the user's gesture.
/// 2. Which overlay to display (e.g., "Like" for right, "Nope" for left).
/// 3. The exit trajectory of the card.
public enum SwipeDirection: CaseIterable, Sendable {
    /// A swipe towards the left side of the screen.
    case left
    
    /// A swipe towards the right side of the screen.
    case right
    
    /// A swipe towards the top of the screen.
    case up
    
    /// A swipe towards the bottom of the screen.
    case down
}
