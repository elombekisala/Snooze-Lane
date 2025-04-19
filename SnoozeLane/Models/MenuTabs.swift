//
//  MenuTabs.swift
//  SnoozeLane
//
//  Created by Elombe.Kisala on 6/2/24.
//

import SwiftUI

/// Tabs
enum MenuTabs: String, CaseIterable {
    case search = "magnifyingglass"
    case home = "house"
    // case favorites = "star.square.on.square" - Commented out for MVP
    case ai = "sparkles"
    case settings = "gear"

    var title: String {
        switch self {
        case .search:
            return "Search"
        case .home:
            return "Home"
        // case .favorites: - Commented out for MVP
        //     return "Favorites"
        case .ai:
            return "AI Assistant"
        case .settings:
            return "Settings"
        }
    }
}
