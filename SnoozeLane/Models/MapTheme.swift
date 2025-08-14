import SwiftUI
import MapKit

enum MapTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case custom = "Custom"
    
    var displayName: String {
        return self.rawValue
    }
    
    var mapType: MKMapType {
        switch self {
        case .light, .custom:
            return .standard
        case .dark:
            return .hybrid
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .light:
            return Color(.systemBackground)
        case .dark:
            return Color(red: 0.12, green: 0.15, blue: 0.18) // Dark blue-gray
        case .custom:
            return Color.orange.opacity(0.1)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .light:
            return Color.blue
        case .dark:
            return Color.cyan
        case .custom:
            return Color.orange
        }
    }
    
    var textColor: Color {
        switch self {
        case .light:
            return Color(.label)
        case .dark:
            return Color.white
        case .custom:
            return Color.orange
        }
    }
    
    var searchBarBackground: Color {
        switch self {
        case .light:
            return Color(.systemGray6)
        case .dark:
            return Color(red: 0.18, green: 0.21, blue: 0.24) // Slightly lighter dark blue-gray
        case .custom:
            return Color.orange.opacity(0.1)
        }
    }
    
    var searchBarBorder: Color {
        switch self {
        case .light:
            return Color(.systemGray4)
        case .dark:
            return Color(red: 0.25, green: 0.28, blue: 0.31) // Medium dark blue-gray
        case .custom:
            return Color.orange.opacity(0.3)
        }
    }
    
    var buttonBackground: Color {
        switch self {
        case .light:
            return Color(.systemBackground)
        case .dark:
            return Color(red: 0.18, green: 0.21, blue: 0.24) // Slightly lighter dark blue-gray
        case .custom:
            return Color.orange.opacity(0.15)
        }
    }
    
    var buttonBorder: Color {
        switch self {
        case .light:
            return Color(.systemGray4)
        case .dark:
            return Color(red: 0.25, green: 0.28, blue: 0.31) // Medium dark blue-gray
        case .custom:
            return Color.orange.opacity(0.4)
        }
    }
    
    var secondaryBackground: Color {
        switch self {
        case .light:
            return Color(.systemGray6)
        case .dark:
            return Color(red: 0.15, green: 0.18, blue: 0.21) // Dark blue-gray
        case .custom:
            return Color.orange.opacity(0.05)
        }
    }
}
