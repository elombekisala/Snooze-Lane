import Foundation
import MapKit
import SwiftUI

// MARK: - Navigation State Model
class NavigationState: ObservableObject {
    @Published var selectedDestination: CLLocationCoordinate2D?
    @Published var destinationTitle: String = ""
    @Published var shouldSetDestination: Bool = false
    
    func setDestination(_ coordinate: CLLocationCoordinate2D, title: String) {
        selectedDestination = coordinate
        destinationTitle = title
        shouldSetDestination = true
    }
    
    func clearDestination() {
        selectedDestination = nil
        destinationTitle = ""
        shouldSetDestination = false
    }
    
    func destinationSet() {
        shouldSetDestination = false
    }
}

// MARK: - Destination Data Model
struct DestinationData {
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let type: DestinationType
    
    enum DestinationType {
        case home
        case work
        case gym
        case grocery
        case custom
        
        var icon: String {
            switch self {
            case .home:
                return "house.fill"
            case .work:
                return "briefcase.fill"
            case .gym:
                return "dumbbell.fill"
            case .grocery:
                return "cart.fill"
            case .custom:
                return "mappin.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .home:
                return .blue
            case .work:
                return .green
            case .gym:
                return .purple
            case .grocery:
                return .orange
            case .custom:
                return .red
            }
        }
    }
}

// MARK: - Quick Destinations
extension DestinationData {
    static let quickDestinations: [DestinationData] = [
        DestinationData(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            title: "Home",
            subtitle: "123 Main St",
            type: .home
        ),
        DestinationData(
            coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            title: "Work",
            subtitle: "456 Office Rd",
            type: .work
        ),
        DestinationData(
            coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294),
            title: "Gym",
            subtitle: "Fitness Center",
            type: .gym
        ),
        DestinationData(
            coordinate: CLLocationCoordinate2D(latitude: 37.7549, longitude: -122.4394),
            title: "Grocery Store",
            subtitle: "Supermarket",
            type: .grocery
        )
    ]
}
