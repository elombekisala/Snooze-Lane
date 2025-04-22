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
    // case home = "house" - Removed for MVP
    // case favorites = "star.square.on.square" - Commented out for MVP
    // case ai = "sparkles" - Removed for MVP
    case settings = "gear"

    var title: String {
        switch self {
        case .search:
            return "Search"
        // case .home: - Removed for MVP
        //     return "Home"
        // case .favorites: - Commented out for MVP
        //     return "Favorites"
        // case .ai: - Removed for MVP
        //     return "AI Assistant"
        case .settings:
            return "Settings"
        }
    }
}
