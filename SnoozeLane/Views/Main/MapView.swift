import MapKit
import SwiftUI
import AudioToolbox

struct MapView: View {
    @Binding var mapState: MapViewState
    @Binding var alarmDistance: Double
    @Binding var showLocationSearch: Bool
    let navigationState: NavigationState

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
    @State private var destinationAnnotation: MKPointAnnotation?
    @State private var routePolyline: MKPolyline?
    
    // Map interaction state
    @State private var isMapInteracting = false
    @State private var lastUserLocation: CLLocation?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Map with polyline and annotations
            Map(
                coordinateRegion: $region, 
                showsUserLocation: true,
                userTrackingMode: .constant(.follow)
            )
            .mapStyle(mapType == .standard ? .standard : mapType == .satellite ? .imagery : .hybrid)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: mapState)
            .onTapGesture(count: 1) {
                // Single tap to clear selection
                clearDestination()
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        // Handle long press for destination selection
                        handleLongPress()
                    }
            )

            // Top Controls - Pinned to top right (State-based visibility)
            if mapState.shouldShowTopControls {
                VStack(spacing: 12) {
                    // Map Type Button
                    Button(action: {
                        cycleMapType()
                    }) {
                        Image(systemName: mapTypeIcon)
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
                        centerOnUserLocation()
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
                    LocationDetailsCard(
                        mapState: $mapState,
                        destination: selectedDestination,
                        distance: calculateDistanceToDestination()
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Alarm Settings Card (when setting alarm radius)
                if mapState.shouldShowAlarmSettings {
                    AlarmSettingsCard(
                        alarmDistance: $alarmDistance, 
                        mapState: $mapState,
                        onStartTrip: startTrip
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Trip Progress Card (when trip is in progress)
                if mapState.shouldShowTripProgress {
                    TripProgressCard(
                        mapState: $mapState,
                        distance: calculateDistanceToDestination(),
                        onEndTrip: endTrip
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: mapState)
        }
        .onAppear {
            setupLocationUpdates()
        }
        .onChange(of: mapState) {
            handleMapStateChange()
        }
        .onChange(of: locationManager.location) { newLocation in
            handleLocationUpdate(newLocation)
        }
        .onChange(of: navigationState.shouldSetDestination) { shouldSet in
            if shouldSet {
                handleNavigationStateDestination()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Computed Properties
    
    private var mapTypeIcon: String {
        switch mapType {
        case .standard:
            return "map"
        case .satellite:
            return "globe"
        case .hybrid:
            return "map.fill"
        case .satelliteFlyover:
            return "globe"
        @unknown default:
            return "map"
        }
    }
    
    // MARK: - Public Functions
    
    func setDestinationFromSearch(_ coordinate: CLLocationCoordinate2D, title: String) {
        setDestination(coordinate, title: title)
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .locationSelected
        }
        scaleMapToShowBothLocations()
    }
    
    // MARK: - Private Functions
    
    private func setupLocationUpdates() {
        locationManager.startUpdatingLocation()
        startLocationUpdateTimer()
        
        // Center on user location initially
        if let userLocation = locationManager.location {
            centerOnLocation(userLocation)
        }
    }
    
    private func handleNavigationStateDestination() {
        guard let coordinate = navigationState.selectedDestination,
              let title = navigationState.destinationTitle.isEmpty ? nil : navigationState.destinationTitle else {
            return
        }
        
        setDestination(coordinate, title: title)
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .locationSelected
        }
        scaleMapToShowBothLocations()
        
        // Mark destination as set
        navigationState.destinationSet()
    }
    
    private func cycleMapType() {
        switch mapType {
        case .standard:
            mapType = .satellite
        case .satellite:
            mapType = .hybrid
        case .hybrid:
            mapType = .standard
        case .satelliteFlyover:
            mapType = .standard
        @unknown default:
            mapType = .standard
        }
    }
    
    private func centerOnUserLocation() {
        guard let userLocation = locationManager.location else { return }
        centerOnLocation(userLocation)
        
        // Provide haptic feedback
        provideHapticFeedback()
    }
    
    private func centerOnLocation(_ location: CLLocation) {
        let newRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = newRegion
        }
    }
    
    private func handleLongPress() {
        // Use the center of the current map view as the destination
        let coordinate = region.center
        let title = "Selected Location"
        setDestination(coordinate, title: title)
        
        // Update map state to show location details
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .locationSelected
        }
        
        // Scale map to show both user location and destination
        scaleMapToShowBothLocations()
        
        // Provide haptic feedback
        provideHapticFeedback()
    }

    private func setDestination(_ coordinate: CLLocationCoordinate2D, title: String) {
        selectedDestination = coordinate
        
        // Create destination annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        destinationAnnotation = annotation
        
        // Update polyline coordinates
        updatePolylineCoordinates()
        
        isNavigating = true
    }

    private func clearDestination() {
        selectedDestination = nil
        destinationAnnotation = nil
        polylineCoordinates = []
        isNavigating = false
        
        // Reset map state
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .noInput
        }
        
        // Stop location updates
        stopLocationUpdateTimer()
        
        // Clear navigation state
        navigationState.clearDestination()
    }
    
    private func updatePolylineCoordinates() {
        guard let userLocation = locationManager.location,
              let destination = selectedDestination else { return }
        
        // Create polyline from user location to destination
        polylineCoordinates = [
            userLocation.coordinate,
            destination
        ]
        
        // Scale map to show both locations if not interacting
        if !isMapInteracting {
            scaleMapToShowBothLocations()
        }
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
    
    private func calculateDistanceToDestination() -> Double? {
        guard let userLocation = locationManager.location,
              let destination = selectedDestination else { return nil }
        
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return userLocation.distance(from: destinationLocation)
    }
    
    private func startTrip() {
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .tripInProgress
        }
        
        // Start monitoring for destination approach
        startDestinationMonitoring()
        
        // Provide haptic feedback
        provideHapticFeedback()
    }
    
    private func endTrip() {
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .noInput
        }
        
        clearDestination()
        
        // Provide haptic feedback
        provideHapticFeedback()
    }
    
    private func startDestinationMonitoring() {
        guard let destination = selectedDestination else { return }
        
        // Create a location from the destination coordinate
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        
        // Start monitoring using the LocationManager's custom method
        locationManager.startMonitoring(destinationLocation, radius: alarmDistance)
    }
    
    private func handleMapStateChange() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showTopControls = mapState.shouldShowTopControls
            showMapControls = mapState.shouldShowMapControls
        }
    }
    
    private func handleLocationUpdate(_ newLocation: CLLocation?) {
        guard let newLocation = newLocation else { return }
        
        lastUserLocation = newLocation
        
        // Update polyline when user location changes
        if isNavigating {
            updatePolylineCoordinates()
        }
        
        // Check if user has reached destination
        if mapState == .tripInProgress {
            checkDestinationReached(newLocation)
        }
    }
    
    private func checkDestinationReached(_ location: CLLocation) {
        guard let destination = selectedDestination else { return }
        
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let distance = location.distance(from: destinationLocation)
        
        if distance <= alarmDistance {
            // Destination reached!
            destinationReached()
        }
    }
    
    private func destinationReached() {
        // Provide haptic feedback
        provideHapticFeedback()
        
        // Show alert or notification
        // For now, just end the trip
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            endTrip()
        }
    }
    
    private func provideHapticFeedback() {
        // Simple haptic feedback using system sound
        // In a real app, you'd use UIImpactFeedbackGenerator
        AudioServicesPlaySystemSound(1104) // Light impact sound
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
    let destination: CLLocationCoordinate2D?
    let distance: Double?

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

                    if let distance = distance {
                        Text("Distance: \(formatDistance(distance))")
                            .font(.subheadline)
                            .foregroundColor(Color("2"))
                    }
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
    
    private func formatDistance(_ distance: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        
        if distance >= 1000 {
            let kilometers = Measurement(value: distance / 1000, unit: UnitLength.kilometers)
            return formatter.string(from: kilometers)
        } else {
            let meters = Measurement(value: distance, unit: UnitLength.meters)
            return formatter.string(from: meters)
        }
    }
}

