//
//  Deck.swift
//  Deck
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
/// Deck([.left, .right], viewModel: viewModel) { item, isOnTop, isMoving in
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
    private let content: (Item, Bool, Bool) -> Content
    @ViewBuilder private var detailOverlay: (Item) -> DetailOverlay
    @ViewBuilder let swipeOverlay: (SwipeDirection) -> SwipeOverlay
    
    @State private var dragOffset: CGSize = .zero
    @GestureState private var dragGestureActive = false
    @State private var isDragging = false
    @State private var dragTask: Task<Void, Never>?
    @State private var showOverlay = false
    @State private var lastSwipeDirection: SwipeDirection = .right
    
    /// Creates a new swipable deck view.
    /// - Parameters:
    ///   - directions: A set of `SwipeDirection` indicating which directions a user is allowed to swipe.
    ///   - viewModel: The `DeckViewModel` that manages the data and state of the deck.
    ///   - onSwipe: An optional closure executed when an item is successfully swiped.
    ///   - onUndo: An optional closure executed when a swiped item is undone.
    ///   - content: A closure that returns the view for an individual item. The boolean indicates if the item is currently on top, and if it is moving.
    ///   - detailOverlay: A closure that returns a view to overlay on the card when tapped or focused.
    ///   - swipeOverlay: A closure that returns a view representing the action of the current swipe direction (e.g., a "LIKE" stamp).
    public init(
        _ directions: Set<SwipeDirection>,
        viewModel: DeckViewModel<Item>,
        onSwipe: ((Item, SwipeDirection) -> Void)? = nil,
        onUndo: ((Item) -> Void)? = nil,
        content: @escaping (Item, Bool, Bool) -> Content,
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
                    let depth = index - (viewModel.internalIndex ?? -1)
                    let currentlySwipingItem = viewModel.currentlySwipingItems.first(where: { $0.index == index })
                    let isIncoming = currentlySwipingItem?.state == .incoming
                    let isLeaving = currentlySwipingItem?.state == .leaving
                    
                    let offsetX: CGFloat = currentlySwipingItem != nil ? currentlySwipingItem!.currentTranslation.width : (isOnTop ? dragOffset.width : 0)
                    let offsetY: CGFloat = currentlySwipingItem != nil ? currentlySwipingItem!.currentTranslation.height : (isOnTop ? dragOffset.height * 0.4 : 0) // Dampened Y-axis
                    let isActivelySwiping = isDragging || currentlySwipingItem != nil
                    
                    let currentSwipeDirection: SwipeDirection = {
                        if !isActivelySwiping { return lastSwipeDirection }
                        let horizontalDirection: SwipeDirection = offsetX > 0 ? .right : .left
                        // Logic simplified to only care about horizontal
                        return horizontalDirection
                    }()
                    
                    let swipeOverlayOpacity: Double = {
                        guard (isOnTop || isLeaving) && allowedDirections.contains(currentSwipeDirection) && isActivelySwiping else { return 0 }
                        let activeDragForOpacity = (currentSwipeDirection == .left || currentSwipeDirection == .right) ? abs(offsetX) : abs(offsetY)
                        let maxDragForOpacity = geometry.size.width * viewModel.config.dragThreshold
                        let clampedOpacityDrag = min(activeDragForOpacity, maxDragForOpacity)
                        return Double(clampedOpacityDrag / maxDragForOpacity)
                    }()
                    
                    let rotationDegrees: Double = {
                        guard isOnTop || isIncoming || isLeaving else { return 0 }
                        let maxDragForRotation = geometry.size.width / 2
                        let clampedOffsetWidth = min(max(offsetX, -maxDragForRotation), maxDragForRotation)
                        let isProg = currentlySwipingItem?.isProgrammatic == true
                        let maxRot = isProg ? viewModel.config.programmaticMaxRotation : viewModel.config.maxRotation
                        return Double(clampedOffsetWidth / maxDragForRotation) * maxRot
                    }()
                    
                    let cardScale: Double = {
                        if isLeaving {
                            return 1.0
                        }
                        return depth == 0 ? 1.0 : 0.9
                    }()
                    
                    let cardOpacity: Double = {
                        if isLeaving {
                            return 0
                        }
                        if isIncoming {
                            return 1
                        }
                        return depth == 0 ? 1 : 0
                    }()
                    
                    ZStack {
                        content(item, isOnTop, currentlySwipingItem != nil)
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
                    .opacity(cardOpacity)
                    .animation(currentlySwipingItem?.isProgrammatic == true ? viewModel.config.programmaticSwipeAnimation : viewModel.config.swipeOutAnimation, value: cardOpacity)
                    .scaleEffect(cardScale)
                    .transition(isIncoming ? .identity : .asymmetric(
                        insertion: AnyTransition.opacity.combined(with: .scale(scale: 0.9)).animation(.linear(duration: viewModel.config.fadeInDuration)),
                        removal: .opacity
                    ))
                    .zIndex(-Double(index))
                    .gesture(
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
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .contentShape(Rectangle())
            .gesture(
                TapGesture()
                    .onEnded({
                        handleTap()
                    }),
                including: isDragging ? .subviews : .all
            )
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
        guard !isDragging else { return }
        viewModel.handleTap()
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
        dragTask?.cancel()
        dragTask = nil
        
        guard isOnTop else {
            isDragging = false
            return
        }
        
        if abs(gesture.predictedEndTranslation.width) >= geometry.size.width * viewModel.config.dragThreshold || abs(gesture.predictedEndTranslation.height) >= geometry.size.width * viewModel.config.dragThreshold {
            
            let offScreenDistance = max(geometry.size.width, geometry.size.height) * 1.5
            
            let isHorizontal = abs(gesture.translation.width) > abs(gesture.translation.height)
            let direction: SwipeDirection = isHorizontal
            ? (gesture.translation.width > 0 ? .right : .left)
            : (gesture.translation.height > 0 ? .down : .up)
            
            guard allowedDirections.contains(direction) else {
                withAnimation(viewModel.config.snapBackAnimation) {
                    isDragging = false
                    dragOffset = .zero
                }
                return
            }
            
            let currentTime = CFAbsoluteTimeGetCurrent()
            guard currentTime - viewModel.lastSwipeTime >= viewModel.config.swipeDelay else {
                withAnimation(viewModel.config.snapBackAnimation) {
                    isDragging = false
                    dragOffset = .zero
                }
                return
            }
            
            viewModel.lastSwipeTime = currentTime
            
            let finalPoint = CGPoint(
                x: isHorizontal ? (direction == .right ? offScreenDistance : -offScreenDistance) : 0,
                y: !isHorizontal ? (direction == .down ? offScreenDistance : -offScreenDistance) : offScreenDistance * 0.15
            )
            
            let currentTranslation = gesture.translation
            
            isDragging = false
            
            viewModel.handleSwipeEnd(for: direction, at: index, from: currentTranslation, to: finalPoint, isProgrammatic: false)
            
            DispatchQueue.main.async {
                self.dragOffset = .zero
            }
            
        } else {
            withAnimation(viewModel.config.snapBackAnimation) {
                isDragging = false
                dragOffset = .zero
            }
        }
    }
    
    private func dragGestureCancelled() {
        dragTask?.cancel()
        dragTask = nil
        withAnimation(viewModel.config.snapBackAnimation) {
            isDragging = false
            showOverlay = false
            dragOffset = .zero
        }
    }
}
