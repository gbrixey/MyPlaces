//
//  PlaceData.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/19/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import CoreLocation

/// Entity representing a placemark on Google Earth
struct PlaceData {
    let placeID: Int
    let placeName: String
    let description: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Hashable

extension PlaceData: Hashable {

    var hashValue: Int {
        return placeID
    }

    static func ==(lhs: PlaceData, rhs: PlaceData) -> Bool {
        return lhs.placeID == rhs.placeID &&
            lhs.placeName == rhs.placeName &&
            lhs.coordinate.latitude == rhs.coordinate.latitude &&
            lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}
