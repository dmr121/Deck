//
//  DeckConfiguration.swift
//  Deck
//
//  Created by David Rozmajzl on 2/15/26.
//

import SwiftUI

/// Configuration options that determine the physical behavior of the deck's cards.
public struct DeckConfig {
    /// The percentage of the view's width a user must drag a card before it commits to a swipe (e.g., `0.33` for 33%).
    public let dragThreshold: CGFloat
    /// The maximum number of degrees the card will rotate while being dragged.
    public let maxRotation: Double
    /// The animation type for when the card snaps back to the top of the deck.
    public let animation: Animation
    /// The animation type for when the card snaps back to the top of the deck when the user presses undo.
    public let undoAnimation: Animation
    
    /// Initializes a new deck configuration.
    /// - Parameters:
    ///   - dragThreshold: The distance required to trigger a swipe, represented as a multiplier of the view's width. Defaults to `0.33`.
    ///   - maxRotation: The maximum rotation applied to the card in degrees. Defaults to `15`.
    public init(
        dragThreshold: CGFloat = 0.33,
        maxRotation: Double = 15,
        animation: Animation = .spring(duration: 0.3, bounce: 0.4),
        undoAnimation: Animation = .spring(duration: 0.48, bounce: 0.24)
    ) {
        self.dragThreshold = dragThreshold
        self.maxRotation = maxRotation
        self.animation = animation
        self.undoAnimation = undoAnimation
    }
}
