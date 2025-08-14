import MapKit
import SwiftUI

// Add this extension at the top or in your notification constants file if not present
extension Notification.Name {
    static let centerOnUserLocation = Notification.Name("centerOnUserLocation")
}

struct MapViewRepresentable: UIViewRepresentable {
    let mapView = MKMapView()

    // Bindings to manage state between SwiftUI and UIKit
    @Binding var selectedMapItem: MKMapItem?
    @Binding var showingDetails: Bool
    @Binding var mapState: MapViewState
    @Binding var userHasInteractedWithMap: Bool
    @Binding var alarmDistance: Double
    @Binding var mapType: MKMapType
    @Binding var isFollowingUser: Bool
    @Binding var useDarkMapStyle: Bool

    // EnvironmentObjects to access shared data
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var locationViewModel: LocationSearchViewModel

    func makeCoordinator() -> MapCoordinator {
        return MapCoordinator(parent: self, isFollowingUser: $isFollowingUser)
    }

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator

        // Configure the map with new configuration
        let config = MKStandardMapConfiguration()
        config.emphasisStyle = useDarkMapStyle ? .muted : .default
        config.showsTraffic = false
        
        // Apply dark theme styling
        if useDarkMapStyle {
            config.pointOfInterestFilter = MKPointOfInterestFilter(excluding: [.airport, .bank, .hospital, .school])
            mapView.tintColor = .orange
            mapView.overrideUserInterfaceStyle = .dark
        } else {
            mapView.overrideUserInterfaceStyle = .light
        }

        // Set the configuration
        mapView.preferredConfiguration = config
        mapView.mapType = mapType

        // Configure the map view
        mapView.userTrackingMode = .follow
        mapView.showsUserLocation = true
        mapView.tintColor = .orange

        // Ensure isFollowingUser is true on initial load
        context.coordinator.isFollowingUser.wrappedValue = true

        // Add compass and scale bar
        mapView.showsCompass = true
        mapView.showsScale = true

        // Add the SwiftUI gesture to the UIViewRepresentable
        let longPressGesture = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleLongPress))
        longPressGesture.minimumPressDuration = 0.5  // Set to 0.5 seconds as requested
        mapView.addGestureRecognizer(longPressGesture)

        // Add double tap gesture to clear overlays and recenter
        let doubleTapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(doubleTapGesture)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        print("🗺️ updateUIView called - mapState: \(mapState)")
        // Update map type if changed
        if uiView.mapType != mapType {
            uiView.mapType = mapType
        }
        
        // Update dark style if changed
        if uiView.overrideUserInterfaceStyle != (useDarkMapStyle ? .dark : .light) {
            uiView.overrideUserInterfaceStyle = useDarkMapStyle ? .dark : .light
            // Reconfigure map with new style
            let config = MKStandardMapConfiguration()
            config.emphasisStyle = useDarkMapStyle ? .muted : .default
            config.showsTraffic = false
            uiView.preferredConfiguration = config
        }

        // Update UI elements based on map state
        updateMapUI(uiView)

        // Update overlays if location is selected
        if let coordinate = locationViewModel.selectedSnoozeLaneLocation?.coordinate {
            print("🗺️ updateUIView has selected destination: \(coordinate)")
            context.coordinator.updateOverlays(for: coordinate, radius: alarmDistance)
        } else {
            print("🗺️ updateUIView no selected destination available")
        }
    }

    private func updateMapUI(_ mapView: MKMapView) {
        // Update tracking mode
        if mapState == .noInput && !userHasInteractedWithMap {
            mapView.setUserTrackingMode(.follow, animated: true)
        }

        // Update UI elements visibility
        let shouldShowUI = mapState != .noInput
        mapView.showsCompass = shouldShowUI
        mapView.showsScale = shouldShowUI
    }
}

extension MapViewRepresentable {
    class MapCoordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        let parent: MapViewRepresentable
        private var circleOverlay: MKCircle?
        private var userToDestinationLine: MKPolyline?
        var isFollowingUser: Binding<Bool>

