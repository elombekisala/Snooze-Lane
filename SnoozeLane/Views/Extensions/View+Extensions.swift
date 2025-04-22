//
//  View+Extensions.swift
//  SnoozeLane
//
//  Created by Elombe.Kisala on 9/9/24.
//

import SwiftUI

/// Custom View Modifiers
extension View {
    @ViewBuilder
    func hideNativeTabBar() -> some View {
        self
            .toolbar(.hidden, for: .tabBar)
    }
}

/// Custom TabView Modifier
extension TabView {
    @ViewBuilder
    func tabSheet<SheetContent: View>(
        initialHeight: CGFloat = 100, sheetCornerRadius: CGFloat = 15,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        self
            .modifier(
                BottomSheetModifier(
                    initialHeight: initialHeight, sheetCornerRadius: sheetCornerRadius,
                    sheetView: content()))
    }
}

/// Helper View Modifier
private struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    var initialHeight: CGFloat
    var sheetCornerRadius: CGFloat
    var sheetView: SheetContent
    /// View Properties
    @State private var showSheet: Bool = true
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: $showSheet,
                content: {
                    VStack(spacing: 0) {
                        sheetView
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color("4"), Color("5"), Color("5")]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .opacity(0.95)
                                .ignoresSafeArea()
                            )
                            .zIndex(0)
                    }
                    .presentationDetents([.height(initialHeight), .medium, .fraction(0.99)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(sheetCornerRadius)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationBackground(.clear)
                    .interactiveDismissDisabled()
                    .safeAreaInset(edge: .bottom) {
                        Rectangle()
                            .fill(.clear)
                            .frame(height: 65)  // Increased height to account for tab bar
                    }
                })
    }
}
