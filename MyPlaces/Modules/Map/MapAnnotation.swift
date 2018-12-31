//
//  MapAnnotation.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/20/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import MapKit

/// Annotation for the map view
final class MapAnnotation: NSObject, MKAnnotation {

    // MARK: - Public

    private(set) var place: PlaceData
    
    var coordinate: CLLocationCoordinate2D {
        return place.coordinate
    }
    
    var title: String? {
        return place.placeName
    }
    
    init(place: PlaceData) {
        self.place = place
    }
}
