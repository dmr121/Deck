//
//  ContentView.swift
//  tinder test
//
//  Created by David Rozmajzl on 1/29/26.
//

import SwiftUI

let colors: [Color] = [.red, .blue, .yellow, .green]

fileprivate struct Profile: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
}

struct ContentView: View {
    @State private var deckViewModel = DeckViewModel(items: (1...50).map { i in
        let colors: [Color] = [.red, .blue, .yellow, .green]
        return Profile(
            name: "Person \(i)",
            color: colors[(i - 1) % 4]
        )
    }, config: .init(dragThreshold: 0.30, maxRotation: 20))
    
    var body: some View {
        VStack {
            Deck([.left, .right, .down],
                 viewModel: deckViewModel,
                 onSwipe: { profile, direction in
                print("swiped \(profile.id) \(direction)")
            },
                 onUndo: { profile in
                print("undo \(profile.id)")
            }
            ) { profile, isTopCard in
                VStack {
                    AsyncImage(url: URL(string: "https://picsum.photos/seed/\(profile.id)/200/300")!) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        profile.color
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .frame(height: 460)
                .clipShape(RoundedRectangle(cornerRadius: 30))
            } detailOverlay: { profile in
                ZStack {
                    VStack {
                        Spacer()
                        
                        Text("Profile id: \(profile.name)")
                            .font(.title)
                    }
                    .padding(32)
                    .zIndex(1)
                    
                    Color.black.opacity(0.65)
                        .zIndex(0)
                }
                .clipShape(RoundedRectangle(cornerRadius: 30))
            } swipeOverlay: { direction in
                switch direction {
                case .left:
                    Text("LEFT")
                        .font(.title)
                        .padding()
                        .background(.red)
                case .right:
                    Text("RIGHT")
                        .font(.title)
                        .padding()
                        .background(.green)
                case .up:
                    Text("UP")
                        .font(.title)
                        .padding()
                        .background(.blue)
                case .down:
                    Text("DOWN")
                        .font(.title)
                        .padding()
                        .background(.yellow)
                }
            }
            .padding()
            
            HStack {
                Spacer()
                
                Button("LEFT") {
                    deckViewModel.swipe(.left)
                }
                
                Spacer()
                
                Button("UNDO") {
                    deckViewModel.undo()
                }
                
                Spacer()
                
                Button("RIGHT") {
                    deckViewModel.swipe(.right)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
