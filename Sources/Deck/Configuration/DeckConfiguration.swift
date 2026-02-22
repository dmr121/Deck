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
    
    /// The duration for the opacity fade-in animation of the new card after a swipe.
    public let fadeInDuration: TimeInterval
    
    /// Initializes a new deck configuration.
    /// - Parameters:
    ///   - dragThreshold: The distance required to trigger a swipe, represented as a multiplier of the view's width. Defaults to `0.33`.
    ///   - maxRotation: The maximum rotation applied to the card in degrees during a drag. Defaults to `20`.
    public init(
        dragThreshold: CGFloat = 0.33,
        maxRotation: Double = 20,
        swipeOutAnimation: Animation = .easeIn(duration: 0.3),
        programmaticSwipeAnimation: Animation = .easeIn(duration: 0.33),
        undoAnimation: Animation = .easeInOut(duration: 0.33),
        swipeDuration: TimeInterval = 0.45,
        undoDuration: TimeInterval = 0.28,
        swipeDelay: TimeInterval = 0.12,
        undoDelay: TimeInterval = 0.12,
        fadeInDuration: TimeInterval = 0.2,
        snapBackAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7)
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
        self.fadeInDuration = fadeInDuration
    }
}
