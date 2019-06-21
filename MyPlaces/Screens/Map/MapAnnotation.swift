import MapKit

class MapAnnotation: NSObject, MKAnnotation {

    // MARK: - Public

    private(set) var place: Place
    
    var coordinate: CLLocationCoordinate2D {
        return place.coordinate
    }
    
    var title: String? {
        return place.name
    }

    var color: UIColor {
        return UIColor(hex: place.hexColor)
    }
    
    init(place: Place) {
        self.place = place
    }
}
