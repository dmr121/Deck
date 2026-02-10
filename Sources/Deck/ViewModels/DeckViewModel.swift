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
    public var renderableCards: [Item] {
        guard currentIndex < cards.count else { return [] }
        
        let endIndex = min(currentIndex + DeckConfiguration.visibleCount, cards.count)
        let visibleWindow = cards[currentIndex..<endIndex]
        
        let exitingCards = cards.filter { exitingCardIds.contains($0.id) }
        
        var seenIDs = Set<Item.ID>()
        var combined: [Item] = []
        for item in visibleWindow {
            if !seenIDs.contains(item.id) {
                combined.append(item)
                seenIDs.insert(item.id)
            }
        }
        for item in exitingCards {
            if !seenIDs.contains(item.id) {
                combined.append(item)
                seenIDs.insert(item.id)
            }
        }
        
        // Return sorted by original index to ensure correct Z-Stacking order
        return combined.sorted { item1, item2 in
            guard let i1 = cards.firstIndex(of: item1),
                  let i2 = cards.firstIndex(of: item2) else { return false }
            return i1 < i2
        }
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
        currentIndex = lastAction.index
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
        
        currentIndex += 1
        
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

