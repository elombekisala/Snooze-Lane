import Foundation
import CoreLocation

final class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation? = nil
    @Published var authorizationStatus: CLAuthorizationStatus? = nil
    @Published var showLocationDeniedAlert = false
    var userHasInteractedWithMap = false
    private let locationManager = CLLocationManager()
    private var lastProcessedLocation: CLLocation?
    private var lastProcessedTime: Date?
    private let minimumDistanceThreshold: CLLocationDistance = 30 // meters
    private let minimumTimeThreshold: TimeInterval = 60 // seconds
    private var calculatedDistance: Double = 0.0
    static let shared = LocationManager()
    
    weak var locationSearchViewModel: LocationSearchViewModel?
    
    var monitoredRegion: CLCircularRegion?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }
    
    func calculateDistance(to destination: CLLocationCoordinate2D) {
        guard let currentLocation = location else { return }
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        calculatedDistance = currentLocation.distance(from: destinationLocation)
    }
    
    func calculateDistanceToDestination(from location: CLLocation, to destination: CLLocationCoordinate2D) {
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        calculatedDistance = location.distance(from: destinationLocation)
    }
    
    func getCalculatedDistance() -> Double {
        return calculatedDistance
    }
    
    func startMonitoring(_ location: CLLocation, radius: Double = 500.0) {
        let region = CLCircularRegion(center: location.coordinate, radius: radius, identifier: "DestinationRegion")
        self.monitoredRegion = region
        locationManager.startMonitoring(for: region)
    }
    
    func stopMonitoring() {
        if let region = self.monitoredRegion {
            locationManager.stopMonitoring(for: region)
        }
        self.monitoredRegion = nil
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func updateMapRegion(with location: CLLocation) {
        NotificationCenter.default.post(name: .didUpdateLocation, object: location)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else if authorizationStatus == .denied {
            showLocationDeniedAlert = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let shouldProcessUpdate = lastProcessedLocation == nil ||
        location.distance(from: lastProcessedLocation!) > minimumDistanceThreshold ||
        Date().timeIntervalSince(lastProcessedTime!) > minimumTimeThreshold
        
        if shouldProcessUpdate {
            self.location = location
            self.lastProcessedLocation = location
            self.lastProcessedTime = Date()
            
            if !userHasInteractedWithMap {
                updateMapRegion(with: location)
            }
        }
    }
    
    func userInteractedWithMap() {
        userHasInteractedWithMap = true
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager did fail with error: \(error.localizedDescription)")
    }
}