        init(parent: MapViewRepresentable, isFollowingUser: Binding<Bool>) {
            self.parent = parent
            self.isFollowingUser = isFollowingUser
            super.init()

            NotificationCenter.default.addObserver(
                self, selector: #selector(handleUpdateCircle(_:)), name: .updateCircle, object: nil)
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleClearMapOverlays(_:)), name: .clearMapOverlays,
                object: nil)
            NotificationCenter.default.addObserver(
                self, selector: #selector(centerOnUserLocation), name: .centerOnUserLocation,
                object: nil)
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleUserLocationChanged(_:)),
                name: .userLocationChanged,
                object: nil)
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleFitMapToUserAndDestination(_:)),
                name: .fitMapToUserAndDestination,
                object: nil)
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleAddDestinationAnnotation(_:)),
                name: .addDestinationAnnotation,
                object: nil)
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleLocationSelected(_:)),
                name: .locationSelected,
                object: nil)
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleUpdateTrafficVisibility(_:)),
                name: .updateTrafficVisibility,
                object: nil)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
            cleanup()
        }

        @objc func handleUpdateTrafficVisibility(_ notification: Notification) {
            if let enabled = notification.userInfo?["enabled"] as? Bool {
                if let std = parent.mapView.preferredConfiguration as? MKStandardMapConfiguration {
                    std.showsTraffic = enabled
                    parent.mapView.preferredConfiguration = std
                }
            }
        }

        private func cleanup() {
            clearOverlays()
        }

        private func clearOverlays() {
            parent.mapView.removeOverlays(parent.mapView.overlays)
            circleOverlay = nil
            userToDestinationLine = nil
        }

        @objc func handleUpdateCircle(_ notification: Notification) {
            print("🗺️ MAP: Received updateCircle notification")
            print("   📍 UserInfo: \(notification.userInfo ?? [:])")

            if let userInfo = notification.userInfo,
                let coordinate = userInfo["coordinate"] as? CLLocationCoordinate2D,
                let radius = userInfo["radius"] as? Double
            {
                print("✅ MAP: Updating overlays with coordinate: \(coordinate), radius: \(radius)")
                updateOverlays(for: coordinate, radius: radius)
            } else {
                print("❌ MAP: Invalid userInfo in updateCircle notification")
            }
        }

        @objc func handleClearMapOverlays(_ notification: Notification) {
            print("🗺️ Clearing all map overlays")
            clearOverlays()
        }

        @objc func handleUserLocationChanged(_ notification: Notification) {
            // Refresh polyline when user location changes to maintain accuracy
            if parent.locationViewModel.selectedSnoozeLaneLocation != nil {
                DispatchQueue.main.async {
                    self.updateUserToDestinationLine()
                }
            }
        }

        @objc func handleFitMapToUserAndDestination(_ notification: Notification) {
            // Fit map to show both user location and selected destination
            DispatchQueue.main.async {
                self.fitMapToUserAndDestination()
            }
        }

        @objc func handleAddDestinationAnnotation(_ notification: Notification) {
            print("🗺️ MAP: Received addDestinationAnnotation notification")
            print("   📍 UserInfo: \(notification.userInfo ?? [:])")

            // Add destination annotation to the map
            guard let userInfo = notification.userInfo,
                let coordinate = userInfo["coordinate"] as? CLLocationCoordinate2D,
                let title = userInfo["title"] as? String,
                let subtitle = userInfo["subtitle"] as? String
            else {
                print("❌ MAP: Invalid userInfo in addDestinationAnnotation notification")
                return
            }

            print("✅ MAP: Adding destination annotation:")
            print("   📍 Title: \(title)")
            print("   📍 Subtitle: \(subtitle)")
            print("   📍 Coordinate: \(coordinate)")

            DispatchQueue.main.async {
                // Clear existing annotations first
                self.parent.mapView.removeAnnotations(self.parent.mapView.annotations)
                print("🗑️ MAP: Cleared existing annotations")

                // Add new destination annotation
                self.parent.mapState = .locationSelected
                print("🔄 MAP: Updated mapState to .locationSelected")

                // Add new destination annotation
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = title
                annotation.subtitle = subtitle
                self.parent.mapView.addAnnotation(annotation)
                print("📍 MAP: Added destination annotation to map")

                // Select the annotation to show callout
                self.parent.mapView.selectAnnotation(annotation, animated: true)
                print("🎯 MAP: Selected annotation with callout")
            }
        }

        @objc func handleLocationSelected(_ notification: Notification) {
            print("🗺️ MAP: Received locationSelected notification")
            // Update map state to locationSelected
            DispatchQueue.main.async {
                print("🔄 MAP: Updating mapState to .locationSelected")
                self.parent.mapState = .locationSelected
                print("✅ MAP: mapState updated to .locationSelected")

                // Ensure overlays are drawn and map is fitted even if other notifications are missed
                if let coordinate = self.parent.locationViewModel.selectedSnoozeLaneLocation?
                    .coordinate
                {
                    self.updateOverlays(for: coordinate, radius: self.parent.alarmDistance)

                    // If no destination annotations exist, add one for clarity
                    if self.parent.mapView.annotations.filter({ !($0 is MKUserLocation) }).isEmpty {
                        self.addAndSelectAnnotation(withCoordinate: coordinate)
                    }

                    self.fitMapToUserAndDestination()
                } else {
                    print("⚠️ MAP: No selectedSnoozeLaneLocation when locationSelected received")
                }
            }
        }

        @objc func centerOnUserLocation() {
            parent.mapView.setUserTrackingMode(.follow, animated: true)
            isFollowingUser.wrappedValue = true

            // Refresh polyline to ensure it's accurate with current user location
            if parent.locationViewModel.selectedSnoozeLaneLocation != nil {
                updateUserToDestinationLine()
            }
        }

        func updateOverlays(for coordinate: CLLocationCoordinate2D, radius: Double) {
            print("🗺️ updateOverlays called with coordinate: \(coordinate), radius: \(radius)")
            // Update circle overlay
            if let existingOverlay = circleOverlay {
                parent.mapView.removeOverlay(existingOverlay)
            }
            let circle = MKCircle(center: coordinate, radius: radius)
            parent.mapView.addOverlay(circle)
            circleOverlay = circle

            // Update user to destination line
            updateUserToDestinationLine()
        }

        private func updateUserToDestinationLine() {
            if let existingLine = userToDestinationLine {
                parent.mapView.removeOverlay(existingLine)
            }

            // Resolve user coordinate: prefer MapKit blue-pin coordinate, fallback to LocationManager
            let mapUserLocation = parent.mapView.userLocation.coordinate
            guard let destination = parent.locationViewModel.selectedSnoozeLaneLocation?.coordinate
            else {
                print("⚠️ Destination not available - skipping polyline creation")
                return
            }

            // Determine a valid start coordinate
            var startCoordinate: CLLocationCoordinate2D? = nil
            if CLLocationCoordinate2DIsValid(mapUserLocation)
                && !(abs(mapUserLocation.latitude) < 0.0001
                    && abs(mapUserLocation.longitude) < 0.0001)
            {
                startCoordinate = mapUserLocation
                print("👤 Using MapKit userLocation for polyline start: \(mapUserLocation)")
            } else if let managerCoord = parent.locationManager.location?.coordinate,
                CLLocationCoordinate2DIsValid(managerCoord)
            {
                startCoordinate = managerCoord
                print(
                    "👤 Using LocationManager coordinate for polyline start (fallback): \(managerCoord)"
                )
            }

            guard let resolvedStart = startCoordinate, CLLocationCoordinate2DIsValid(destination)
            else {
                print(
                    "⚠️ Could not resolve a valid user start coordinate; skipping polyline creation")
                return
            }

            let endCoordinate = CLLocationCoordinate2D(
                latitude: destination.latitude, longitude: destination.longitude)

            let polyline = MKPolyline(coordinates: [resolvedStart, endCoordinate], count: 2)
            parent.mapView.addOverlay(polyline)
            userToDestinationLine = polyline

            // Debug: Log polyline coordinates for verification
            print("🔄 POLYLINE UPDATED:")
            print("   📍 Start (User): \(resolvedStart.latitude), \(resolvedStart.longitude)")
            print("   🎯 End (Destination): \(endCoordinate.latitude), \(endCoordinate.longitude)")
            print(
                "   📏 Distance: \(CLLocation(latitude: resolvedStart.latitude, longitude: resolvedStart.longitude).distance(from: CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude))) meters"
            )
        }

        @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
            // Prevent selecting a new destination while trip is in progress
            if parent.mapState == .tripInProgress { return }
            if gestureRecognizer.state != .began { return }

            let location = gestureRecognizer.location(in: parent.mapView)
            let coordinate = parent.mapView.convert(location, toCoordinateFrom: parent.mapView)

            // Provide haptic feedback
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
            feedbackGenerator.impactOccurred(intensity: 100)

            // Clear existing annotations and overlays
            clearOverlays()
            parent.mapView.removeAnnotations(parent.mapView.annotations)

            // Add new annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            parent.mapView.addAnnotation(annotation)

            // Update state and reverse geocode
            parent.mapState = .locationSelected
            parent.locationViewModel.reverseGeocodeLocation(coordinate) { [weak self] address in
                guard let self = self else { return }
                let title = address ?? "Selected Location"
                self.parent.locationViewModel.selectedSnoozeLaneLocation = SnoozeLaneLocation(
                    title: title,
                    subtitle: nil,
                    coordinate: coordinate,
                    placemark: MKPlacemark(coordinate: coordinate)
                )

                // Update overlays and fit map
                DispatchQueue.main.async {
                    self.updateOverlays(for: coordinate, radius: self.parent.alarmDistance)
                    self.fitMapToUserAndDestination()
                }
            }
        }

        @objc func handleDoubleTap(gestureRecognizer: UITapGestureRecognizer) {
            // Clear all overlays and recenter on user location
            clearOverlays()
            parent.mapView.removeAnnotations(parent.mapView.annotations)

            // Reset state
            parent.mapState = .noInput
            parent.locationViewModel.selectedSnoozeLaneLocation = nil

            // Recenter on user location
            if let userLocation = parent.locationManager.location?.coordinate {
                let region = MKCoordinateRegion(
                    center: userLocation,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
                parent.mapView.setRegion(region, animated: true)

                // Set user tracking mode to follow
                parent.mapView.setUserTrackingMode(.follow, animated: true)
                isFollowingUser.wrappedValue = true
                parent.userHasInteractedWithMap = false
            }

            // Provide haptic feedback
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
            feedbackGenerator.impactOccurred()
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if let featureAnnotation = annotation as? MKMapFeatureAnnotation {
                let identifier = "mapFeature"
                var view =
                    mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    as? MKMarkerAnnotationView

                if view == nil {
                    view = MKMarkerAnnotationView(
                        annotation: featureAnnotation, reuseIdentifier: identifier)
                }

                view?.annotation = featureAnnotation
                view?.canShowCallout = true
                view?.markerTintColor = .orange

                if let iconStyle = featureAnnotation.iconStyle {
                    view?.glyphImage = iconStyle.image
                }

                return view
            }

            // Handle custom annotations
            let identifier = "customAnnotation"
            var annotationView =
                mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(
                    annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            annotationView?.markerTintColor = .orange
            annotationView?.glyphImage = UIImage(systemName: "bus.fill")
            annotationView?.glyphTintColor = .white

            return annotationView
        }

        func enableFollowMode() {
            parent.mapView.userTrackingMode = .follow
            parent.userHasInteractedWithMap = false

            // Refresh polyline when entering follow mode to ensure accuracy
            if parent.locationViewModel.selectedSnoozeLaneLocation != nil {
                updateUserToDestinationLine()
            }
        }

        func fitMapToUserAndDestination() {
            // Use MapKit user coordinate; fallback to LocationManager if needed
            var userLocation = parent.mapView.userLocation.coordinate
            if !CLLocationCoordinate2DIsValid(userLocation)
                || (abs(userLocation.latitude) < 0.0001 && abs(userLocation.longitude) < 0.0001)
            {
                if let managerCoord = parent.locationManager.location?.coordinate {
                    userLocation = managerCoord
                    print("👤 fitMap fallback using LocationManager coordinate: \(managerCoord)")
                }
            }
            guard let destination = parent.locationViewModel.selectedSnoozeLaneLocation?.coordinate
            else { return }

            let tempPolyline = MKPolyline(coordinates: [userLocation, destination], count: 2)
            let boundingRect = tempPolyline.boundingMapRect
            let edgePadding = UIEdgeInsets(top: 100, left: 100, bottom: 300, right: 100)
            parent.mapView.setVisibleMapRect(boundingRect, edgePadding: edgePadding, animated: true)

            parent.mapView.userTrackingMode = .none
        }

        func addAndSelectAnnotation(withCoordinate coordinate: CLLocationCoordinate2D) {
            parent.mapView.removeAnnotations(parent.mapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            parent.mapView.addAnnotation(annotation)
            parent.mapView.selectAnnotation(annotation, animated: true)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let circleRenderer = MKCircleRenderer(overlay: circleOverlay)
                circleRenderer.strokeColor = UIColor.systemOrange
                circleRenderer.fillColor = UIColor.systemOrange.withAlphaComponent(0.2)
                circleRenderer.lineWidth = 2
                return circleRenderer
            } else if let polyline = overlay as? MKPolyline {
                let polylineRenderer = MKPolylineRenderer(overlay: polyline)
                polylineRenderer.strokeColor = UIColor.systemBlue
                polylineRenderer.lineWidth = 3
                return polylineRenderer
            }
            return MKOverlayRenderer()
        }

        // MARK: - MapCoordinator
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.userHasInteractedWithMap = true
            // If not following user, set isFollowingUser to false
            if mapView.userTrackingMode != .follow {
                isFollowingUser.wrappedValue = false
            }
        }

        // Handle map feature selection through standard annotation selection
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            if let placemark = annotation.subtitle {
                // Create a map item from the selected annotation
                let item = MKMapItem(placemark: MKPlacemark(coordinate: annotation.coordinate))
                item.name = annotation.title ?? ""

                parent.selectedMapItem = item
                parent.showingDetails = true
            }
        }

    }
}
