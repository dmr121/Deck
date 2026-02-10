"

# Deck

A highly customizable, high-performance card swiping library for SwiftUI. Designed for modern apps that require 60fps animations, complex interactions, and perfect clipping of overlays.

## Features

* 🚀 **High Performance:** Optimized with internal `drawingGroup` logic and smart state management to maintain 60fps even with complex card hierarchies.
* 📦 **Inversion of Control:** Unique architecture where Swipe Overlays (Like/Nope) and Detail Views are injected directly into your card content stack. This allows for perfect clipping (e.g., rounded corners affecting both the card and the overlay).
* ↩️ **Undo Support:** Built-in history tracking with programmable undo functionality.
* 🔍 **Detail View:** Seamless long-press gesture to reveal detailed information without extra state management.
* 🛠 **Fully Customizable:** Global configuration for swipe thresholds, rotation physics, animation timing, and allowed directions.

## Installation

### Swift Package Manager

1. In Xcode, open your project and navigate to **File > Add Packages...**
2. Enter the repository URL: `https://github.com/your-username/Deck.git`
3. Select **Up to Next Major Version** and click **Add Package**.

---

## Usage Guide

### 1. Define your Data Model

Your data must conform to `Identifiable` and `Equatable`.

```swift
struct Profile: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
}

```

### 2. Initialize the ViewModel

The `DeckViewModel` manages the stack state, swipes, and undo history.

```swift
@State private var viewModel = DeckViewModel<Profile>()

```

### 3. Render the Deck

The `Deck` view uses a declarative modifier syntax.

**Important:** The `.content` closure receives two arguments: the `item` and the `overlays`. You **must** place `overlays` inside your card's ZStack. This ensures swipe indicators (Like/Nope) and the Detail view are clipped correctly by your card's shape.

```swift
Deck(items: profiles, manager: viewModel)
    .content { profile, overlays in
        // Build your Card
        ZStack(alignment: .bottomLeading) {
            
            // 1. Background Layer
            RoundedRectangle(cornerRadius: 20)
                .fill(profile.color.gradient)
                .shadow(radius: 5)
            
            // 2. Content Layer
            VStack {
                Text(profile.name)
                    .font(.title.bold())
                    .foregroundColor(.white)
            }
            .padding()
            
            // 3. SYSTEM OVERLAYS (Required)
            // Injecting this here ensures the \"Like/Nope\" labels 
            // are clipped by the .clipShape below.
            overlays
        }
        .frame(width: 300, height: 450)
        
        // 4. Clip everything (Content + Overlays)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        
        // 5. Performance Optimization
        .drawingGroup() 
    }
    .overlay { direction in
        // Define how your swipe overlays look
        if direction == .right {
            Text("LIKE").font(.largeTitle).foregroundColor(.green)
                .background(.black.opacity(0.5)).cornerRadius(10)
        } else {
            Text("NOPE").font(.largeTitle).foregroundColor(.red)
                .background(.black.opacity(0.5)).cornerRadius(10)
        }
    }
    .detail { profile in
        // Define the view that appears on Long Press
        Color.black.overlay(Text("Detail View for \(profile.name)").foregroundColor(.white))
    }
    .swipeDirections([.left, .right]) // Limit allowed swipes

```

### 4. Programmatic Control

Trigger actions from buttons outside the deck using the `viewModel`.

```swift
HStack {
    Button("Undo") { viewModel.undo() }
    Button("Swipe Left") { viewModel.swipe(.left) }
    Button("Swipe Right") { viewModel.swipe(.right) }
}

```

---

## Configuration

You can adjust the physics and global behavior using `DeckConfiguration` in your App's `init()` or `onAppear`.

| Property | Default | Description |
| --- | --- | --- |
| `visibleCount` | `3` | Number of cards rendered in the stack for performance. |
| `swipeThreshold` | `150.0` | Distance required to trigger a swipe. |
| `maxRotationAngle` | `.degrees(15)` | Max tilt when dragging. |
| `flightAnimation` | `spring(...)` | Animation for card exiting screen. |
| `allowedDirections` | `all` | Global default for allowed swipes. |

---
