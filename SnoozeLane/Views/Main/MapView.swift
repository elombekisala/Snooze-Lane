import AudioToolbox
import MapKit
import SwiftUI
import UIKit

// MARK: - Enums

enum TransportationMode: String, CaseIterable {
    case car = "car"
    case bus = "bus"
    case train = "train"

    var averageSpeed: Double {  // km/h
        switch self {
        case .car: return 60.0
        case .bus: return 25.0
        case .train: return 80.0
        }
    }

    var displayName: String {
        switch self {
        case .car: return "Car"
        case .bus: return "Bus"
        case .train: return "Train"
        }
    }
}

struct MapView: View {
    @Binding var mapState: MapViewState
    @Binding var alarmDistance: Double
    @Binding var showLocationSearch: Bool
    var onDestinationSelected: ((CLLocationCoordinate2D, String) -> Void)?

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
    @State private var alarmRadiusCircle: MKCircle?

    // Map interaction state
    @State private var isMapInteracting = false
    @State private var lastUserLocation: CLLocation?
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var mapViewSize: CGSize = .zero
    @State private var longPressLocation: CGPoint = .zero
    @State private var isLongPressing: Bool = false
    @State private var longPressTimer: Timer?
    @State private var longPressCancelledByMovement: Bool = false

    // Bridge state for MapViewRepresentable (MKMapView-backed)
    @State private var selectedMapItem: MKMapItem? = nil
    @State private var showingDetails: Bool = false
    @State private var userHasInteractedWithMapBridge: Bool = false
    @State private var isFollowingUser: Bool = true
    @State private var useMetricSystem: Bool = UserDefaults.standard.bool(forKey: "useMetricUnits")
    @State private var transportationMode: TransportationMode = .car

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // MKMapView-backed implementation for precise overlays (polyline, circle, pin)
            MapViewRepresentable(
                selectedMapItem: $selectedMapItem,
                showingDetails: $showingDetails,
                mapState: $mapState,
                userHasInteractedWithMap: $userHasInteractedWithMapBridge,
                alarmDistance: $alarmDistance,
                mapType: $mapType,
                isFollowingUser: $isFollowingUser
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: mapState)
            .overlay(
                // Estimated Rest Time Display - Top Center (during trip and alarm stages)
                Group {
                    if mapState.shouldShowTripProgress || mapState.shouldShowAlarmSettings {
                        VStack {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text("Estimated Rest Time")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))

                                        // Transportation mode picker
                                        Menu {
                                            ForEach(TransportationMode.allCases, id: \.self) {
                                                mode in
                                                Button(mode.displayName) {
                                                    transportationMode = mode
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "\(transportationMode.rawValue).fill")
                                                .foregroundColor(.white)
                                                .font(.caption)
                                        }
                                    }

                                    Text(calculateEstimatedRestTime())
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.7))
                                        .background(
                                            .ultraThinMaterial,
                                            in: RoundedRectangle(cornerRadius: 12))
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
                                Spacer()
                            }
                            .padding(.top, 60)  // Account for status bar
                            Spacer()
                        }
                    }
                }
            )

            // Gestures are handled inside MapViewRepresentable (long-press, double-tap, follow mode)
            .onChange(of: userTrackingMode) { newMode in
                // Handle user tracking mode changes
                if newMode == .none {
                    // Provide subtle haptic feedback when tracking stops
                    AudioServicesPlaySystemSound(1103)  // Light tap sound
                }
            }
            .onChange(of: alarmDistance) { _ in
                // Update alarm radius circle when distance changes
                if selectedDestination != nil {
                    updateAlarmRadiusCircle()
                }
            }
            .onChange(of: useMetricSystem) { newValue in
                // Save metric preference to UserDefaults
                UserDefaults.standard.set(newValue, forKey: "useMetricUnits")
            }
            .onReceive(NotificationCenter.default.publisher(for: .unitsPreferenceChanged)) {
                notif in
                if let val = notif.userInfo?["useMetricUnits"] as? Bool {
                    useMetricSystem = val
                } else {
                    useMetricSystem = UserDefaults.standard.bool(forKey: "useMetricUnits")
                }
            }

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
                        withAnimation(.easeInOut(duration: 0.1)) {
                            // Brief flash effect
                        }
                        centerOnUserLocation()
                    }) {
                        Image(
                            systemName: userTrackingMode == .follow ? "location.fill" : "location"
                        )
                        .font(.title2)
                        .foregroundColor(userTrackingMode == .follow ? mapState.accentColor : .blue)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(
                                    color: userTrackingMode == .follow
                                        ? mapState.accentColor.opacity(0.3) : .blue.opacity(0.3),
                                    radius: 4, x: 0, y: 2
                                )
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                    .scaleEffect(userTrackingMode == .follow ? 1.0 : 1.1)
                    .overlay(
                        // Active state indicator when not following
                        Circle()
                            .stroke(
                                userTrackingMode == .follow ? Color.clear : Color.blue, lineWidth: 2
                            )
                            .scaleEffect(userTrackingMode == .follow ? 1.0 : 1.2)
                            .opacity(userTrackingMode == .follow ? 0.0 : 0.8)
                    )
                    .overlay(
                        // Pulsing animation when not following
                        Circle()
                            .stroke(
                                userTrackingMode == .follow ? Color.clear : Color.blue.opacity(0.3),
                                lineWidth: 1
                            )
                            .scaleEffect(userTrackingMode == .follow ? 1.0 : 1.4)
                            .opacity(userTrackingMode == .follow ? 0.0 : 0.6)
                            .animation(
                                userTrackingMode == .follow
                                    ? nil
                                    : Animation.easeInOut(duration: 1.5).repeatForever(
                                        autoreverses: true),
                                value: userTrackingMode
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: userTrackingMode)

                    // Tooltip when not following
                    if userTrackingMode != .follow {
                        Text("Tap to follow")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            .transition(.opacity.combined(with: .scale))
                    }

                    // Metric/Imperial Toggle Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            useMetricSystem.toggle()
                        }
                    }) {
                        Text(useMetricSystem ? "km" : "mi")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(useMetricSystem ? Color.blue : Color.orange)
                                    .shadow(
                                        color: (useMetricSystem ? Color.blue : Color.orange)
                                            .opacity(0.3),
                                        radius: 4, x: 0, y: 2
                                    )
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
                        useMetricSystem: useMetricSystem,
                        onStartTrip: startTrip
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Trip Progress Card (when trip is in progress)
                if mapState.shouldShowTripProgress {
                    TripProgressCard(
                        mapState: $mapState,
                        distance: calculateDistanceToDestination(),
                        useMetricSystem: useMetricSystem,
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
        .onReceive(NotificationCenter.default.publisher(for: .mapTypeChanged)) { notif in
            if let raw = notif.userInfo?["mapType"] as? UInt, let t = MKMapType(rawValue: raw) {
                mapType = t
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .trafficToggled)) { notif in
            if let enabled = notif.userInfo?["enabled"] as? Bool {
                NotificationCenter.default.post(
                    name: .updateTrafficVisibility, object: nil, userInfo: ["enabled": enabled])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestLocationPermission)) { _ in
            locationManager.requestAuthorization()
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetMapOverlays)) { _ in
            NotificationCenter.default.post(name: .clearMapOverlays, object: nil)
            mapState = .noInput
        }
        .onChange(of: mapState) {
            handleMapStateChange()
        }
        .onChange(of: locationManager.location) { newLocation in
            handleLocationUpdate(newLocation)

            // Update polyline and annotations when location changes
            if let newLocation = newLocation, selectedDestination != nil {
                updatePolylineCoordinates()
            }
        }

        // React when a destination is picked from search results
        .onChange(of: locationViewModel.selectedSnoozeLaneLocation) { newValue in
            guard let newValue = newValue else { return }
            let coord = newValue.coordinate
            let title = newValue.title ?? "Selected Location"
            print("🧭 MapView observed selectedSnoozeLaneLocation: \(coord)")
            setDestinationFromSearch(coord, title: title)
        }

        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Computed Views

    @ViewBuilder
    private var mapOverlays: some View { EmptyView() }

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
        case .hybridFlyover:
            mapType = .standard
        case .mutedStandard:
            mapType = .standard
        case .hybridFlyover:
            mapType = .standard
        @unknown default:
            mapType = .standard
        }
    }

    private func centerOnUserLocation() {
        guard let userLocation = locationManager.location else { return }
        centerOnLocation(userLocation)

        // Reset user tracking mode to follow
        userTrackingMode = .follow

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

    private func screenPointToCoordinate(_ screenPoint: CGPoint) -> CLLocationCoordinate2D {
        // Convert screen coordinates to map coordinates
        // This is the inverse of coordinateToScreenPoint

        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // Calculate the offset from center of screen
        let xOffset = screenPoint.x - screenWidth / 2
        let yOffset = screenPoint.y - screenHeight / 2

        // Convert offset to coordinate differences using current map scale
        let lonScale = region.span.longitudeDelta / screenWidth
        let latScale = region.span.latitudeDelta / screenHeight

        let lonDiff = Double(xOffset) * lonScale
        let latDiff = -Double(yOffset) * latScale  // Negative because screen Y increases downward

        // Calculate the actual coordinate
        let coordinate = CLLocationCoordinate2D(
            latitude: region.center.latitude + latDiff,
            longitude: region.center.longitude + lonDiff
        )

        // DEBUG: Log the coordinate conversion process
        print("🔄 COORDINATE CONVERSION DEBUG:")
        print("   📱 Screen Point: \(screenPoint.x), \(screenPoint.y)")
        print("   📱 Screen Size: \(screenWidth) x \(screenHeight)")
        print("   📍 Map Center: \(region.center.latitude), \(region.center.longitude)")
        print("   🗺️  Map Span: \(region.span.latitudeDelta), \(region.span.longitudeDelta)")
        print("   📐 Offsets: x=\(xOffset), y=\(yOffset)")
        print("   📏 Scales: lon=\(lonScale), lat=\(latScale)")
        print("   📐 Diffs: lon=\(lonDiff), lat=\(latDiff)")
        print("   🎯 Final Coordinate: \(coordinate.latitude), \(coordinate.longitude)")

        return coordinate
    }

    private func handleLongPressAtLocation(_ location: CGPoint) {
        // Convert screen coordinates to map coordinates
        let coordinate = screenPointToCoordinate(location)
        let title = "Selected Location"

        // DEBUG: Log the long press location handling
        print("👆 LONG PRESS LOCATION DEBUG:")
        print("   📱 Screen Location: \(location.x), \(location.y)")
        print("   🎯 Converted Coordinate: \(coordinate.latitude), \(coordinate.longitude)")
        print("   ✅ This function IS being called with actual screen coordinates!")

        setDestination(coordinate, title: title)

        // Update map state to show location details
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .locationSelected
        }

        // Don't automatically scale the map - let user control it naturally
        // This prevents the pulsing/refreshing behavior

        // Provide haptic feedback
        provideHapticFeedback()
    }

    private func setDestination(_ coordinate: CLLocationCoordinate2D, title: String) {
        selectedDestination = coordinate

        // DEBUG: Log what coordinates are actually being set
        print("🎯 SET DESTINATION DEBUG:")
        print("   📍 Coordinate being set: \(coordinate.latitude), \(coordinate.longitude)")
        print("   🏷️  Title: \(title)")
        print(
            "   📍 Selected destination stored: \(selectedDestination?.latitude ?? 0), \(selectedDestination?.longitude ?? 0)"
        )

        // Create destination annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        destinationAnnotation = annotation

        // Update polyline coordinates
        updatePolylineCoordinates()

        // Update alarm radius circle
        updateAlarmRadiusCircle()

        isNavigating = true

        // Notify parent view
        onDestinationSelected?(coordinate, title)
    }

    private func clearDestination() {
        selectedDestination = nil
        destinationAnnotation = nil
        polylineCoordinates = []
        alarmRadiusCircle = nil
        isNavigating = false

        // Reset map state
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .noInput
        }

        // Stop location updates
        stopLocationUpdateTimer()
    }

    private func updatePolylineCoordinates() {
        guard let userLocation = locationManager.location,
            let destination = selectedDestination
        else { return }

        // Create polyline from user location to destination
        polylineCoordinates = [
            userLocation.coordinate,
            destination,
        ]

        // Don't automatically scale the map - let user control it naturally
        // This prevents the pulsing/refreshing behavior
    }

    private func updateAlarmRadiusCircle() {
        guard let destination = selectedDestination else { return }

        // Create a circle overlay for the alarm radius
        let circle = MKCircle(center: destination, radius: alarmDistance)
        alarmRadiusCircle = circle

        // The circle will be drawn in the overlay using SwiftUI
        // The size and position are calculated based on the map's current zoom level
    }

    private func coordinateToScreenPoint(_ coordinate: CLLocationCoordinate2D) -> CGPoint? {
        // Calculate position relative to the current map region
        let latDiff = coordinate.latitude - region.center.latitude
        let lonDiff = coordinate.longitude - region.center.longitude

        // Convert coordinate differences to screen points
        // Use the map's current span to determine scale
        let latScale = UIScreen.main.bounds.height / region.span.latitudeDelta
        let lonScale = UIScreen.main.bounds.width / region.span.longitudeDelta

        let x = UIScreen.main.bounds.width / 2 + CGFloat(lonDiff * Double(lonScale))
        let y = UIScreen.main.bounds.height / 2 - CGFloat(latDiff * Double(latScale))

        return CGPoint(x: x, y: y)
    }

    private func calculateCircleSize(for radius: Double) -> CGFloat {
        // Calculate circle size based on alarm radius and current map zoom
        // Use the map's current span to determine proper scale
        let latScale = UIScreen.main.bounds.height / region.span.latitudeDelta
        let lonScale = UIScreen.main.bounds.width / region.span.longitudeDelta

        // Use the smaller scale to ensure circle fits in view
        let scale = min(latScale, lonScale)

        // Convert radius from meters to screen points
        // 1 degree of latitude ≈ 111,000 meters
        let metersPerDegree = 111000.0
        let radiusInDegrees = radius / metersPerDegree

        return CGFloat(radiusInDegrees * Double(scale))
    }

    private func scaleMapToShowBothLocations() {
        guard let userLocation = locationManager.location,
            let destination = selectedDestination
        else { return }

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
            let destination = selectedDestination
        else { return nil }

        let destinationLocation = CLLocation(
            latitude: destination.latitude, longitude: destination.longitude)
        let distance = userLocation.distance(from: destinationLocation)

        // Ensure we return a valid distance
        return distance.isFinite ? distance : nil
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
        let destinationLocation = CLLocation(
            latitude: destination.latitude, longitude: destination.longitude)

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

        let destinationLocation = CLLocation(
            latitude: destination.latitude, longitude: destination.longitude)
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
        AudioServicesPlaySystemSound(1104)  // Light impact sound
    }

    // MARK: - Distance and Time Calculations

    func formatDistance(_ distance: Double) -> String {
        if useMetricSystem {
            // Metric: show meters or kilometers
            if distance >= 1000 {
                let kilometers = distance / 1000
                return String(format: "%.2f km", kilometers)
            } else {
                return String(format: "%.0f m", distance)
            }
        } else {
            // Imperial: show feet or miles with 0.01 precision
            let feet = distance * 3.28084
            if feet >= 5280 {  // 1 mile = 5280 feet
                let miles = feet / 5280
                return String(format: "%.2f mi", miles)
            } else {
                return String(format: "%.0f ft", feet)
            }
        }
    }

    private func calculateEstimatedRestTime() -> String {
        guard let destination = selectedDestination,
            let userLocation = locationManager.location
        else {
            return "00:00"
        }

        let distance = userLocation.distance(
            from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
        let distanceInKm = distance / 1000

        // Calculate time based on transportation mode average speed
        let timeInHours = distanceInKm / transportationMode.averageSpeed
        let timeInMinutes = Int(timeInHours * 60)

        let hours = timeInMinutes / 60
        let minutes = timeInMinutes % 60

        return String(format: "%02d:%02d", hours, minutes)
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
                        .foregroundColor(.white)

                    if let distance = distance {
                        Text("Distance: \(formatDistance(distance))")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
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
    let useMetricSystem: Bool
    let onStartTrip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundColor(mapState.accentColor)
                    .font(.title2)

                Text("Set Alarm Radius")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button("Start Trip") {
                    onStartTrip()
                }
                .foregroundColor(.white)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                        .shadow(color: .blue.opacity(0.4), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 2)
                )
                .cornerRadius(20)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Distance: \(formatDistance(alarmDistance))")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Slider(value: $alarmDistance, in: 100...1000, step: 50)
                    .accentColor(mapState.accentColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    private func formatDistance(_ distance: Double) -> String {
        if useMetricSystem {
            // Metric: show meters or kilometers
            if distance >= 1000 {
                let kilometers = distance / 1000
                return String(format: "%.2f km", kilometers)
            } else {
                return String(format: "%.0f m", distance)
            }
        } else {
            // Imperial: show feet or miles with 0.01 precision
            let feet = distance * 3.28084
            if feet >= 5280 {  // 1 mile = 5280 feet
                let miles = feet / 5280
                return String(format: "%.2f mi", miles)
            } else {
                return String(format: "%.0f ft", feet)
            }
        }
    }
}

struct TripProgressCard: View {
    @Binding var mapState: MapViewState
    let distance: Double?
    let useMetricSystem: Bool
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
                        .foregroundColor(.white)

                    if let distance = distance {
                        Text("Distance remaining: \(formatDistance(distance))")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("Approaching destination")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    private func formatDistance(_ distance: Double) -> String {
        if useMetricSystem {
            // Metric: show meters or kilometers
            if distance >= 1000 {
                let kilometers = distance / 1000
                return String(format: "%.2f km", kilometers)
            } else {
                return String(format: "%.0f m", distance)
            }
        } else {
            // Imperial: show feet or miles with 0.01 precision
            let feet = distance * 3.28084
            if feet >= 5280 {  // 1 mile = 5280 feet
                let miles = feet / 5280
                return String(format: "%.2f mi", miles)
            } else {
                return String(format: "%.0f ft", feet)
            }
        }
    }
}

#Preview {
    MapView(
        mapState: .constant(.noInput),
        alarmDistance: .constant(482.81),
        showLocationSearch: .constant(false),
        onDestinationSelected: { coordinate, title in
            print("Preview: Destination selected: \(title) at \(coordinate)")
        }
    )
    .environmentObject(LocationSearchViewModel(locationManager: LocationManager()))
    .environmentObject(
        TripProgressViewModel(
            locationViewModel: LocationSearchViewModel(locationManager: LocationManager()))
    )
    .environmentObject(LocationManager())
}
