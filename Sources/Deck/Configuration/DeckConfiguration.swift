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
    /// The maximum number of degrees the card will rotate while being dragged by a finger.
    public let maxRotation: Double
    /// The maximum number of degrees the card will rotate when swiped programmatically or undone.
    public let programmaticMaxRotation: Double
    
    /// The animation type for when the user successfully swipes a card off the screen with their finger.
    public let swipeOutAnimation: Animation
    /// The animation type for when the card is swiped programmatically.
    public let programmaticSwipeAnimation: Animation
    /// The animation type for when the card snaps back into view when the user presses undo.
    public let undoAnimation: Animation
    /// The animation type for when the card snaps back to the center of the deck after a canceled drag.
    public let snapBackAnimation: Animation
    
    /// The duration to wait before cleaning up the swiped card from the view.
    public let swipeDuration: TimeInterval
    /// The duration to wait before cleaning up the undone card from the view.
    public let undoDuration: TimeInterval
    
    /// The delay in seconds before another card can be swiped.
    public let swipeDelay: TimeInterval
    /// The delay in seconds before another card can be undone.
    public let undoDelay: TimeInterval
    
    /// Initializes a new deck configuration.
    /// - Parameters:
    ///   - dragThreshold: The distance required to trigger a swipe, represented as a multiplier of the view's width. Defaults to `0.33`.
    ///   - maxRotation: The maximum rotation applied to the card in degrees during a drag. Defaults to `20`.
    public init(
        dragThreshold: CGFloat = 0.33,
        maxRotation: Double = 20,
        swipeOutAnimation: Animation = .easeOut(duration: 0.55),
        programmaticSwipeAnimation: Animation = .spring(response: 0.55, dampingFraction: 0.75),
        undoAnimation: Animation = .spring(response: 0.36, dampingFraction: 0.78),
        snapBackAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.6),
        swipeDuration: TimeInterval = 0.55,
        undoDuration: TimeInterval = 0.36,
        swipeDelay: TimeInterval = 0.25,
        undoDelay: TimeInterval = 0.22
    ) {
        self.dragThreshold = dragThreshold
        self.maxRotation = maxRotation
        self.programmaticMaxRotation = maxRotation * 2.25
        self.swipeOutAnimation = swipeOutAnimation
        self.programmaticSwipeAnimation = programmaticSwipeAnimation
        self.undoAnimation = undoAnimation
        self.snapBackAnimation = snapBackAnimation
        self.swipeDuration = swipeDuration
        self.undoDuration = undoDuration
        self.swipeDelay = swipeDelay
        self.undoDelay = undoDelay
    }
}
