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
        mapView.addGestureRecognizer(longPressGesture)

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

        @objc func centerOnUserLocation() {
            parent.mapView.setUserTrackingMode(.follow, animated: true)
            isFollowingUser.wrappedValue = true
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
        
        // Set up continuous polyline updates when user location changes
        setupContinuousPolylineUpdates()
    }

        private func updateUserToDestinationLine() {
            if let existingLine = userToDestinationLine {
                parent.mapView.removeOverlay(existingLine)
            }

            guard let userLocation = parent.locationManager.location?.coordinate,
                let destination = parent.locationViewModel.selectedSnoozeLaneLocation?.coordinate
            else { return }

            // Always use the most current user location for the polyline start
            let polyline = MKPolyline(coordinates: [userLocation, destination], count: 2)
            parent.mapView.addOverlay(polyline)
            userToDestinationLine = polyline
            
            // Debug: Log polyline coordinates for verification
            print("🔄 POLYLINE UPDATED:")
            print("   📍 Start (User): \(userLocation.latitude), \(userLocation.longitude)")
            print("   🎯 End (Destination): \(destination.latitude), \(destination.longitude)")
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
        }

        func fitMapToUserAndDestination() {
            guard let userLocation = parent.locationManager.location?.coordinate,
                let destination = parent.locationViewModel.selectedSnoozeLaneLocation?.coordinate
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
        
        // MARK: - Continuous Polyline Updates
        private func setupContinuousPolylineUpdates() {
            // Remove existing notification observer to avoid duplicates
            NotificationCenter.default.removeObserver(self, name: .didUpdateLocation, object: nil)
            
            // Add notification observer for location updates
            NotificationCenter.default.addObserver(
                forName: .didUpdateLocation,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                // Update polyline whenever user location changes
                self?.updateUserToDestinationLine()
            }
        }
        

    }
}
