//
//  Deck.swift
//  tinder test
//
//  Created by David Rozmajzl on 2/3/26.
//
//
//  Deck.swift
//  tinder test
//
//  Created by David Rozmajzl on 2/3/26.
//

import SwiftUI

/// A view that displays a stack of cards which can be swiped in specified directions.
///
/// Use `Deck` to create a Tinder-like card swiping interface. You provide a `DeckViewModel`,
/// the allowed swipe directions, and closures to define the appearance of the card, the detail overlay,
/// and the swipe directional overlays.
///
/// Example usage:
/// ```swift
/// let viewModel = DeckViewModel(items: profiles)
///
/// Deck([.left, .right], viewModel: viewModel) { item, isOnTop in
///     CardView(profile: item)
/// } detailOverlay: { item in
///     CardDetailView(profile: item)
/// } swipeOverlay: { direction in
///     Text(direction == .left ? "NOPE" : "LIKE")
/// }
/// ```
public struct Deck<Item, Content, DetailOverlay, SwipeOverlay>: View
where Item: Identifiable & Equatable, Content: View, DetailOverlay: View, SwipeOverlay: View {
    private let allowedDirections: Set<SwipeDirection>
    private let viewModel: DeckViewModel<Item>
    private let onSwipe: ((Item, SwipeDirection) -> Void)?
    private let onUndo: ((Item) -> Void)?
    private let content: (Item, Bool) -> Content
    @ViewBuilder private var detailOverlay: (Item) -> DetailOverlay
    @ViewBuilder let swipeOverlay: (SwipeDirection) -> SwipeOverlay
    
    @State private var dragOffset: CGSize = .zero
    @GestureState private var dragGestureActive = false
    @State private var isDragging = false
    @State private var canTap = true
    @State private var dragTask: Task<Void, Never>?
    @State private var showOverlay = false
    @State private var lastSwipeDirection: SwipeDirection = .right
    
    /// Creates a new swipable deck view.
    /// - Parameters:
    ///   - directions: A set of `SwipeDirection` indicating which directions a user is allowed to swipe.
    ///   - viewModel: The `DeckViewModel` that manages the data and state of the deck.
    ///   - onSwipe: An optional closure executed when an item is successfully swiped.
    ///   - onUndo: An optional closure executed when a swiped item is undone.
    ///   - content: A closure that returns the view for an individual item. The boolean indicates if the item is currently on top.
    ///   - detailOverlay: A closure that returns a view to overlay on the card when tapped or focused.
    ///   - swipeOverlay: A closure that returns a view representing the action of the current swipe direction (e.g., a "LIKE" stamp).
    public init(
        _ directions: Set<SwipeDirection>,
        viewModel: DeckViewModel<Item>,
        onSwipe: ((Item, SwipeDirection) -> Void)? = nil,
        onUndo: ((Item) -> Void)? = nil,
        content: @escaping (Item, Bool) -> Content,
        @ViewBuilder detailOverlay: @escaping (Item) -> DetailOverlay,
        @ViewBuilder swipeOverlay: @escaping (SwipeDirection) -> SwipeOverlay
    ) {
        self.allowedDirections = directions
        self.viewModel = viewModel
        self.viewModel.onSwipe = onSwipe
        self.viewModel.onUndo = onUndo
        self.onSwipe = onSwipe
        self.onUndo = onUndo
        self.content = content
        self.detailOverlay = detailOverlay
        self.swipeOverlay = swipeOverlay
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(viewModel.shownItems, id: \.item.id) { (item, index) in
                    let isOnTop = index == viewModel.internalIndex
                    let currentlySwipingItem = viewModel.currentlySwipingItems.first(where: { $0.index == index })
                    
                    let offsetX: CGFloat = currentlySwipingItem != nil ? currentlySwipingItem!.currentTranslation.width : (isOnTop ? dragOffset.width : 0)
                    let offsetY: CGFloat = currentlySwipingItem != nil ? currentlySwipingItem!.currentTranslation.height : (isOnTop ? dragOffset.height : 0)
                    
                    let horizontalDirection: SwipeDirection = offsetX > 0 ? .right : .left
                    let verticalDirection: SwipeDirection = offsetY > 0 ? .down : .up
                    
                    let isXAxisDominant = abs(offsetX) > abs(offsetY)
                    let primaryDirection = isXAxisDominant ? horizontalDirection : verticalDirection
                    let secondaryDirection = isXAxisDominant ? verticalDirection : horizontalDirection
                    
                    let dynamicDirection: SwipeDirection = allowedDirections.contains(primaryDirection) ? primaryDirection : secondaryDirection
                    let isActivelySwiping = isDragging || currentlySwipingItem != nil
                    let currentSwipeDirection: SwipeDirection = isActivelySwiping ? dynamicDirection : lastSwipeDirection
                    
                    let activeDrag = (currentSwipeDirection == .left || currentSwipeDirection == .right) ? abs(offsetX) : abs(offsetY)
                    let maxDragForOpacity = geometry.size.width * viewModel.config.dragThreshold
                    let clampedOpacityDrag = min(activeDrag, maxDragForOpacity)
                    let swipeOverlayOpacity: Double = allowedDirections.contains(currentSwipeDirection) && isActivelySwiping ? Double(clampedOpacityDrag / maxDragForOpacity) : 0.0
                    
                    let maxDragForRotation = geometry.size.width / 2
                    let isIncoming = currentlySwipingItem?.state == .incoming
                    let isLeaving = currentlySwipingItem?.state == .leaving
                    let clampedOffsetWidth = (isIncoming || isLeaving) ? offsetX : min(max(offsetX, -maxDragForRotation), maxDragForRotation)
                    let rotationMultiplier = isIncoming ? 1.12 : 1.0
                    let rotationDegrees = Double(clampedOffsetWidth / maxDragForRotation) * viewModel.config.maxRotation * rotationMultiplier
                    
                    ZStack {
                        content(item, isOnTop)
                            .zIndex(0)
                        
                        detailOverlay(item)
                            .opacity(showOverlay && (isOnTop || currentlySwipingItem != nil) ? 1 : 0)
                            .zIndex(1)
                        
                        swipeOverlay(currentSwipeDirection)
                            .opacity(swipeOverlayOpacity)
                            .zIndex(2)
                    }
                    .visualEffect { content, geometry in
                        content
                            .rotationEffect(.degrees(rotationDegrees))
                            .offset(x: offsetX, y: offsetY)
                    }
                    .zIndex(-Double(index))
                    .highPriorityGesture(
                        DragGesture()
                            .updating($dragGestureActive) { value, state, transaction in
                                state = true
                            }
                            .onChanged({ gesture in
                                dragGestureChanged(gesture, isOnTop: isOnTop)
                            })
                            .onEnded({ gesture in
                                dragGestureEnded(
                                    gesture,
                                    geometry: geometry,
                                    index: index,
                                    isOnTop: isOnTop
                                )
                            })
                    )
                    .gesture(
                        TapGesture()
                            .onEnded({
                                handleTap()
                            }),
                        including: isDragging ? .subviews : .gesture
                    )
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onChange(of: geometry.size) { _, newValue in
                viewModel.viewSize = newValue
            }
            .onChange(of: dragGestureActive) { _, isActive in
                if !isActive && isDragging {
                    dragGestureCancelled()
                }
            }
        }
    }
}

