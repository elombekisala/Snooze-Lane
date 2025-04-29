//
//  View+Extensions.swift
//  SnoozeLane
//
//  Created by Elombe.Kisala on 9/9/24.
//

import MapKit
import SwiftUI

/// Custom View Modifiers
extension View {
    @ViewBuilder
    func hideNativeTabBar() -> some View {
        self
            .toolbar(.hidden, for: .tabBar)
    }
}

struct AlarmButtonModifier: ViewModifier {
    let isSet: Bool

    func body(content: Content) -> some View {
        content
            .background(isSet ? Color.green : Color("3"))
            .cornerRadius(10)
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
                            .frame(height: 0)  // Remove the extra height since we want it above tab bar
                    }
                })
    }
}

struct MapTypeSelector: View {
    @Binding var mapType: MKMapType

    var body: some View {
        VStack(spacing: 8) {
            Button(action: { mapType = .standard }) {
                Image(systemName: "map")
                    .font(.system(size: 18))
                    .foregroundColor(mapType == .standard ? .orange : .gray)
                    .padding(8)
                    .background(mapType == .standard ? Color.orange.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
            }

            Button(action: { mapType = .satellite }) {
                Image(systemName: "globe")
                    .font(.system(size: 18))
                    .foregroundColor(mapType == .satellite ? .orange : .gray)
                    .padding(8)
                    .background(mapType == .satellite ? Color.orange.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
            }

            Button(action: { mapType = .hybrid }) {
                Image(systemName: "map.fill")
                    .font(.system(size: 18))
                    .foregroundColor(mapType == .hybrid ? .orange : .gray)
                    .padding(8)
                    .background(mapType == .hybrid ? Color.orange.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
            }
        }
        .padding(8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color("4"), Color("5"), Color("5")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.95)
        )
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
