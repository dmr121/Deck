//
//  DeckSystemOverlay.swift
//  tinder test
//
//  Created by David Rozmajzl on 2/3/26.
//

import SwiftUI

/// A container view that packages the Detail and Swipe Overlays together.
///
/// This view is passed into the `content` closure of the Deck. You should place this view
/// inside your content's `ZStack` so that it is clipped and transformed along with the card background.
public struct DeckSystemOverlay<Overlay: View, Detail: View>: View {
    
    // MARK: - Properties
    
    let offset: CGSize
    let showDetail: Bool
    let allowedDirections: Set<SwipeDirection>
    let swipeThreshold: CGFloat
    
    @ViewBuilder let overlayBuilder: (SwipeDirection) -> Overlay
    @ViewBuilder let detailBuilder: () -> Detail
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // 1. Detail View (appears on long press)
            detailBuilder()
                .opacity(showDetail ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showDetail)
                .zIndex(0)
            
            // 2. Swipe Overlays (Like/Nope labels)
            ZStack {
                ForEach(SwipeDirection.allCases, id: \.self) { dir in
                    if allowedDirections.contains(dir) {
                        overlayBuilder(dir)
                            .opacity(opacity(for: dir))
                    }
                }
            }
            .zIndex(1)
        }
        .zIndex(999)
    }
    
    // MARK: - Helpers
    
    private func opacity(for direction: SwipeDirection) -> Double {
        let activeDir = SwipePhysics.activeDirection(for: offset)
        guard activeDir == direction else { return 0 }
        return min(Double(max(abs(offset.width), abs(offset.height)) / swipeThreshold), 1.0)
    }
}