// MARK: Private functions
extension Deck {
    private func handleTap() {
        guard canTap, !isDragging else { return }
        
        canTap = false
        
        viewModel.handleTap()
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 130_000_000)
            if !Task.isCancelled {
                canTap = true
            }
        }
    }
    
    private func dragGestureChanged(_ gesture: DragGesture.Value, isOnTop: Bool) {
        guard isOnTop else { return }
        isDragging = true
        
        let isHorizontal = abs(gesture.translation.width) > abs(gesture.translation.height)
        lastSwipeDirection = isHorizontal
        ? (gesture.translation.width > 0 ? .right : .left)
        : (gesture.translation.height > 0 ? .down : .up)
        
        if dragTask == nil {
            dragTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                if !Task.isCancelled {
                    await MainActor.run {
                        withAnimation {
                            showOverlay = true
                        }
                    }
                }
            }
        }
        
        dragOffset = gesture.translation
    }
    
    private func dragGestureEnded(_ gesture: _ChangedGesture<DragGesture>.Value, geometry: GeometryProxy, index: Int, isOnTop: Bool) {
        withAnimation {
            showOverlay = false
        }
        canTap = true
        dragTask?.cancel()
        dragTask = nil
        
        guard isOnTop else {
            isDragging = false
            return
        }
        
        if abs(gesture.predictedEndTranslation.width) >= geometry.size.width * viewModel.config.dragThreshold || abs(gesture.predictedEndTranslation.height) >= geometry.size.width * viewModel.config.dragThreshold {
            let dx = gesture.predictedEndTranslation.width
            let dy = gesture.predictedEndTranslation.height
            
            let vectorLength = max(sqrt(dx * dx + dy * dy), 1)
            
            let offScreenDistance = max(geometry.size.width, geometry.size.height) * 1.5
            let finalPoint = CGPoint(
                x: (dx / vectorLength) * offScreenDistance,
                y: (dy / vectorLength) * offScreenDistance
            )
            
            let isHorizontal = abs(gesture.translation.width) > abs(gesture.translation.height)
            let direction: SwipeDirection = isHorizontal
            ? (gesture.translation.width > 0 ? .right : .left)
            : (gesture.translation.height > 0 ? .down : .up)
            
            guard allowedDirections.contains(direction) else {
                withAnimation(viewModel.config.animation) {
                    isDragging = false
                    dragOffset = .zero
                }
                return
            }
            
            isDragging = false
            viewModel.handleSwipeEnd(for: direction, at: index, from: gesture.translation, to: finalPoint)
            
            dragOffset = .zero
        } else {
            withAnimation(viewModel.config.animation) {
                isDragging = false
                dragOffset = .zero
            }
        }
    }
    
    private func dragGestureCancelled() {
        canTap = true
        dragTask?.cancel()
        dragTask = nil
        withAnimation(viewModel.config.animation) {
            isDragging = false
            showOverlay = false
            dragOffset = .zero
        }
    }
}
