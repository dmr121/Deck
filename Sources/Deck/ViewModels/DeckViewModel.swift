//
//  DeckViewModel.swift
//  Deck
//
//  Created by David Rozmajzl on 2/3/26.
//

import SwiftUI
import CoreFoundation

/// The view model responsible for managing the state, indices, and swipe logic of the `Deck`.
///
/// `DeckViewModel` keeps track of which items have been swiped, the current top item, and coordinates
/// the animations for cards entering and leaving the screen.
///
/// Example:
/// ```swift
/// let items = [Profile(name: "Alice"), Profile(name: "Bob")]
/// let viewModel = DeckViewModel(items: items)
/// ```
@MainActor @Observable public class DeckViewModel<Item>
where Item: Identifiable & Equatable {
    private(set) var items: [Item]
    @ObservationIgnored let config: DeckConfig
    
    public var currentIndex: Int = 0
    private(set) var shownItems = [(item: Item, index: Int)]()
    
    // MARK: Internal
    internal var internalIndex: Int? = 0 {
        didSet {
            currentIndex = internalIndex ?? (items.count - 1)
        }
    }
    internal var currentlySwipingItems = [(
        index: Int,
        direction: SwipeDirection,
        state: SwipeState,
        currentTranslation: CGSize,
        predictedEnd: CGPoint,
        isProgrammatic: Bool,
        task: Task<Void, Never>?
    )]()
    @ObservationIgnored internal var swipedItems = [(item: Item, direction: SwipeDirection)]()
    @ObservationIgnored internal var viewSize: CGSize?
    @ObservationIgnored internal var onSwipe: ((Item, SwipeDirection) -> Void)?
    @ObservationIgnored internal var onUndo: ((Item) -> Void)?
    
    @ObservationIgnored internal var lastSwipeTime: CFAbsoluteTime = 0
    @ObservationIgnored internal var lastUndoTime: CFAbsoluteTime = 0
    
    /// Creates a new view model to manage a `Deck`.
    /// - Parameters:
    ///   - items: The array of identifiable items to display in the deck.
    ///   - startIndex: The index of the card that should start out on the top of the deck
    ///   - config: The configuration defining the physical behavior of the deck. Defaults to standard values.
    public init(items: [Item], startIndex: Int = 0, config: DeckConfig = DeckConfig()) {
        self.items = items
        self.internalIndex = startIndex
        self.currentIndex = startIndex
        self.config = config
        
        calculateShownItems()
    }
}

// MARK: Public functions
extension DeckViewModel {
    /// Programmatically swipes the current top card in the specified direction.
    ///
    /// Useful for tying swipe actions to external buttons.
    ///
    /// Example:
    /// ```swift
    /// Button("Swipe Left") {
    ///     viewModel.swipe(.left)
    /// }
    /// ```
    /// - Parameter direction: The `SwipeDirection` to animate the card towards.
    public func swipe(_ direction: SwipeDirection) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        guard currentTime - lastSwipeTime >= config.swipeDelay else { return }
        lastSwipeTime = currentTime
        
        guard let internalIndex else { return }
        guard internalIndex < items.count else { return }
        
        let viewWidth = viewSize?.width ?? 1000
        let viewHeight = viewSize?.height ?? 1000
        
        let offScreenDistance = max(viewWidth, viewHeight) * 1.15
        
        let x: CGFloat = direction == .right ? offScreenDistance : direction == .left ? -offScreenDistance : 0
        let y: CGFloat = direction == .down ? offScreenDistance : direction == .up ? -offScreenDistance : offScreenDistance * 0.15
        
        let finalPoint = CGPoint(x: x, y: y)
        
        handleSwipeEnd(for: direction, at: internalIndex, from: .zero, to: finalPoint, isProgrammatic: true)
    }
    
    /// Programmatically undoes the last swiped card.
    ///
    /// Useful for tying swipe actions to external buttons.
    ///
    /// Example:
    /// ```swift
    /// Button("Undo") {
    ///     viewModel.undo()
    /// }
    /// ```
    public func undo() {
        handleTap()
    }
}

// MARK: Internal functions
extension DeckViewModel {
    internal func handleSwipeEnd(for direction: SwipeDirection, at index: Int, from translation: CGSize, to endPoint: CGPoint, isProgrammatic: Bool = false) {
        onSwipe?(items[index], direction)
        swipedItems.append((item: items[index], direction))
        
        let animation = isProgrammatic ? config.programmaticSwipeAnimation : config.swipeOutAnimation
        let duration: Double = config.swipeDuration
        
        let cleanupTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard let self = self, !Task.isCancelled else { return }
            
            if let idx = self.currentlySwipingItems.firstIndex(where: { $0.index == index }) {
                if self.currentlySwipingItems[idx].state == .leaving {
                    withAnimation(animation) {
                        self.currentlySwipingItems.remove(at: idx)
                        self.calculateShownItems()
                    }
                }
            }
        }
        
