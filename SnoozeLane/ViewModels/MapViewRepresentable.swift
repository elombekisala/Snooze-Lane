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
        config.emphasisStyle = .default
        config.showsTraffic = false

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
        // Update map type if changed
        if uiView.mapType != mapType {
            uiView.mapType = mapType
        }

        // Update UI elements based on map state
        updateMapUI(uiView)

        // Update overlays if location is selected
        if let coordinate = locationViewModel.selectedSnoozeLaneLocation?.coordinate {
            context.coordinator.updateOverlays(for: coordinate, radius: alarmDistance)
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
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
            cleanup()
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
            if let userInfo = notification.userInfo,
                let coordinate = userInfo["coordinate"] as? CLLocationCoordinate2D,
                let radius = userInfo["radius"] as? Double
            {
                updateOverlays(for: coordinate, radius: radius)
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

        @objc func centerOnUserLocation() {
            parent.mapView.setUserTrackingMode(.follow, animated: true)
            isFollowingUser.wrappedValue = true

            // Refresh polyline to ensure it's accurate with current user location
            if parent.locationViewModel.selectedSnoozeLaneLocation != nil {
                updateUserToDestinationLine()
            }
        }

        func updateOverlays(for coordinate: CLLocationCoordinate2D, radius: Double) {
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

            // Get the exact coordinate that MapKit is using for the visual blue user location pin
            let mapUserLocation = parent.mapView.userLocation.coordinate
            guard let destination = parent.locationViewModel.selectedSnoozeLaneLocation?.coordinate
            else {
                print("⚠️ Destination not available - skipping polyline creation")
                return
            }

            // Validate coordinates to ensure they are valid
            guard
                CLLocationCoordinate2DIsValid(mapUserLocation)
                    && CLLocationCoordinate2DIsValid(destination)
            else {
                print("⚠️ Invalid coordinates detected - skipping polyline creation")
                return
            }

            // Use the exact MapKit user location coordinate for perfect alignment with the blue pin
            let startCoordinate = CLLocationCoordinate2D(
                latitude: mapUserLocation.latitude,
                longitude: mapUserLocation.longitude
            )

            let endCoordinate = CLLocationCoordinate2D(
                latitude: destination.latitude,
                longitude: destination.longitude
            )

            let polyline = MKPolyline(coordinates: [startCoordinate, endCoordinate], count: 2)
            parent.mapView.addOverlay(polyline)
            userToDestinationLine = polyline

            // Debug: Log polyline coordinates for verification
            print("🔄 POLYLINE UPDATED:")
            print("   📍 Start (User): \(startCoordinate.latitude), \(startCoordinate.longitude)")
            print("   🎯 End (Destination): \(endCoordinate.latitude), \(endCoordinate.longitude)")
            print(
                "   📏 Distance: \(CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude).distance(from: CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude))) meters"
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
            // Use the exact MapKit user location coordinate for perfect alignment
            let userLocation = parent.mapView.userLocation.coordinate
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
