//
//  DraggableCardView.swift
//  tinder test
//
//  Created by David Rozmajzl on 2/3/26.
//

import SwiftUI

/// An internal view wrapper that handles the actual rendering and geometry of the card.
///
/// This view applies the:
/// * Rotation based on drag offset
/// * Drag Gesture recognition
///
/// - Note: `drawingGroup()` is NOT applied here to ensure video players or complex animations
/// within the card work correctly. It should be applied by the user in the `content` closure if needed.
internal struct DraggableCardView<Content: View>: View {
    let isTopCard: Bool
    let offset: CGSize
    let content: () -> Content
    
    var onDragChanged: (CGSize) -> Void
    var onDragEnded: (CGSize) -> Void
    
    var body: some View {
        // We render content directly. The user is responsible for placing the overlays via the closure.
        content()
            // We just apply the physics/interaction modifiers.
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / DeckConfiguration.rotationFactor)))
            .allowsHitTesting(isTopCard)
            .gesture(
                isTopCard ?
                DragGesture()
                    .onChanged { onDragChanged($0.translation) }
                    .onEnded { onDragEnded($0.translation) }
                : nil
            )
    }
}
