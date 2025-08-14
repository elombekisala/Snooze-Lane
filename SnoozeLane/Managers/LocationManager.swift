import CoreLocation
import Foundation

// MARK: - Location Manager
final class LocationManager: NSObject, ObservableObject {
    // MARK: - Properties
    @Published var location: CLLocation? = nil
    @Published var authorizationStatus: CLAuthorizationStatus? = nil
    @Published var showLocationDeniedAlert = false
    @Published var locationAccuracy: CLAccuracyAuthorization? = nil

    private let locationManager = CLLocationManager()
    private var lastProcessedLocation: CLLocation?
    private var lastProcessedTime: Date?
    private var minimumDistanceThreshold: CLLocationDistance = 30  // meters
    private var minimumTimeThreshold: TimeInterval = 60  // seconds
    private var calculatedDistance: Double = 0.0

    var userHasInteractedWithMap = false
    var monitoredRegion: CLCircularRegion?
    weak var locationSearchViewModel: LocationSearchViewModel?

    static let shared = LocationManager()

    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .otherNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true

        // Request authorization
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Authorization
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Location Updates
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Distance Calculations
    private func calculateThresholds(for location: CLLocation) {
        let speed = location.speed
        if speed > 10 {  // Moving fast
            minimumDistanceThreshold = 50
            minimumTimeThreshold = 30
        } else {  // Moving slow or stationary
            minimumDistanceThreshold = 30
            minimumTimeThreshold = 60
        }
    }

    func calculateDistance(to destination: CLLocationCoordinate2D) {
        guard let currentLocation = location else { return }
        let destinationLocation = CLLocation(
            latitude: destination.latitude, longitude: destination.longitude)
        calculatedDistance = currentLocation.distance(from: destinationLocation)
    }

    func calculateDistanceToDestination(
        from location: CLLocation, to destination: CLLocationCoordinate2D
    ) {
        let destinationLocation = CLLocation(
            latitude: destination.latitude, longitude: destination.longitude)
        calculatedDistance = location.distance(from: destinationLocation)
    }

    func getCalculatedDistance() -> Double {
        return calculatedDistance
    }

    // MARK: - Region Monitoring
    func startMonitoring(_ location: CLLocation, radius: Double = 500.0) {
        let region = CLCircularRegion(
            center: location.coordinate, radius: radius, identifier: "DestinationRegion")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        self.monitoredRegion = region
        locationManager.startMonitoring(for: region)
    }

    func stopMonitoring() {
        if let region = self.monitoredRegion {
            locationManager.stopMonitoring(for: region)
        }
        self.monitoredRegion = nil
    }

    // MARK: - Map Management
    func clearMapElements() {
        stopMonitoring()
        userHasInteractedWithMap = false
        NotificationCenter.default.post(name: .didClearMapElements, object: nil)
    }

    func centerOnUserLocation() {
        guard let currentLocation = location else { return }
        updateMapRegion(with: currentLocation)
    }

    func updateMapRegion(with location: CLLocation) {
        NotificationCenter.default.post(name: .didUpdateLocation, object: location)
    }

    func userInteractedWithMap() {
        userHasInteractedWithMap = true
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        locationAccuracy = manager.accuracyAuthorization

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if manager.accuracyAuthorization == .fullAccuracy {
                locationManager.startUpdatingLocation()
            } else {
                // Handle reduced accuracy
                print("⚠️ Precise location access not granted")
                // You might want to show an alert or message to the user
            }
        case .denied, .restricted:
            showLocationDeniedAlert = true
            stopUpdatingLocation()
        case .notDetermined:
            requestAuthorization()
        @unknown default:
            print("⚠️ Unknown authorization status")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Update thresholds based on movement
        calculateThresholds(for: location)

        let shouldProcessUpdate =
            lastProcessedLocation == nil
            || location.distance(from: lastProcessedLocation!) > minimumDistanceThreshold
            || Date().timeIntervalSince(lastProcessedTime!) > minimumTimeThreshold

        if shouldProcessUpdate {
            self.location = location
            self.lastProcessedLocation = location
            self.lastProcessedTime = Date()

            if !userHasInteractedWithMap {
                updateMapRegion(with: location)
            }

            // Notify that location has changed significantly to refresh polyline
            NotificationCenter.default.post(name: .userLocationChanged, object: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError {
            switch error.code {
            case .denied:
                showLocationDeniedAlert = true
                print("🚫 Location access denied")
            case .locationUnknown:
                print("📍 Location unknown, waiting for update")
            case .promptDeclined:
                print("❌ Location prompt declined by user")
            case .rangingUnavailable:
                print("⚠️ Ranging unavailable")
            default:
                print("⚠️ Other Core Location error: \(error.localizedDescription)")
            }
        } else {
            print("❌ Other error: \(error.localizedDescription)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == "DestinationRegion" {
            NotificationCenter.default.post(name: .didEnterDestinationRegion, object: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == "DestinationRegion" {
            NotificationCenter.default.post(name: .didExitDestinationRegion, object: nil)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didEnterDestinationRegion = Notification.Name("didEnterDestinationRegion")
    static let didExitDestinationRegion = Notification.Name("didExitDestinationRegion")
    static let userLocationChanged = Notification.Name("userLocationChanged")
}
