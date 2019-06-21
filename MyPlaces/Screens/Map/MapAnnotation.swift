//
//  MapAnnotation.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/20/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

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
    
    init(place: Place) {
        self.place = place
    }
}
