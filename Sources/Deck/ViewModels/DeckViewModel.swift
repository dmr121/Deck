//
//  DeckViewModel.swift
//  tinder test
//
//  Created by David Rozmajzl on 2/3/26.
//

import SwiftUI
import Observation

/// The engine that drives the `Deck`.
///
/// This class manages the array of items, the current index, the undo history, and the state of cards currently animating off-screen.
///
/// **Usage:**
/// ```swift
/// @State private var viewModel = DeckViewModel<Profile>()
///
/// // Later in the view
/// Deck(items: profiles, manager: viewModel)
/// ```
@Observable
public final class DeckViewModel<Item: Identifiable & Equatable & Sendable> where Item.ID: Sendable {
    
    // MARK: - Properties
    
    /// The complete list of items in the deck.
    ///
    /// This is the source of truth. Items are not removed from this array during swiping;
    /// instead, `currentIndex` is incremented.
    public var cards: [Item] = []
    
    /// The index of the card currently at the top of the stack.
    public var currentIndex: Int = 0
    
    /// A set of IDs representing cards that are currently in the process of animating off-screen.
    /// This prevents them from disappearing instantly when `currentIndex` changes.
    public var exitingCardIds: Set<Item.ID> = []
    
    /// If true, user interactions (swipes/drags) are temporarily disabled.
    public var isLocked: Bool = false
    
    /// The live offset of the top card being dragged.
    ///
    /// This is exposed so that background cards can react (e.g., scaling up) based on the drag distance.
    public var currentDragOffset: CGSize = .zero
    
    // MARK: - Internal State
    
    /// A stack of historical actions used to perform Undo operations.
    private var swipeHistory: [(index: Int, direction: SwipeDirection, lastOffset: CGSize)] = []
    
    /// Tracks programmatic swipe requests triggered by buttons.
    var pendingSwipe: [Item.ID: SwipeDirection] = [:]
    
    /// Stores the item currently being restored via Undo to manage its transition.
    var undoItem: (item: Item, offset: CGSize)? = nil
    
    /// Timestamp of the last button action, used for throttling.
    private var lastActionTime: Date = .distantPast
    
    // MARK: - Initialization
    
    /// Initializes a new manager.
    /// - Parameter items: The initial array of items to display.
    public init(items: [Item] = []) {
        self.cards = items
    }
    
    // MARK: - Computed Properties
    
    /// Calculates which cards should be physically rendered by the SwiftUI View.
    ///
    /// This includes:
    /// 1. The current top card.
    /// 2. The next few cards (up to `DeckConfiguration.visibleCount`).
    /// 3. Any cards currently animating off the screen.
    public var renderableCards: [(item: Item, index: Int)] {
        guard currentIndex < cards.count else { return [] }

        // 1. Exiting Cards
        // Optimization: Only scan the cards BEFORE the current index (O(N) but on a smaller subset).
        // These are cards that have been swiped but are still animating away.
        let exitingItems: [(Item, Int)] = cards.prefix(currentIndex)
            .enumerated()
            .filter { exitingCardIds.contains($0.element.id) }
            .map { ($0.element, $0.offset) }

        // 2. Visible Window
        // Optimization: Use direct slice access (O(1)) instead of searching.
        // We use .indices on the slice to get the absolute index in the main array.
        let endIndex = min(currentIndex + DeckConfiguration.visibleCount, cards.count)
        let visibleItems: [(Item, Int)] = cards[currentIndex..<endIndex]
            .indices
            .map { (cards[$0], $0) }

        // 3. Combine
        // Exiting cards (lower indices) + Visible cards (higher indices)
        // This preserves Z-order without needing a .sorted() call.
        return exitingItems + visibleItems
    }
    
    /// Returns the item currently at the top of the stack, or `nil` if the stack is exhausted.
    public var topCard: Item? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }
    
    // MARK: - Methods
    
    /// Determines if a specific item is the active top card and interaction is allowed.
    public func canInteract(with item: Item) -> Bool {
        return !isLocked && topCard?.id == item.id
    }
    
    /// Internal helper to throttle button presses.
    private func canPerformAction() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastActionTime) >= DeckConfiguration.buttonActionInterval {
            lastActionTime = now
            return true
        }
        return false
    }
    
    /// Programmatically swipes the top card in the specified direction.
    ///
    /// - Parameter direction: The direction to swipe.
    @MainActor
    public func swipe(_ direction: SwipeDirection) {
        if let top = topCard, !isLocked, canPerformAction() {
            pendingSwipe[top.id] = direction
        }
    }
    
    /// Reverses the last swipe action, bringing the card back to the top of the stack.
    @MainActor
    public func undo() {
        guard canPerformAction(), let lastAction = swipeHistory.popLast() else { return }
        
        withAnimation {
            currentIndex = lastAction.index
        }
        
        let item = cards[currentIndex]
        undoItem = (item, lastAction.lastOffset)
    }
    
    /// Internal method triggered when a card begins its exit animation.
    ///
    /// This locks the stack briefly, updates indices, and manages the `exitingCardIds` set.
    @MainActor
    public func startExiting(_ item: Item, direction: SwipeDirection, finalOffset: CGSize) {
        isLocked = true
        exitingCardIds.insert(item.id)
        
        swipeHistory.append((index: currentIndex, direction: direction, lastOffset: finalOffset))
        pendingSwipe.removeValue(forKey: item.id)
        
        withAnimation {
            currentIndex += 1
        }
        
        // Briefly lock interaction to prevent accidental double-swipes
        Task {
            try? await Task.sleep(nanoseconds: UInt64(DeckConfiguration.swipeThrottleDelay * 1_000_000_000))
            await MainActor.run { isLocked = false }
        }
        
        // Remove from exiting set after animation completes
        Task {
            let id = item.id
            try? await Task.sleep(nanoseconds: 550_000_000)
            _ = await MainActor.run {
                exitingCardIds.remove(id)
            }
        }
    }
}

