import Combine
import MapKit
import SwiftUI
import AudioToolbox

struct Home: View {
    @State private var mapState: MapViewState = .noInput
    @State private var alarmDistance: Double = 482.81
    @State private var showSearchModal = false
    @StateObject private var navigationState = NavigationState()

    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var tripProgressViewModel: TripProgressViewModel
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var windowSharedModel: WindowSharedModel

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Map View - Full Screen Background
            MapView(
                mapState: $mapState,
                alarmDistance: $alarmDistance,
                showLocationSearch: $showSearchModal,
                navigationState: navigationState
            )

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
                        Text("Quick Destinations")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        ForEach(DestinationData.quickDestinations, id: \.title) { destination in
                            QuickDestinationButton(
                                destination: destination
                            ) {
                                setDestinationFromQuickButton(destination: destination)
                            }
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
                                        // Convert search result to coordinate and set destination
                                        if let coordinate = result.coordinate {
                                            setDestinationFromSearch(coordinate: coordinate, title: result.title)
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
    }
    
    // MARK: - Helper Functions
    
    private func setDestinationFromQuickButton(destination: DestinationData) {
        // Close the search modal
        showSearchModal = false
        
        // Set the destination using NavigationState
        navigationState.setDestination(destination.coordinate, title: destination.title)
        
        // Update map state
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .locationSelected
        }
        
        // Provide haptic feedback
        provideHapticFeedback()
    }
    
    private func setDestinationFromSearch(coordinate: CLLocationCoordinate2D, title: String) {
        // Close the search modal
        showSearchModal = false
        
        // Set the destination using NavigationState
        navigationState.setDestination(coordinate, title: title)
        
        // Update map state
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .locationSelected
        }
        
        // Provide haptic feedback
        provideHapticFeedback()
    }
    
    private func provideHapticFeedback() {
        // Simple haptic feedback using system sound
        AudioServicesPlaySystemSound(1104) // Light impact sound
    }
}

// Enhanced Quick Destination Button
struct QuickDestinationButton: View {
    let destination: DestinationData
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle()
                        .fill(destination.type.color)
                        .frame(width: 40, height: 40)

                    Image(systemName: destination.type.icon)
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(destination.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(destination.subtitle)
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
        @ViewBuilder placeholder: () -> Content) -> some View {
        
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
