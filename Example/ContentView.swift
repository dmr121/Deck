//
//  ContentView.swift
//  tinder test
//
//  Created by David Rozmajzl on 1/29/26.
//

import SwiftUI

let colors: [Color] = [.red, .blue, .yellow, .green]

struct ContentView: View {
    @State private var profiles = (1...50).map { i in
        Profile(
            name: "Person \(i)",
            color: colors[(i - 1) % 4]
        )
    }
    
    var body: some View {
        DeckExampleView(profiles: profiles)
    }
}

#Preview {
    ContentView()
}
