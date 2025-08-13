import Combine
import MapKit
import SwiftUI

class LocationSearchViewModel: NSObject, ObservableObject {

    // MARK: - Properties

    @Published public var currentLocation: CLLocation?
    @Published var formattedDistance: String = ""

    @Published var results = [MKLocalSearchCompletion]()
    @Published var selectedSnoozeLaneLocation: SnoozeLaneLocation?
    
    // Store coordinates for each search result as they're fetched
    private var resultCoordinates: [String: CLLocationCoordinate2D] = [:]
    
    // Get stored coordinates for a specific search result
    func getCoordinateForResult(_ result: MKLocalSearchCompletion) -> CLLocationCoordinate2D? {
        let resultKey = "\(result.title)_\(result.subtitle)"
        return resultCoordinates[resultKey]
    }

    @Published var pickUpTime: String?
    @Published var dropOffTime: String?

    @Published var showAlarmOptionsView = false
    @Published var showProgressView = false

    @Published var estimatedRestTime: TimeInterval?

    @ObservedObject var locationManager: LocationManager

    @Published public var distance: Double? {
        didSet {
            if let distance = distance {
                formattedDistance = formatDistance(distance)
            }
        }
    }

    var destinationRoute: MKRoute?

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        super.init()
        setupLocationManager()
        setupSearchCompleter()
    }

    private let searchCompleter = MKLocalSearchCompleter()
    private var cancellables: Set<AnyCancellable> = []

    private func setupLocationManager() {
        self.locationManager.locationSearchViewModel = self
        self.locationManager.objectWillChange.sink { [weak self] _ in
            self?.locationUpdated()
        }.store(in: &cancellables)
    }

    private func setupSearchCompleter() {
        searchCompleter.delegate = self
    }

    // MARK: - Search Management

    var queryFragment: String = "" {
        didSet {
            print("🔍 QUERY FRAGMENT CHANGED: '\(queryFragment)'")
            searchCompleter.queryFragment = queryFragment
        }
    }

    func search(queryFragment: String) {
        searchCompleter.queryFragment = queryFragment
    }

    // MARK: - Location Management

    func getCurrentLocation() -> CLLocation? {
        return currentLocation
    }

    public func clearMapElements() {
        destinationRoute = nil
        selectedSnoozeLaneLocation = nil
        distance = nil
        formattedDistance = ""
        estimatedRestTime = nil
        pickUpTime = nil
        dropOffTime = nil
        locationManager.clearMapElements()
    }

    public func centerOnUserLocation() {
        locationManager.centerOnUserLocation()
    }

    func locationUpdated() {
        guard let currentLocation = locationManager.location,
            let destination = selectedSnoozeLaneLocation
        else { return }

        let destinationLocation = CLLocation(
            latitude: destination.latitude, longitude: destination.longitude)
        let distanceInMeters = currentLocation.distance(from: destinationLocation)
        distance = distanceInMeters
        formattedDistance = formatDistance(distanceInMeters)
        #if DEBUG
            print("Calculated distance: \(formattedDistance)")
        #endif

        // Notify TripProgressViewModel of distance update
        NotificationCenter.default.post(
            name: .distanceUpdated,
            object: distanceInMeters
        )

        fetchEstimatedRestTime(from: currentLocation.coordinate, to: destinationLocation.coordinate)

        if let destinationRoute = destinationRoute {
            locationManager.location = CLLocation(
                latitude: destinationRoute.polyline.coordinate.latitude,
                longitude: destinationRoute.polyline.coordinate.longitude)
        }
    }

    // MARK: - Route Management

    func getDestinationRoute(
        from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D,
        completion: @escaping (_ route: MKRoute?, _ distance: CLLocationDistance?, _ error: Error?)
            -> Void
    ) {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile

        let directions = MKDirections(request: directionRequest)

        directions.calculate { (response, error) in
            guard let response = response else {
                completion(nil, nil, error)
                return
            }

            guard let route = response.routes.first else {
                completion(nil, nil, error)
                return
            }

            let distance = route.distance
            let expectedTravelTime = route.expectedTravelTime
            self.configurePickUpAndDropOffTime(with: expectedTravelTime)

            completion(route, distance, nil)
        }
    }

    // MARK: - Time Management

    func fetchEstimatedRestTime(
        from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D
    ) {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile

        let directions = MKDirections(request: directionRequest)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            directions.calculate { [weak self] (response, error) in
                guard let self = self else { return }

                if let error = error {
                    print("Failed to fetch estimated rest time: \(error.localizedDescription)")
                    self.estimatedRestTime = nil
                    return
                }

                guard let route = response?.routes.first else {
                    self.estimatedRestTime = nil
                    return
                }

                let travelTime = route.expectedTravelTime
                self.estimatedRestTime = travelTime
                print("Estimated rest time: \(travelTime) seconds")
            }
        }
    }

    func configurePickUpAndDropOffTime(with expectedTravelTime: Double) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"

        pickUpTime = formatter.string(from: Date())
        dropOffTime = formatter.string(from: Date() + expectedTravelTime)
    }

    // MARK: - Location Selection

    func selectLocation(_ localSearch: MKLocalSearchCompletion) {
        print("🔍 SEARCH RESULT SELECTED:")
        print("   📍 Title: \(localSearch.title)")
        print("   📍 Subtitle: \(localSearch.subtitle)")

        // Check if we already have coordinates for this result
        let resultKey = "\(localSearch.title)_\(localSearch.subtitle)"
        if let storedCoordinate = resultCoordinates[resultKey] {
            print("✅ Using stored coordinates for '\(localSearch.title)':")
            print("   📍 Lat: \(storedCoordinate.latitude)")
            print("   📍 Lon: \(storedCoordinate.longitude)")
            
            // Create the location directly with stored coordinates
            self.selectedSnoozeLaneLocation = SnoozeLaneLocation(
                title: localSearch.title,
                subtitle: localSearch.subtitle,
                coordinate: storedCoordinate,
                placemark: MKPlacemark(coordinate: storedCoordinate)
            )
            
            // Post notification to add destination annotation to the map
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .addDestinationAnnotation,
                    object: nil,
                    userInfo: [
                        "coordinate": storedCoordinate, "title": localSearch.title,
                        "subtitle": localSearch.subtitle,
                    ]
                )
            }
            
            // Get route if we have current location
            if let currentLocation = self.getCurrentLocation() {
                let sourceCoordinate = CLLocationCoordinate2D(
                    latitude: currentLocation.coordinate.latitude,
                    longitude: currentLocation.coordinate.longitude)
                let destinationCoordinate = CLLocationCoordinate2D(
                    latitude: storedCoordinate.latitude,
                    longitude: storedCoordinate.longitude)

                self.getDestinationRoute(from: sourceCoordinate, to: destinationCoordinate) {
                    route, distance, error in
                    if let error = error {
                        print("DEBUG: Failed to get destination route with error \(error.localizedDescription)")
                        return
                    }
                    guard let route = route, let distance = distance else { return }

                    self.distance = distance
                    self.destinationRoute = route
                    self.locationUpdated()
                }
            }
            
            return
        }
        
        // Fallback: If no stored coordinates, do the search (this shouldn't happen now)
        print("⚠️ No stored coordinates found, falling back to search...")
        let searchRequest = MKLocalSearch.Request(completion: localSearch)
        let search = MKLocalSearch(request: searchRequest)

        print("   🔄 Starting coordinate search...")
        print("   📍 Search request: \(searchRequest)")
        print("   📍 Search object: \(search)")
        print("   🔍 About to start search...")
        print("   🔍 Search isActive before start: \(search.isSearching)")

        // Add a timeout to detect if search is hanging
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            print("⏰ Search timeout - search may be hanging")
            print("⏰ Search isActive after timeout: \(search.isSearching)")
        }

        print("   🚀 About to call search.start()...")
        search.start { [weak self] response, error in
            print("🔄 Search completion handler called!")
            guard let self = self else {
                print("❌ Self is nil in completion handler")
                return
            }

            if let error = error {
                print("❌ Location search failed with error: \(error.localizedDescription)")
                print("❌ Error domain: \(error._domain)")
                print("❌ Error code: \(error._code)")
                return
            }

            print("📋 SEARCH RESPONSE RECEIVED:")
            print("   📍 Response items count: \(response?.mapItems.count ?? 0)")
            print("   📍 Response region: \(response?.boundingRegion)")

            guard let item = response?.mapItems.first else {
                print("❌ No map items found in search response")
                return
            }

            print("📍 MAP ITEM DETAILS:")
            print("   📍 Name: \(item.name ?? "N/A")")
            print("   📍 Placemark: \(item.placemark)")
            print("   📍 Coordinate: \(item.placemark.coordinate)")
            print("   📍 Country: \(item.placemark.country ?? "N/A")")
            print("   📍 Administrative Area: \(item.placemark.administrativeArea ?? "N/A")")
            print("   📍 Locality: \(item.placemark.locality ?? "N/A")")

            let coordinate = item.placemark.coordinate
            print("✅ COORDINATES EXTRACTED:")
            print("   📍 Latitude: \(coordinate.latitude)")
            print("   📍 Longitude: \(coordinate.longitude)")
            print("   📍 Full Coordinate: \(coordinate)")

            self.selectedSnoozeLaneLocation = SnoozeLaneLocation(
                title: localSearch.title,
                subtitle: localSearch.subtitle,
                coordinate: coordinate,
                placemark: item.placemark)

            // Post notification to add destination annotation to the map
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .addDestinationAnnotation,
                    object: nil,
                    userInfo: [
                        "coordinate": coordinate, "title": localSearch.title,
                        "subtitle": localSearch.subtitle,
                    ]
                )
            }

            if let selectedSnoozeLaneLocation = self.selectedSnoozeLaneLocation,
                let currentLocation = self.getCurrentLocation()
            {
                let sourceCoordinate = CLLocationCoordinate2D(
                    latitude: currentLocation.coordinate.latitude,
                    longitude: currentLocation.coordinate.longitude)
                let destinationCoordinate = CLLocationCoordinate2D(
                    latitude: selectedSnoozeLaneLocation.latitude,
                    longitude: selectedSnoozeLaneLocation.longitude)

                self.getDestinationRoute(from: sourceCoordinate, to: destinationCoordinate) {
                    route, distance, error in
                    if let error = error {
                        print(
                            "DEBUG: Failed to get destination route with error \(error.localizedDescription)"
                        )
                        return
                    }
                    guard let route = route, let distance = distance else { return }

                    self.distance = distance
                    self.destinationRoute = route
                    self.locationUpdated()
                }
            }
        }
    }

    // MARK: - Distance Formatting

    private func formatDistance(_ distance: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        let measurement = Measurement(value: distance, unit: UnitLength.meters)

        // Check user preference for units
        let useMetricUnits = UserDefaults.standard.bool(forKey: "useMetricUnits")

        if useMetricUnits {
            // Use kilometers for metric
            if distance >= 1000 {
                let kilometers = measurement.converted(to: .kilometers)
                return formatter.string(from: kilometers)
            } else {
                return formatter.string(from: measurement)
            }
        } else {
            // Use miles for imperial
            let miles = measurement.converted(to: .miles)
            return formatter.string(from: miles)
        }
    }

    // MARK: - Geocoding

    func reverseGeocodeLocation(
        _ coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void
    ) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Error in reverse geocoding: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let placemark = placemarks?.first {
                let address = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.country,
                ].compactMap { $0 }.joined(separator: ", ")
                completion(address)
            } else {
                completion(nil)
            }
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        print("🔍 SEARCH COMPLETER RESULTS UPDATED:")
        print("   📍 Results count: \(completer.results.count)")

        for (index, result) in completer.results.enumerated() {
            print("   📍 Result \(index + 1):")
            print("      📍 Title: \(result.title)")
            print("      📍 Subtitle: \(result.subtitle)")
            
            // Try to get coordinates for this completion
            let searchRequest = MKLocalSearch.Request(completion: result)
            let search = MKLocalSearch(request: searchRequest)
            
            print("      🔍 Getting coordinates for: \(result.title)")
            search.start { response, error in
                if let error = error {
                    print("      ❌ Error getting coordinates: \(error.localizedDescription)")
                    return
                }
                
                            if let item = response?.mapItems.first {
                let coordinate = item.placemark.coordinate
                print("      ✅ Coordinates for '\(result.title)':")
                print("         📍 Lat: \(coordinate.latitude)")
                print("         📍 Lon: \(coordinate.longitude)")
                
                // Store the coordinates for this result
                let resultKey = "\(result.title)_\(result.subtitle)"
                self.resultCoordinates[resultKey] = coordinate
            } else {
                print("      ❌ No coordinates found for: \(result.title)")
            }
            }
        }

        self.results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("❌ Failed to find search results with error: \(error.localizedDescription)")
    }
}
