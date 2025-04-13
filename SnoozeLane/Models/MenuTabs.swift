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
    case favorites = "star.square.on.square"
    case ai = "waveform"
    case settings = "gear"
    
    var title: String {
        switch self {
        case .search:
            return "Search"
        case .favorites:
            return "Favorites"
        case .ai:
            return "AI Voice"
        case .settings:
            return "Settings"
        }
    }
}
