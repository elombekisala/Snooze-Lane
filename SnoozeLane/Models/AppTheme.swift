import SwiftUI

enum AppTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case custom = "Custom"
    
    var displayName: String {
        return self.rawValue
    }
    
    // MARK: - Primary Colors
    var primaryColor: Color {
        switch self {
        case .light:
            return Color("MainOrange") // Your custom orange
        case .dark:
            return Color("MainOrange") // Keep orange as primary
        case .custom:
            return Color("MainOrange") // Consistent orange branding
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .light:
            return Color("3") // Dark blue-gray from your palette
        case .dark:
            return Color("1") // Light gray from your palette
        case .custom:
            return Color("2") // Medium gray from your palette
        }
    }
    
    // MARK: - Background Colors
    var backgroundColor: Color {
        switch self {
        case .light:
            return Color("1") // Light gray (F5F5F5)
        case .dark:
            return Color("5") // Very dark (2A1310)
        case .custom:
            return Color("2") // Medium gray (CFD6DA)
        }
    }
    
    var secondaryBackground: Color {
        switch self {
        case .light:
            return .white
        case .dark:
            return Color("4") // Dark brown (231A1A)
        case .custom:
            return Color("1") // Light gray
        }
    }
    
    var tertiaryBackground: Color {
        switch self {
        case .light:
            return Color("2") // Medium gray
        case .dark:
            return Color("3") // Dark blue-gray
        case .custom:
            return Color("3") // Dark blue-gray
        }
    }
    
    // MARK: - Text Colors
    var primaryText: Color {
        switch self {
        case .light:
            return Color("5") // Very dark (2A1310)
        case .dark:
            return Color("1") // Light gray
        case .custom:
            return Color("5") // Very dark
        }
    }
    
    var secondaryText: Color {
        switch self {
        case .light:
            return Color("4") // Dark brown
        case .dark:
            return Color("2") // Medium gray
        case .custom:
            return Color("4") // Dark brown
        }
    }
    
    var accentText: Color {
        switch self {
        case .light:
            return Color("MainOrange")
        case .dark:
            return Color("MainOrange")
        case .custom:
            return Color("MainOrange")
        }
    }
    
    // MARK: - Interactive Elements
    var buttonBackground: Color {
        switch self {
        case .light:
            return Color("MainOrange")
        case .dark:
            return Color("MainOrange")
        case .custom:
            return Color("MainOrange")
        }
    }
    
    var buttonText: Color {
        return .white
    }
    
    var buttonSecondary: Color {
        switch self {
        case .light:
            return Color("2") // Medium gray
        case .dark:
            return Color("3") // Dark blue-gray
        case .custom:
            return Color("2") // Medium gray
        }
    }
    
    var buttonSecondaryText: Color {
        switch self {
        case .light:
            return Color("5") // Very dark
        case .dark:
            return Color("1") // Light gray
        case .custom:
            return Color("5") // Very dark
        }
    }
    
    // MARK: - Search and Input Fields
    var searchBarBackground: Color {
        switch self {
        case .light:
            return Color("2") // Medium gray
        case .dark:
            return Color("3") // Dark blue-gray
        case .custom:
            return Color("2") // Medium gray
        }
    }
    
    var searchBarBorder: Color {
        switch self {
        case .light:
            return Color("3") // Dark blue-gray
        case .dark:
            return Color("2") // Medium gray
        case .custom:
            return Color("3") // Dark blue-gray
        }
    }
    
    var searchBarText: Color {
        switch self {
        case .light:
            return Color("5") // Very dark
        case .dark:
            return Color("1") // Light gray
        case .custom:
            return Color("5") // Very dark
        }
    }
    
    // MARK: - Borders and Dividers
    var borderColor: Color {
        switch self {
        case .light:
            return Color("3") // Dark blue-gray
        case .dark:
            return Color("2") // Medium gray
        case .custom:
            return Color("3") // Dark blue-gray
        }
    }
    
    var dividerColor: Color {
        switch self {
        case .light:
            return Color("2") // Medium gray
        case .dark:
            return Color("4") // Dark brown
        case .custom:
            return Color("2") // Medium gray
        }
    }
    
    // MARK: - Shadows and Elevation
    var shadowColor: Color {
        switch self {
        case .light:
            return Color.black.opacity(0.1)
        case .dark:
            return Color.black.opacity(0.3)
        case .custom:
            return Color.black.opacity(0.15)
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .light:
            return 8
        case .dark:
            return 12
        case .custom:
            return 10
        }
    }
    
    // MARK: - Status and Feedback
    var successColor: Color {
        return Color.green
    }
    
    var warningColor: Color {
        return Color.orange
    }
    
    var errorColor: Color {
        return Color.red
    }
    
    var infoColor: Color {
        return Color.blue
    }
    
    // MARK: - Map Specific Colors
    var mapAccent: Color {
        return Color("MainOrange")
    }
    
    var mapBackground: Color {
        switch self {
        case .light:
            return Color("1") // Light gray
        case .dark:
            return Color("5") // Very dark
        case .custom:
            return Color("2") // Medium gray
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .light
    
    static let shared = ThemeManager()
    
    private init() {
        // Load saved theme preference
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
    }
}

// MARK: - View Extensions for Easy Theming
extension View {
    func themedBackground(_ theme: AppTheme) -> some View {
        self.background(theme.backgroundColor)
    }
    
    func themedText(_ theme: AppTheme) -> some View {
        self.foregroundColor(theme.primaryText)
    }
    
    func themedSecondaryText(_ theme: AppTheme) -> some View {
        self.foregroundColor(theme.secondaryText)
    }
    
    func themedAccentText(_ theme: AppTheme) -> some View {
        self.foregroundColor(theme.accentText)
    }
    
    func themedButton(_ theme: AppTheme) -> some View {
        self
            .background(theme.buttonBackground)
            .foregroundColor(theme.buttonText)
    }
    
    func themedSecondaryButton(_ theme: AppTheme) -> some View {
        self
            .background(theme.buttonSecondary)
            .foregroundColor(theme.buttonSecondaryText)
    }
    
    func themedSearchBar(_ theme: AppTheme) -> some View {
        self
            .background(theme.searchBarBackground)
            .foregroundColor(theme.searchBarText)
    }
    
    func themedBorder(_ theme: AppTheme) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.borderColor, lineWidth: 1)
        )
    }
    
    func themedShadow(_ theme: AppTheme) -> some View {
        self.shadow(
            color: theme.shadowColor,
            radius: theme.shadowRadius,
            x: 0,
            y: 2
        )
    }
}
