import MapKit
import SwiftUI

struct MapViewRepresentable: UIViewRepresentable {
    let mapView = MKMapView()

    // Bindings to manage state between SwiftUI and UIKit
    @Binding var selectedMapItem: MKMapItem?
    @Binding var showingDetails: Bool
    @Binding var mapState: MapViewState
    @Binding var userHasInteractedWithMap: Bool
    @Binding var alarmDistance: Double
    @Binding var mapType: MKMapType

    // New state for Look Around
    @State private var lookAroundScene: MKLookAroundScene?

    // EnvironmentObjects to access shared data
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var locationViewModel: LocationSearchViewModel

    func makeCoordinator() -> MapCoordinator {
        return MapCoordinator(parent: self)
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

        // Clean up existing resources
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)

        // Reset user tracking if needed
        if mapState == .noInput {
            uiView.setUserTrackingMode(.follow, animated: true)
            userHasInteractedWithMap = false
        }

        if let coordinate = locationViewModel.selectedSnoozeLaneLocation?.coordinate {
            context.coordinator.updateCircleOverlay(
                withCoordinate: coordinate,
                radius: alarmDistance)
            context.coordinator.updateUserToDestinationLine()

            // Add Look Around scene for the selected location
            Task {
                await addLookAroundPreview(for: coordinate)
            }
        }

        // Update compass and scale bar visibility based on map state
        uiView.showsCompass = mapState != .noInput
        uiView.showsScale = mapState != .noInput
    }

    // New function to handle Look Around scene request
    private func addLookAroundPreview(for coordinate: CLLocationCoordinate2D) async {
        let sceneRequest = MKLookAroundSceneRequest(coordinate: coordinate)
        do {
            lookAroundScene = try await sceneRequest.scene
        } catch {
            print("Error fetching Look Around scene: \(error.localizedDescription)")
        }
    }

    // Cleanup method for Look Around scene
    private func cleanupLookAroundScene() {
        lookAroundScene = nil
    }
}

extension MapViewRepresentable {
    class MapCoordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        let parent: MapViewRepresentable
        var circleOverlay: MKCircle?
        var userToDestinationLine: MKPolyline?

        init(parent: MapViewRepresentable) {
            self.parent = parent
            super.init()

            NotificationCenter.default.addObserver(
                self, selector: #selector(handleUpdateCircle(_:)), name: .updateCircle, object: nil)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
            cleanup()
        }

        private func cleanup() {
            if let circle = circleOverlay {
                parent.mapView.removeOverlay(circle)
                circleOverlay = nil
            }

            if let line = userToDestinationLine {
                parent.mapView.removeOverlay(line)
                userToDestinationLine = nil
            }

            parent.cleanupLookAroundScene()
        }

        @objc func handleUpdateCircle(_ notification: Notification) {
            if let userInfo = notification.userInfo,
                let coordinate = userInfo["coordinate"] as? CLLocationCoordinate2D,
                let radius = userInfo["radius"] as? Double
            {
                updateCircleOverlay(withCoordinate: coordinate, radius: radius)
            }
        }

        func updateCircleOverlay(withCoordinate coordinate: CLLocationCoordinate2D, radius: Double)
        {
            // Ensure that the circle overlay is always updated, no matter the map state
            if let existingOverlay = circleOverlay {
                parent.mapView.removeOverlay(existingOverlay)
            }
            let circle = MKCircle(center: coordinate, radius: radius)
            parent.mapView.addOverlay(circle)
            circleOverlay = circle
        }

        @objc func handleUserInteraction(_ gesture: UIGestureRecognizer) {
            if gesture.state == .began || gesture.state == .changed || gesture.state == .ended {
                print("User interaction detected with gesture: \(gesture.state)")
                if parent.mapState != .noInput {
                    parent.userHasInteractedWithMap = true
                    parent.mapView.userTrackingMode = .none
                    print("User tracking mode set to none due to user interaction.")
                }
            }
        }

        @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
            if gestureRecognizer.state != .began { return }

            let location = gestureRecognizer.location(in: parent.mapView)
            let coordinate = parent.mapView.convert(location, toCoordinateFrom: parent.mapView)

            // Provide haptic feedback for the long press
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
            feedbackGenerator.impactOccurred(intensity: 100)

            // Clear existing annotations and overlays
            parent.mapView.removeAnnotations(parent.mapView.annotations)
            parent.mapView.removeOverlays(parent.mapView.overlays)

            // Add new annotation at the pressed location
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            parent.mapView.addAnnotation(annotation)

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

                // Update circle overlay and user-to-destination line
                DispatchQueue.main.async {
                    self.updateCircleOverlay(
                        withCoordinate: coordinate, radius: self.parent.alarmDistance)
                    self.updateUserToDestinationLine()
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

            let polyline = MKPolyline(coordinates: [userLocation, destination], count: 2)
            parent.mapView.removeOverlays(parent.mapView.overlays)  // Remove existing overlays before adding a new one
            parent.mapView.addOverlay(polyline)

            // Calculate the bounding map rect to fit both locations with some padding
            let boundingRect = polyline.boundingMapRect
            let edgePadding = UIEdgeInsets(top: 100, left: 100, bottom: 300, right: 100)
            parent.mapView.setVisibleMapRect(boundingRect, edgePadding: edgePadding, animated: true)

            parent.mapView.userTrackingMode = .none
        }

        func updateUserToDestinationLine() {
            if let existingLine = userToDestinationLine {
                parent.mapView.removeOverlay(existingLine)
            }

            guard let userLocation = parent.locationManager.location?.coordinate,
                let destination = parent.locationViewModel.selectedSnoozeLaneLocation?.coordinate
            else { return }

            let polyline = MKPolyline(coordinates: [userLocation, destination], count: 2)
            parent.mapView.addOverlay(polyline)
            userToDestinationLine = polyline
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
