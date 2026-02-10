//
//  DeckExampleView.swift
//  tinder test
//
//  Created by David Rozmajzl on 2/3/26.
//

import SwiftUI

/// A sample model used for demonstrating the Deck.
struct Profile: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
}

/// An example view demonstrating how to integrate the `Deck` component.
struct DeckExampleView: View {
    
    // MARK: - Properties
    
    let profiles: [Profile]
    
    @State private var viewModel = DeckViewModel<Profile>()
    
    init(profiles: [Profile]) {
        self.profiles = profiles
    }
    
    // MARK: - Subviews
    
    struct CustomOverlayView: View {
        let direction: SwipeDirection
        
        var body: some View {
            ZStack {
                let text = direction == .right ? "LIKE" : (direction == .left ? "NOPE" : "SUPER")
                let color = direction == .right ? Color.green : (direction == .left ? Color.red : Color.blue)
                
                if !text.isEmpty {
                    Text(text)
                        .font(.largeTitle.bold())
                        .foregroundColor(color)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 3))
                        .rotationEffect(.degrees(direction == .right ? -10 : 10))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 40)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Deck Demo")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(height: 60)
            
            Spacer()
            
            Text("Index: \(viewModel.currentIndex)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom)
            
            // The Main Deck Component
            Deck(items: profiles, manager: viewModel)
                .content { profile, Overlays in // IMPORTANT: overlays injected here
                    
                    // CARD CONTENT + SYSTEM OVERLAYS
                    ZStack(alignment: .bottomLeading) {
                        
                        // 1. Background / Main Content
                        RoundedRectangle(cornerRadius: 24)
                            .fill(profile.color.gradient)
                            .stroke(.white, lineWidth: 2)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        
                        VStack(alignment: .leading) {
                            Text(profile.name)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Hold for details")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(24)
                        
                        // 2. Inject Overlays (Like/Nope/Detail)
                        // By placing it here, it will be clipped by the clipShape below
                        Overlays
                    }
                    .frame(width: 340, height: 480)
                    // CLIP EVERYTHING (Content + Overlays)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    // PERFORMANCE TIP: Apply drawingGroup here for complex vector content
                    .drawingGroup()
                }
                .overlay { direction in
                    CustomOverlayView(direction: direction)
                }
                .detail { profile in
                    ZStack {
                        Color.black.opacity(0.7)
                        VStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                                .padding()
                            Text("More Info for \(profile.name)")
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 340, height: 480)
                }
                .swipeDirections([.left, .right, .up])
                .onSwipe { item, direction in
                    print("Swiped \(item.name) towards \(direction)")
                    // Analytics or database updates go here
                }
                .onUndo {
                    print("Undo performed!")
                }
            
                .frame(maxWidth: .infinity, maxHeight: 600)
            
            Spacer()
            
            // Control Buttons
            HStack(spacing: 30) {
                controlButton(icon: "xmark", color: .red) { viewModel.swipe(.left) }
                controlButton(icon: "arrow.uturn.backward", color: .yellow) { viewModel.undo() }
                controlButton(icon: "heart.fill", color: .green) { viewModel.swipe(.right) }
            }
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.bold())
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(Circle().fill(.white).shadow(color: .black.opacity(0.1), radius: 5, y: 2))
        }
    }
}

#Preview {
    DeckExampleView(profiles: (1...50).map { i in
        let colors: [Color] = [.red, .blue, .yellow, .green]
        return Profile(
            name: "Person \(i)",
            color: colors[(i - 1) % 4]
        )
    })
}
