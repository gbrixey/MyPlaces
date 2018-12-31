//
//  LocationManager.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/20/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import CoreLocation

/// Class responsible for finding the user's current location
final class LocationManager: NSObject {

    // MARK: - Public
    
    static let sharedLocationManager = LocationManager()

    var currentLocation: CLLocation?

    func startTrackingLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            // Fail silently
            break
        }
    }

    func stopTrackingLocation() {
        manager.stopUpdatingLocation()
    }

    // MARK: - Overrides

    override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
    }

    // MARK: - Private

    private let manager: CLLocationManager = CLLocationManager()
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard locations.count > 0 else { return }
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .notDetermined, .restricted, .denied:
            manager.stopUpdatingLocation()
        }
    }
}
