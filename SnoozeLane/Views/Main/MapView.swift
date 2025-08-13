import MapKit
import SwiftUI

struct MapView: View {
    @Binding var mapState: MapViewState
    @Binding var alarmDistance: Double
    @Binding var showLocationSearch: Bool

    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var tripProgressViewModel: TripProgressViewModel
    @EnvironmentObject var locationManager: LocationManager

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var showTopControls = true
    @State private var showMapControls = true

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Map
            Map(
                coordinateRegion: $region, showsUserLocation: true,
                userTrackingMode: .constant(.follow)
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: mapState)

            // Top Controls - Pinned to top right (State-based visibility)
            if mapState.shouldShowTopControls {
                VStack(spacing: 12) {
                    // Map Type Button
                    Button(action: {
                        // Toggle map type if needed
                    }) {
                        Image(systemName: "map")
                            .font(.title2)
                            .foregroundColor(mapState.accentColor)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(
                                        color: mapState.accentColor.opacity(0.3), radius: 4, x: 0,
                                        y: 2)
                            )
                    }
                    .transition(.scale.combined(with: .opacity))

                    // Location Button
                    Button(action: {
                        // Center on user location
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(mapState.accentColor)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(
                                        color: mapState.accentColor.opacity(0.3), radius: 4, x: 0,
                                        y: 2)
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                .padding(.top, 60)  // Account for status bar
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .animation(.easeInOut(duration: 0.3), value: mapState)
            }

            // State-specific overlay views
            VStack {
                Spacer()

                // Location Details Card (when location is selected)
                if mapState.shouldShowLocationDetails {
                    LocationDetailsCard(mapState: $mapState)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Alarm Settings Card (when setting alarm radius)
                if mapState.shouldShowAlarmSettings {
                    AlarmSettingsCard(alarmDistance: $alarmDistance, mapState: $mapState)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Trip Progress Card (when trip is in progress)
                if mapState.shouldShowTripProgress {
                    TripProgressCard(mapState: $mapState)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: mapState)
        }
        .onAppear {
            // Request location when view appears
            // locationManager.requestLocation()
        }
        .onChange(of: mapState) {
            // Handle state changes with animations
            withAnimation(.easeInOut(duration: 0.3)) {
                showTopControls = mapState.shouldShowTopControls
                showMapControls = mapState.shouldShowMapControls
            }
        }
    }
}

// MARK: - State-specific UI Components

struct LocationDetailsCard: View {
    @Binding var mapState: MapViewState

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(mapState.accentColor)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Destination Selected")
                        .font(.headline)
                        .foregroundColor(Color("1"))

                    Text("Tap to set alarm radius")
                        .font(.subheadline)
                        .foregroundColor(Color("2"))
                }

                Spacer()

                Button("Set Alarm") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mapState = .settingAlarmRadius
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(mapState.accentColor)
                .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 8)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

struct AlarmSettingsCard: View {
    @Binding var alarmDistance: Double
    @Binding var mapState: MapViewState

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundColor(mapState.accentColor)
                    .font(.title2)

                Text("Set Alarm Radius")
                    .font(.headline)
                    .foregroundColor(Color("1"))

                Spacer()

                Button("Start Trip") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mapState = .tripInProgress
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(mapState.accentColor)
                .cornerRadius(20)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Distance: \(Int(alarmDistance)) meters")
                    .font(.subheadline)
                    .foregroundColor(Color("2"))

                Slider(value: $alarmDistance, in: 100...1000, step: 50)
                    .accentColor(mapState.accentColor)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 8)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

struct TripProgressCard: View {
    @Binding var mapState: MapViewState

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(mapState.accentColor)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Trip in Progress")
                        .font(.headline)
                        .foregroundColor(Color("1"))

                    Text("Approaching destination")
                        .font(.subheadline)
                        .foregroundColor(Color("2"))
                }

                Spacer()

                Button("End Trip") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mapState = .noInput
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(mapState.accentColor)
                .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 8)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

#Preview {
    MapView(
        mapState: .constant(.noInput),
        alarmDistance: .constant(482.81),
        showLocationSearch: .constant(false)
    )
}