struct AlarmSettingsCard: View {
    @Binding var alarmDistance: Double
    @Binding var mapState: MapViewState
    let onStartTrip: () -> Void

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
                    onStartTrip()
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
    let distance: Double?
    let onEndTrip: () -> Void

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

                    if let distance = distance {
                        Text("Distance remaining: \(formatDistance(distance))")
                            .font(.subheadline)
                            .foregroundColor(Color("2"))
                    } else {
                        Text("Approaching destination")
                            .font(.subheadline)
                            .foregroundColor(Color("2"))
                    }
                }

                Spacer()

                Button("End Trip") {
                    onEndTrip()
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
    
    private func formatDistance(_ distance: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        
        if distance >= 1000 {
            let kilometers = Measurement(value: distance / 1000, unit: UnitLength.kilometers)
            return formatter.string(from: kilometers)
        } else {
            let meters = Measurement(value: distance, unit: UnitLength.meters)
            return formatter.string(from: meters)
        }
    }
}

#Preview {
    MapView(
        mapState: .constant(.noInput),
        alarmDistance: .constant(482.81),
        showLocationSearch: .constant(false),
        navigationState: NavigationState()
    )
    .environmentObject(LocationSearchViewModel(locationManager: LocationManager()))
    .environmentObject(TripProgressViewModel(locationViewModel: LocationSearchViewModel(locationManager: LocationManager())))
    .environmentObject(LocationManager())
}
