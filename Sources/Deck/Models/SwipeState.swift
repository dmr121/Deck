//
//  SwipeState.swift
//  Deck
//
//  Created by David Rozmajzl on 2/15/26.
//

/// Represents the animation lifecycle state of a swiped card.
public enum SwipeState {
    /// The card has been swiped and is animating off the screen.
    case leaving
    /// The card is being undone and is animating back onto the screen.
    case incoming
}