        if let existingIndex = currentlySwipingItems.firstIndex(where: { $0.index == index }) {
            currentlySwipingItems[existingIndex].task?.cancel()
            currentlySwipingItems[existingIndex].direction = direction
            currentlySwipingItems[existingIndex].state = .leaving
            currentlySwipingItems[existingIndex].predictedEnd = endPoint
            currentlySwipingItems[existingIndex].isProgrammatic = isProgrammatic
            currentlySwipingItems[existingIndex].currentTranslation = translation
            currentlySwipingItems[existingIndex].task = cleanupTask
        } else {
            currentlySwipingItems.append((index: index, direction: direction, state: .leaving, currentTranslation: translation, predictedEnd: endPoint, isProgrammatic: isProgrammatic, task: cleanupTask))
        }
        
        withAnimation(animation) {
            self.internalIndex = (index == self.items.count - 1) ? nil: min(index + 1, self.items.count - 1)
            self.calculateShownItems()
            if let idx = self.currentlySwipingItems.firstIndex(where: { $0.index == index }) {
                self.currentlySwipingItems[idx].currentTranslation = .init(width: endPoint.x, height: endPoint.y)
            }
        }
    }
    
    internal func handleTap() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        guard currentTime - lastUndoTime >= config.undoDelay else { return }
        lastUndoTime = currentTime
        
        guard let swipedItem = swipedItems.popLast() else { return }
        onUndo?(swipedItem.item)
        
        let animation = config.undoAnimation
        let duration: Double = config.undoDuration
        
        let incomingIndex = max((internalIndex ?? items.count) - 1, 0)
        
        let cleanupTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard let self = self, !Task.isCancelled else { return }
            
            if let idx = self.currentlySwipingItems.firstIndex(where: { $0.index == incomingIndex }) {
                if self.currentlySwipingItems[idx].state == .incoming {
                    withAnimation(animation) {
                        self.currentlySwipingItems.remove(at: idx)
                        self.calculateShownItems()
                    }
                }
            }
        }
        
        if let existingIndex = currentlySwipingItems.firstIndex(where: { $0.index == incomingIndex }) {
            currentlySwipingItems[existingIndex].task?.cancel()
            currentlySwipingItems[existingIndex].state = .incoming
            currentlySwipingItems[existingIndex].task = cleanupTask
            currentlySwipingItems[existingIndex].isProgrammatic = true
            
            withAnimation(animation) {
                internalIndex = incomingIndex
                calculateShownItems()
                currentlySwipingItems[existingIndex].currentTranslation = .zero
            }
            
        } else {
            let viewWidth = viewSize?.width ?? 1000
            let viewHeight = viewSize?.height ?? 1000
            
            let offScreenDistance = max(viewWidth, viewHeight) * 1.15
            
            let x: CGFloat = swipedItem.direction == .right ? offScreenDistance : swipedItem.direction == .left ? -offScreenDistance : 0
            let y: CGFloat = swipedItem.direction == .down ? offScreenDistance : swipedItem.direction == .up ? -offScreenDistance : offScreenDistance * 0.15
            
            currentlySwipingItems.append((
                index: incomingIndex,
                direction: swipedItem.direction,
                state: .incoming,
                currentTranslation: .init(width: x, height: y),
                predictedEnd: .zero,
                isProgrammatic: true,
                task: cleanupTask
            ))
            
            // Render the card exactly off-screen instantly
            calculateShownItems()
            
            // Yield the thread to ensure SwiftUI applies the initial layout state,
            // then simultaneously update internalIndex and animate the offset to trigger the slide
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 20_000_000)
                guard let self = self else { return }
                
                withAnimation(animation) {
                    self.internalIndex = incomingIndex
                    self.calculateShownItems()
                    if let idx = self.currentlySwipingItems.firstIndex(where: { $0.index == incomingIndex }) {
                        self.currentlySwipingItems[idx].currentTranslation = .zero
                    }
                }
            }
        }
    }
    
    internal func calculateShownItems() {
        guard !items.isEmpty else {
            shownItems = []
            return
        }
        
        var visibleIndices = Set<Int>()
        
        if let internalIndex {
            if internalIndex < items.count {
                visibleIndices.insert(internalIndex)
            }
        }
        
        for swipingItem in currentlySwipingItems {
            visibleIndices.insert(swipingItem.index)
            
            if swipingItem.state == .incoming {
                visibleIndices.insert(swipingItem.index + 1)
            }
        }
        
        let sortedIndices = visibleIndices
            .filter { $0 >= 0 && $0 < items.count }
            .sorted()
        
        shownItems = sortedIndices.prefix(4).map { (item: items[$0], index: $0) }
    }
}
