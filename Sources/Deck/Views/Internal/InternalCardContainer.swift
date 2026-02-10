//
//  InternalCardContainer.swift
//  tinder test
//
//  Created by David Rozmajzl on 2/3/26.
//

import SwiftUI

/// An internal container that bridges the `DeckViewModel` logic with the `DraggableCardView`.
///
/// This component handles:
/// * Triggering exit animations.
/// * Managing the "Detail" hold gesture logic (only if a detail view is present).
/// * Syncing the View's local offset state with the ViewModel.
/// * Watching for programmatic swipes or undos.
/// * Executing the user's `onSwipe` callback.
internal struct InternalCardContainer<Item, Content, Overlay, Detail>: View
where Item: Sendable & Identifiable & Equatable, Item.ID: Sendable, Content: View, Overlay: View, Detail: View {
    let item: Item
    var manager: DeckViewModel<Item>
    let viewSize: CGSize
    
    // UPDATED: Content closure now accepts the system overlays (as AnyView to avoid type recursion)
    let content: (Item, AnyView) -> Content
    
    let overlay: (SwipeDirection) -> Overlay
    let detail: (Item) -> Detail
    
    // Config
    let allowedDirections: Set<SwipeDirection>
    let hasDetailView: Bool
    
    /// Closure triggered when the card is successfully swiped.
    let onSwipe: ((Item, SwipeDirection) -> Void)?
    
    @State private var offset: CGSize = .zero
    @State private var showDetail: Bool = false
    @State private var dragTask: Task<Void, Never>? = nil
    
    var isInteractable: Bool { manager.canInteract(with: item) }
    
    var body: some View {
        DraggableCardView(
            isTopCard: isInteractable,
            offset: offset,
            content: {
                // 1. Create the strongly-typed system overlay
                let systemOverlay = DeckSystemOverlay(
                    offset: offset,
                    showDetail: showDetail,
                    allowedDirections: allowedDirections,
                    swipeThreshold: DeckConfiguration.swipeThreshold,
                    overlayBuilder: overlay,
                    detailBuilder: { detail(item) }
                )
                
                // 2. Wrap it in AnyView (Type Erasure) and pass to user content
                return content(item, AnyView(systemOverlay))
            },
            onDragChanged: { change in
                offset = change
                manager.currentDragOffset = change
                
                // Only start detail timer if the user actually provided a detail view
                if hasDetailView && dragTask == nil {
                    dragTask = Task {
                        try? await Task.sleep(nanoseconds: UInt64(DeckConfiguration.detailDragDelay * 1_000_000_000))
                        if !Task.isCancelled {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDetail = true
                            }
                        }
                    }
                }
            },
            onDragEnded: { finalOffset in
                dragTask?.cancel()
                dragTask = nil
                
                // Animate reset of drag offset to prevent snap in scaling for background cards
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                    manager.currentDragOffset = .zero
                }
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDetail = false
                }
                
                let physics = SwipePhysics(viewSize: viewSize)
                if let direction = physics.determineDirection(from: finalOffset),
                   allowedDirections.contains(direction) {
                    
                    // Trigger the swipe callback
                    onSwipe?(item, direction)
                    
                    let escape = physics.projectEscapeVector(from: finalOffset)
                    withAnimation(DeckConfiguration.flightAnimation) { self.offset = escape }
                    manager.startExiting(item, direction: direction, finalOffset: escape)
                } else {
                    withAnimation(DeckConfiguration.resetAnimation) { self.offset = .zero }
                }
            }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                if isInteractable && DeckConfiguration.tapToUndo {
                    manager.undo()
                    // Note: onUndo is handled in Deck.swift by observing the ViewModel
                    // to capture both tap-based and button-based undos.
                }
            }
        )
        // Watch for Programmatic Swipes
        .onChange(of: manager.pendingSwipe[item.id]) { _, direction in
            if let direction = direction {
                // Trigger the swipe callback
                onSwipe?(item, direction)
                
                let physics = SwipePhysics(viewSize: viewSize)
                let target = physics.targetPoint(for: direction)
                withAnimation(DeckConfiguration.flightAnimation) { self.offset = target }
                manager.startExiting(item, direction: direction, finalOffset: target)
            }
        }
        // Watch for Undo events (Fixes "Missing Top Card" bug)
        .onChange(of: manager.undoItem?.item.id) { _, newValue in
            if newValue == item.id, let undoData = manager.undoItem {
                offset = undoData.offset
                withAnimation(DeckConfiguration.resetAnimation) {
                    offset = .zero
                }
                manager.undoItem = nil
            }
        }
        // Initial setup for Undo
        .onAppear {
            if let undoData = manager.undoItem, undoData.item.id == item.id {
                offset = undoData.offset
                withAnimation(DeckConfiguration.resetAnimation) { offset = .zero }
                manager.undoItem = nil
            }
        }
    }
}

