import Foundation
import MapKit

struct QuickDestination: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let icon: String
    let colorHex: String
    let category: QuickDestinationCategory
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    init(id: String = UUID().uuidString, 
         title: String, 
         subtitle: String, 
         latitude: Double, 
         longitude: Double, 
         icon: String, 
         colorHex: String, 
         category: QuickDestinationCategory) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
        self.icon = icon
        self.colorHex = colorHex
        self.category = category
    }
    
    // MARK: - Default Quick Destinations
    static let defaultDestinations: [QuickDestination] = [
        QuickDestination(
            title: "Home",
            subtitle: "123 Main St",
            latitude: 37.7749,
            longitude: -122.4194,
            icon: "house.fill",
            colorHex: "#007AFF",
            category: .home
        ),
        QuickDestination(
            title: "Work",
            subtitle: "456 Office Rd",
            latitude: 37.7849,
            longitude: -122.4094,
            icon: "briefcase.fill",
            colorHex: "#34C759",
            category: .work
        ),
        QuickDestination(
            title: "Gym",
            subtitle: "Fitness Center",
            latitude: 37.7649,
            longitude: -122.4294,
            icon: "dumbbell.fill",
            colorHex: "#AF52DE",
            category: .fitness
        ),
        QuickDestination(
            title: "Grocery Store",
            subtitle: "Supermarket",
            latitude: 37.7549,
            longitude: -122.4394,
            icon: "cart.fill",
            colorHex: "#FF9500",
            category: .shopping
        )
    ]
}

enum QuickDestinationCategory: String, CaseIterable, Codable {
    case home = "home"
    case work = "work"
    case fitness = "fitness"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case healthcare = "healthcare"
    case education = "education"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .home: return "Home"
        case .work: return "Work"
        case .fitness: return "Fitness"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .healthcare: return "Healthcare"
        case .education: return "Education"
        case .other: return "Other"
        }
    }
    
    var defaultIcon: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .fitness: return "dumbbell.fill"
        case .shopping: return "cart.fill"
        case .entertainment: return "gamecontroller.fill"
        case .healthcare: return "cross.fill"
        case .education: return "book.fill"
        case .other: return "mappin.circle.fill"
        }
    }
    
    var defaultColorHex: String {
        switch self {
        case .home: return "#007AFF"
        case .work: return "#34C759"
        case .fitness: return "#AF52DE"
        case .shopping: return "#FF9500"
        case .entertainment: return "#FF3B30"
        case .healthcare: return "#FF2D92"
        case .education: return "#5856D6"
        case .other: return "#8E8E93"
        }
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
