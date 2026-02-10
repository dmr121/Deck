//
//  Deck.swift
//  tinder test
//
//  Created by David Rozmajzl on 2/3/26.
//

import SwiftUI

/// A Tinder-style swipeable card stack container.
///
/// `Deck` renders a stack of cards based on the provided items and handles the complex logic of
/// swiping, undoing, scaling background cards, and managing memory/rendering performance.
///
/// You configure the deck using a declarative modifier syntax:
/// ```swift
/// Deck(items: profiles, manager: viewModel)
///     .content { profile, overlays in
///         // Place your card content and the overlays in a ZStack
///         ZStack {
///             ...
///             overlays
///         }
///     }
///     .swipeDirections([.left, .right])
///     .onSwipe { item, direction in
///         print("Swiped \(item) to \(direction)")
///     }
/// ```
public struct Deck<Item: Sendable, Content, Overlay, Detail>: View
where Item: Identifiable & Equatable, Item.ID: Sendable, Content: View, Overlay: View, Detail: View {
    
    // MARK: - Properties
    
    private let items: [Item]
    private var manager: DeckViewModel<Item>
    
    /// The closure to render the card content. Accepts the item and the system overlay view (AnyView).
    private let content: (Item, AnyView) -> Content
    
    private let overlay: (SwipeDirection) -> Overlay
    private let detail: (Item) -> Detail
    
    // Configuration properties
    private var allowedDirections: Set<SwipeDirection>
    private var hasDetailView: Bool
    
    // Action callbacks
    private var onSwipeAction: ((Item, SwipeDirection) -> Void)?
    private var onUndoAction: (() -> Void)?
    
    // MARK: - Initializers
    
    /// Internal initializer for reconstruction by modifiers.
    internal init(
        items: [Item],
        manager: DeckViewModel<Item>,
        content: @escaping (Item, AnyView) -> Content,
        overlay: @escaping (SwipeDirection) -> Overlay,
        detail: @escaping (Item) -> Detail,
        allowedDirections: Set<SwipeDirection> = DeckConfiguration.allowedDirections,
        hasDetailView: Bool = false,
        onSwipeAction: ((Item, SwipeDirection) -> Void)? = nil,
        onUndoAction: (() -> Void)? = nil
    ) {
        self.items = items
        self.manager = manager
        self.content = content
        self.overlay = overlay
        self.detail = detail
        self.allowedDirections = allowedDirections
        self.hasDetailView = hasDetailView
        self.onSwipeAction = onSwipeAction
        self.onUndoAction = onUndoAction
        
        // Sync items if necessary
        if manager.cards != items {
            manager.cards = items
        }
    }
    
    // MARK: - Modifiers
    
    /// Defines the content view for each card in the deck.
    ///
    /// The closure provides:
    /// 1. `item`: The data model.
    /// 2. `overlays`: A View containing the Swipe Overlays (Like/Nope) and Detail View.
    ///
    /// **Important:** You MUST add `overlays` to your ZStack, otherwise swipe indicators will not appear.
    /// - Parameter content: A closure returning the card view.
    public func content<NewContent: View>(
        @ViewBuilder _ content: @escaping (Item, AnyView) -> NewContent
    ) -> Deck<Item, NewContent, Overlay, Detail> {
        Deck<Item, NewContent, Overlay, Detail>(
            items: items,
            manager: manager,
            content: content,
            overlay: overlay,
            detail: detail,
            allowedDirections: allowedDirections,
            hasDetailView: hasDetailView,
            onSwipeAction: onSwipeAction,
            onUndoAction: onUndoAction
        )
    }
    
    /// Defines the overlay view to display when a card is swiped.
    ///
    /// - Parameter overlay: A closure that takes a `SwipeDirection` and returns a View.
    public func overlay<NewOverlay: View>(
        @ViewBuilder _ overlay: @escaping (SwipeDirection) -> NewOverlay
    ) -> Deck<Item, Content, NewOverlay, Detail> {
        Deck<Item, Content, NewOverlay, Detail>(
            items: items,
            manager: manager,
            content: content,
            overlay: overlay,
            detail: detail,
            allowedDirections: allowedDirections,
            hasDetailView: hasDetailView,
            onSwipeAction: onSwipeAction,
            onUndoAction: onUndoAction
        )
    }
    
    /// Defines the detail view to display when a card is held down (long pressed).
    ///
    /// If this modifier is excluded, the long-press gesture will be disabled.
    /// - Parameter detail: A closure that takes an `Item` and returns a View.
    public func detail<NewDetail: View>(
        @ViewBuilder _ detail: @escaping (Item) -> NewDetail
    ) -> Deck<Item, Content, Overlay, NewDetail> {
        Deck<Item, Content, Overlay, NewDetail>(
            items: items,
            manager: manager,
            content: content,
            overlay: overlay,
            detail: detail,
            allowedDirections: allowedDirections,
            hasDetailView: true, // Mark detail as present
            onSwipeAction: onSwipeAction,
            onUndoAction: onUndoAction
        )
    }
    
    /// Sets the allowed swipe directions for this specific Deck instance.
    ///
    /// - Parameter directions: The set of allowed directions.
    public func swipeDirections(_ directions: Set<SwipeDirection>) -> Self {
        var copy = self
        copy.allowedDirections = directions
        return copy
    }
    
    /// Registers a callback to be executed when a card is fully swiped off-screen.
    ///
    /// This callback is triggered for both manual gestures and programmatic swipes.
    /// - Parameter action: A closure receiving the swiped `Item` and the `SwipeDirection`.
    public func onSwipe(_ action: @escaping (Item, SwipeDirection) -> Void) -> Self {
        var copy = self
        copy.onSwipeAction = action
        return copy
    }
    
    /// Registers a callback to be executed when an Undo operation occurs.
    ///
    /// This callback is triggered for both tap-to-undo and programmatic undo.
    /// - Parameter action: A closure to execute on undo.
    public func onUndo(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onUndoAction = action
        return copy
    }
    
    // MARK: - Body
    
    // Helper to calculate scale based on drag distance
    private func getScale(for item: Item) -> CGFloat {
        if item.id == manager.topCard?.id || manager.exitingCardIds.contains(item.id) {
            return 1.0
        }
        
        guard let index = manager.cards.firstIndex(of: item) else { return 0.95 }
        let distance = index - manager.currentIndex
        
        // Scale only the card immediately behind the top card
        if distance == 1 {
            let maxDist = max(abs(manager.currentDragOffset.width), abs(manager.currentDragOffset.height))
            let progress = min(maxDist / DeckConfiguration.swipeThreshold, 1.0)
            return 0.95 + (0.05 * progress)
        }
        
        return 0.95
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(manager.renderableCards.reversed()) { item in
                    InternalCardContainer(
                        item: item,
                        manager: manager,
                        viewSize: geo.size,
                        content: content,
                        overlay: overlay,
                        detail: detail,
                        allowedDirections: allowedDirections,
                        hasDetailView: hasDetailView,
                        onSwipe: onSwipeAction // Pass callback down
                    )
                    .zIndex(Double(manager.cards.count - (manager.cards.firstIndex(of: item) ?? 0)))
                    .transition(.identity)
                    .scaleEffect(getScale(for: item))
                    // Ensures smooth interpolation of scale when drag is released
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: getScale(for: item))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.default, value: manager.currentIndex)
            // Monitor Undo state changes here to trigger the callback
            .onChange(of: manager.undoItem?.item.id) { _, newValue in
                // If undoItem is set, an undo action just started
                if newValue != nil {
                    onUndoAction?()
                }
            }
        }
    }
}

// MARK: - Convenience Extension

public extension Deck where Content == EmptyView, Overlay == EmptyView, Detail == EmptyView {
    
    /// Initializes a generic `Deck` with no content, overlays, or details.
    ///
    /// Use the modifier methods `.content()`, `.overlay()`, and `.detail()` to populate the views.
    init(items: [Item], manager: DeckViewModel<Item>) {
        self.init(
            items: items,
            manager: manager,
            content: { _, _ in EmptyView() },
            overlay: { _ in EmptyView() },
            detail: { _ in EmptyView() },
            allowedDirections: DeckConfiguration.allowedDirections,
            hasDetailView: false
        )
    }
}

