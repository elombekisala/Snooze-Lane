import SwiftUI
import MapKit
import Combine

class LocationSearchViewModel: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    @Published public var currentLocation: CLLocation?
    @Published var formattedDistance: String = ""
    
    @Published var results = [MKLocalSearchCompletion]()
    @Published var selectedSnoozeLaneLocation: SnoozeLaneLocation?
    
    @Published var pickUpTime: String?
    @Published var dropOffTime: String?
    
    @Published var showAlarmOptionsView = false
    @Published var showProgressView = false
    
    @Published var estimatedRestTime: TimeInterval?
    
    @ObservedObject var locationManager: LocationManager
    
    @Published public var distance: Double? {
        didSet {
            if let distance = distance {
                locationManager.location?.distance(from: CLLocation(latitude: selectedSnoozeLaneLocation?.latitude ?? 0, longitude: selectedSnoozeLaneLocation?.longitude ?? 0))
            }
        }
    }
    
    var destinationRoute: MKRoute?
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.locationSearchViewModel = self
        self.locationManager.objectWillChange.sink { [weak self] _ in
            self?.locationUpdated()
        }.store(in: &cancellables)
        searchCompleter.delegate = self
    }
    
    private let searchCompleter = MKLocalSearchCompleter()
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Helpers
    
    var queryFragment: String = "" {
        didSet {
            searchCompleter.queryFragment = queryFragment
        }
    }
    
    func search(queryFragment: String) {
        searchCompleter.queryFragment = queryFragment
    }
    
    func getCurrentLocation() -> CLLocation? {
        return currentLocation
    }
    
    func locationSearch(forLocalSearchCompletion localSearch: MKLocalSearchCompletion, completion: @escaping MKLocalSearch.CompletionHandler) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = localSearch.title + " " + localSearch.subtitle
        let search = MKLocalSearch(request: searchRequest)
        
        search.start(completionHandler: completion)
    }
    
    func selectLocation(_ localSearch: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: localSearch)
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Location search failed with error \(error.localizedDescription)")
                return
            }
            
            guard let item = response?.mapItems.first else { return }
            let coordinate = item.placemark.coordinate
            self.selectedSnoozeLaneLocation = SnoozeLaneLocation(title: localSearch.title, subtitle: localSearch.subtitle, coordinate: coordinate, placemark: item.placemark)
            
            print("DEBUG: Location coordinates \(coordinate)")
            
            if let selectedSnoozeLaneLocation = self.selectedSnoozeLaneLocation, let currentLocation = self.getCurrentLocation() {
                let sourceCoordinate = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
                let destinationCoordinate = CLLocationCoordinate2D(latitude: selectedSnoozeLaneLocation.latitude, longitude: selectedSnoozeLaneLocation.longitude)
                
                self.getDestinationRoute(from: sourceCoordinate, to: destinationCoordinate) { route, distance, error in
                    if let error = error {
                        print("DEBUG: Failed to get destination route with error \(error.localizedDescription)")
                        return
                    }
                    guard let route = route, let distance = distance else { return }
                    
                    let destination = CLLocation(latitude: route.polyline.coordinate.latitude, longitude: route.polyline.coordinate.longitude)
                    
                    self.distance = distance
                    
                    self.destinationRoute = route
                    self.locationUpdated()
                }
            }
        }
    }
    
    
    func locationUpdated() {
        guard let currentLocation = locationManager.location,
              let destination = selectedSnoozeLaneLocation else { return }
        
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let distanceInMeters = currentLocation.distance(from: destinationLocation)
        distance = distanceInMeters
        formattedDistance = formatDistance(distanceInMeters)
        print("Calculated distance: \(formattedDistance)")
        
        // Fetch estimated rest time based on Apple Maps API data
        fetchEstimatedRestTime(from: currentLocation.coordinate, to: destinationLocation.coordinate)
        
        // Set the estimated rest time in the locationManager
        if let destinationRoute = destinationRoute {
            locationManager.location = CLLocation(latitude: destinationRoute.polyline.coordinate.latitude, longitude: destinationRoute.polyline.coordinate.longitude)
        }
    }
    
    func fetchEstimatedRestTime(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
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
    
    
    func getDestinationRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (_ route: MKRoute?, _ distance: CLLocationDistance?, _ error: Error?) -> Void) {
        
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
    
    func formattedDistanceString() -> String? {
        if let distance = distance {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            if let formattedString = formatter.string(from: NSNumber(value: distance)) {
                formattedDistance = formattedString + " m"
                return formattedDistance
            }
        }
        return nil
    }
    
    func configurePickUpAndDropOffTime(with expectedTravelTime: Double) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        
        pickUpTime = formatter.string(from: Date())
        dropOffTime = formatter.string(from: Date() + expectedTravelTime)
    }
    
    func formatDistance(_ distanceInMeters: Double) -> String {
        let distanceInMiles = distanceInMeters / 1609.34
        let distanceInFeet = distanceInMeters * 3.28084
        
        if distanceInMiles < 0.1 {
            let formatterFeet = NumberFormatter()
            formatterFeet.numberStyle = .decimal
            formatterFeet.maximumFractionDigits = 0
            
            if let formattedStringFeet = formatterFeet.string(from: NSNumber(value: distanceInFeet)) {
                return formattedStringFeet + " ft"
            } else {
                return "N/A"
            }
        } else {
            let formatterMiles = NumberFormatter()
            formatterMiles.numberStyle = .decimal
            formatterMiles.maximumFractionDigits = 2
            
            if let formattedStringMiles = formatterMiles.string(from: NSNumber(value: distanceInMiles)) {
                return formattedStringMiles + " mi"
            } else {
                return "N/A"
            }
        }
    }
    
    func reverseGeocodeLocation(_ coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Error in reverse geocoding: \(error.localizedDescription)")
                completion(nil) // Reverse geocoding failed
                return
            }
            
            if let placemark = placemarks?.first {
                let address = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                completion(address)
            } else {
                completion(nil) // No placemark found
            }
        }
    }
}

// MARK: MKlocalSearchCompleterDelegate

extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Failed to find search results with error: \(error.localizedDescription)")
    }
}
