import SwiftUI

struct EdgeSwipeModifier: ViewModifier {
    let edge: Edge
    let action: () -> Void

    enum Edge {
        case leading   // swipe from left edge →
        case trailing  // swipe from right edge ←
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: edge == .leading ? .leading : .trailing) {
                Color.clear
                    .frame(width: 28)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 25)
                            .onEnded { value in
                                let direction = edge == .leading
                                    ? value.translation.width > 40   // swipe right from left edge
                                    : value.translation.width < -40  // swipe left from right edge

                                if direction {
                                    action()
                                }
                            }
                    )
            }
    }
}

extension View {
    func onEdgeSwipe(_ edge: EdgeSwipeModifier.Edge, perform action: @escaping () -> Void) -> some View {
        modifier(EdgeSwipeModifier(edge: edge, action: action))
    }
}
