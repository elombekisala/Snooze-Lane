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
    @State private var showSettings = false
    @State private var mapType: MKMapType = .standard
    
    // Navigation state
    @State private var selectedDestination: CLLocationCoordinate2D?
    @State private var polylineCoordinates: [CLLocationCoordinate2D] = []
    @State private var isNavigating = false
    @State private var locationUpdateTimer: Timer?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Map with polyline and annotations
            Map(
                coordinateRegion: $region, showsUserLocation: true,
                userTrackingMode: .constant(.follow)
            )
            .mapStyle(mapType == .standard ? .standard : mapType == .satellite ? .imagery : .hybrid)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: mapState)
            .overlay(
                // Polyline and destination overlay
                ZStack {
                    // Polyline path
                    if polylineCoordinates.count >= 2 {
                        Path { path in
                            // Convert coordinates to screen points (simplified)
                            let startPoint = CGPoint(x: 100, y: 300)
                            let endPoint = CGPoint(x: 300, y: 300)
                            
                            path.move(to: startPoint)
                            path.addLine(to: endPoint)
                        }
                        .stroke(Color.blue, lineWidth: 4)
                    }
                    
                    // Destination annotation
                    if let destination = selectedDestination {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                            .background(Circle().fill(.white))
                            .position(
                                x: 300, y: 300 // Placeholder position
                            )
                    }
                }
            )
            .onTapGesture(count: 1) {
                // Single tap to clear selection
                clearDestination()
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        // Handle long press - we'll implement coordinate conversion differently
                        handleLongPress()
                    }
            )

            // Top Controls - Pinned to top right (State-based visibility)
            if mapState.shouldShowTopControls {
                VStack(spacing: 12) {
                    // Map Type Button
                    Button(action: {
                        // Toggle map type if needed
                        switch mapType {
                        case .standard:
                            mapType = .satellite
                        case .satellite:
                            mapType = .hybrid
                        case .hybrid:
                            mapType = .standard
                        @unknown default:
                            mapType = .standard
                        }
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

                    // Settings Button
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
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
            locationManager.startUpdatingLocation()
            
            // Start location update timer for real-time polyline updates
            startLocationUpdateTimer()
        }
        .onChange(of: mapState) {
            // Handle state changes with animations
            withAnimation(.easeInOut(duration: 0.3)) {
                showTopControls = mapState.shouldShowTopControls
                showMapControls = mapState.shouldShowMapControls
            }
        }
        .onChange(of: locationManager.location) { _ in
            // Update polyline when user location changes
            if isNavigating {
                updatePolylineCoordinates()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func handleLongPress() {
        // For now, use the center of the current map view as the destination
        // In a real implementation, you'd convert screen coordinates to map coordinates
        let coordinate = region.center
        setDestination(coordinate)
        
        // Update map state to show location details
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .locationSelected
        }
        
        // Scale map to show both user location and destination
        scaleMapToShowBothLocations()
    }

    private func setDestination(_ coordinate: CLLocationCoordinate2D) {
        selectedDestination = coordinate
        
        // Update polyline coordinates
        updatePolylineCoordinates()
        
        isNavigating = true
    }

    private func clearDestination() {
        selectedDestination = nil
        polylineCoordinates = []
        isNavigating = false
        
        // Reset map state
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .noInput
        }
    }
    
    private func updatePolylineCoordinates() {
        guard let userLocation = locationManager.location,
              let destination = selectedDestination else { return }
        
        // Create polyline from user location to destination
        polylineCoordinates = [
            userLocation.coordinate,
            destination
        ]
        
        // Scale map to show both locations
        scaleMapToShowBothLocations()
    }
    
    private func scaleMapToShowBothLocations() {
        guard let userLocation = locationManager.location,
              let destination = selectedDestination else { return }
        
        // Calculate the region that includes both locations
        let centerLat = (userLocation.coordinate.latitude + destination.latitude) / 2
        let centerLon = (userLocation.coordinate.longitude + destination.longitude) / 2
        
        let latDelta = abs(userLocation.coordinate.latitude - destination.latitude) * 1.5
        let lonDelta = abs(userLocation.coordinate.longitude - destination.longitude) * 1.5
        
        // Ensure minimum zoom level
        let minDelta = 0.01
        let finalLatDelta = max(latDelta, minDelta)
        let finalLonDelta = max(lonDelta, minDelta)
        
        let newRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: finalLatDelta, longitudeDelta: finalLonDelta)
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = newRegion
        }
    }

    private func startLocationUpdateTimer() {
        // Update polyline every 2 seconds when navigating
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if isNavigating {
                updatePolylineCoordinates()
            }
        }
    }
    
    private func stopLocationUpdateTimer() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
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
