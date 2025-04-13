import Foundation
import MapKit

class SnoozeLaneLocation: NSObject, MKAnnotation {
    
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let placemark: CLPlacemark
    
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    
    init(title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D, placemark: CLPlacemark) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.placemark = placemark
    }
    
    init(title: String?, subtitle: String?, location: CLLocation, placemark: CLPlacemark) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = location.coordinate
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.placemark = placemark
    }
    
    convenience init(title: String?, subtitle: String?, latitude: CLLocationDegrees, longitude: CLLocationDegrees, placemark: CLPlacemark) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.init(title: title, subtitle: subtitle, coordinate: coordinate, placemark: placemark)
    }
    
    func setLocation(_ location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
}
