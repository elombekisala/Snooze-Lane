import AudioToolbox
import Combine
import MapKit
import SwiftUI
import Foundation

struct Home: View {
    @State private var mapState: MapViewState = .noInput
    @State private var alarmDistance: Double = 482.81
    @State private var showSearchModal = false
    @State private var showAddDestinationModal = false

    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var tripProgressViewModel: TripProgressViewModel
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var windowSharedModel: WindowSharedModel
    
    // @State private var quickDestinationsManager = QuickDestinationsManager.shared
    


    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Map View - Full Screen Background
            MapView(
                mapState: $mapState,
                alarmDistance: $alarmDistance,
                showLocationSearch: $showSearchModal,
                onDestinationSelected: { coordinate, title in
                    // Handle destination selection from MapView
                    handleDestinationSelected(coordinate: coordinate, title: title)
                }
            )
            .environmentObject(locationManager)

            // Floating Search Bar at the Bottom (State-based visibility)
            if mapState.shouldShowSearchBar {
                Button(action: {
                    showSearchModal = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 15)

                        Text("Where To?")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)

                        Spacer()

                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 15)
                    }
                    .frame(height: 50)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(radius: 5)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: mapState)
            }
        }

        .sheet(isPresented: $showSearchModal) {
            // Enhanced Search Modal View
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Search Destinations")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        showSearchModal = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.leading, 12)

                    TextField("Search destinations...", text: $locationViewModel.queryFragment)
                        .font(.system(size: 18, weight: .medium))
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .placeholder(when: locationViewModel.queryFragment.isEmpty) {
                            Text("Search destinations...")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 18, weight: .medium))
                        }

                    if !locationViewModel.queryFragment.isEmpty {
                        Button(action: {
                            locationViewModel.queryFragment = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.trailing, 12)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)

                // Quick Destinations or Search Results
                if locationViewModel.queryFragment.isEmpty {
                    // Quick Destination Options
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Quick Destinations")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                showAddDestinationModal = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                        }
                        .padding(.horizontal)

                        // Home
                        QuickDestinationButton(
                            title: "Home",
                            subtitle: "123 Main St",
                            icon: "house.fill",
                            color: Color.blue
                        ) {
                            // Set destination to home coordinates
                            let homeCoordinate = CLLocationCoordinate2D(
                                latitude: 37.7749, longitude: -122.4194)
                            handleDestinationSelected(coordinate: homeCoordinate, title: "Home")
                        }

                        // Work
                        QuickDestinationButton(
                            title: "Work",
                            subtitle: "456 Office Rd",
                            icon: "briefcase.fill",
                            color: Color.green
                        ) {
                            // Set destination to work coordinates
                            let workCoordinate = CLLocationCoordinate2D(
                                latitude: 37.7849, longitude: -122.4094)
                            handleDestinationSelected(coordinate: workCoordinate, title: "Work")
                        }

                        // Gym
                        QuickDestinationButton(
                            title: "Gym",
                            subtitle: "Fitness Center",
                            icon: "dumbbell.fill",
                            color: Color.purple
                        ) {
                            // Set destination to gym coordinates
                            let gymCoordinate = CLLocationCoordinate2D(
                                latitude: 37.7649, longitude: -122.4294)
                            handleDestinationSelected(coordinate: gymCoordinate, title: "Gym")
                        }

                        // Grocery Store
                        QuickDestinationButton(
                            title: "Grocery Store",
                            subtitle: "Supermarket",
                            icon: "cart.fill",
                            color: Color.orange
                        ) {
                            // Set destination to grocery store coordinates
                            let groceryCoordinate = CLLocationCoordinate2D(
                                latitude: 37.7549, longitude: -122.4394)
                            handleDestinationSelected(
                                coordinate: groceryCoordinate, title: "Grocery Store")
                        }
                    }
                    .padding(.top)
                } else {
                    // Location Search Results
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            if locationViewModel.results.isEmpty
                                && !locationViewModel.queryFragment.isEmpty
                            {
                                Text("No results found for \"\(locationViewModel.queryFragment)\"")
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding()
                            } else {
                                ForEach(locationViewModel.results, id: \.self) { result in
                                    LocationSearchResultsCell(
                                        title: result.title,
                                        subtitle: result.subtitle
                                    )
                                    .onTapGesture {
                                        // Select the location (handles annotation, overlays, and fitting)
                                        print("Search result selected: \(result.title)")
                                        locationViewModel.selectLocation(result)

                                        // Update map state and close modal
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            mapState = .locationSelected
                                            showSearchModal = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .background(Color.black)
            .presentationDetents([.medium, .large])
        }
        
        // Add/Edit Quick Destination Modal
        // .sheet(isPresented: $showAddDestinationModal) {
        //     QuickDestinationEditView(quickDestinationsManager: quickDestinationsManager)
        // }
    }

    // MARK: - Helper Functions

    private func provideHapticFeedback() {
        // Simple haptic feedback using system sound
        AudioServicesPlaySystemSound(1104)  // Light impact sound
    }

    private func handleDestinationSelected(coordinate: CLLocationCoordinate2D, title: String) {
        // Close the search modal if it's open
        showSearchModal = false

        // Update the map state to show location details
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .locationSelected
        }

        // Provide haptic feedback
        provideHapticFeedback()

        print("Destination selected: \(title) at \(coordinate)")
    }
}



// Simple Quick Destination Button
struct QuickDestinationButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// MARK: - Extensions
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .environmentObject(LocationSearchViewModel(locationManager: LocationManager()))
            .environmentObject(
                TripProgressViewModel(
                    locationViewModel: LocationSearchViewModel(locationManager: LocationManager()))
            )
            .environmentObject(LoginViewModel())
            .environmentObject(LocationManager())
            .environmentObject(WindowSharedModel())
    }
}
