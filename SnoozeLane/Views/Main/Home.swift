import Combine
import MapKit
import SwiftUI

struct Home: View {
    @State private var mapState: MapViewState = .noInput
    @State private var alarmDistance: Double = 482.81
    @State private var showSearchModal = false

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
                showLocationSearch: $showSearchModal
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
                        .foregroundColor(Color("1"))

                    Spacer()

                    Button(action: {
                        showSearchModal = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("3"))
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("3"))
                        .padding(.leading, 12)

                    TextField("Search destinations...", text: $locationViewModel.queryFragment)
                        .font(.system(size: 18, weight: .medium))
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(Color("1"))

                    if !locationViewModel.queryFragment.isEmpty {
                        Button(action: {
                            locationViewModel.queryFragment = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color("3"))
                        }
                        .padding(.trailing, 12)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color("6").opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                // Quick Destinations or Search Results
                if locationViewModel.queryFragment.isEmpty {
                    // Quick Destination Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Destinations")
                            .font(.headline)
                            .foregroundColor(Color("1"))
                            .padding(.horizontal)

                        // Home
                        QuickDestinationButton(
                            title: "Home",
                            subtitle: "123 Main St",
                            icon: "house.fill",
                            color: Color.blue
                        ) {
                            showSearchModal = false
                        }

                        // Work
                        QuickDestinationButton(
                            title: "Work",
                            subtitle: "456 Office Rd",
                            icon: "briefcase.fill",
                            color: Color.green
                        ) {
                            showSearchModal = false
                        }

                        // Gym
                        QuickDestinationButton(
                            title: "Gym",
                            subtitle: "Fitness Center",
                            icon: "dumbbell.fill",
                            color: Color.purple
                        ) {
                            showSearchModal = false
                        }

                        // Grocery Store
                        QuickDestinationButton(
                            title: "Grocery Store",
                            subtitle: "Supermarket",
                            icon: "cart.fill",
                            color: Color.orange
                        ) {
                            showSearchModal = false
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
                                    .foregroundColor(Color("2"))
                                    .padding()
                            } else {
                                ForEach(locationViewModel.results, id: \.self) { result in
                                    LocationSearchResultsCell(
                                        title: result.title,
                                        subtitle: result.subtitle
                                    )
                                    .onTapGesture {
                                        locationViewModel.selectLocation(result)
                                        mapState = .locationSelected
                                        showSearchModal = false
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .background(Color("6"))
            .presentationDetents([.medium, .large])
        }
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
                        .foregroundColor(Color("1"))

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color("2"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(Color("3"))
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color("6").opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
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
