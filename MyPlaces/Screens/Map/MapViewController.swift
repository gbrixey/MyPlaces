//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/20/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import MapKit

class MapViewController: UIViewController {

    // MARK: - Public

    var folder: Folder? {
        didSet {
            guard folder?.objectID != oldValue?.objectID else { return }
            fetchItems()
            updateNavigationBar()
        }
    }

    init(folder: Folder?) {
        self.folder = folder
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - Overrides

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for MapViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Map"
        setupNavigationBar()
        fetchItems()
    }
    
    // MARK: - Actions

    @objc private func resetButtonTapped() {
        folder = dataManager.rootFolder
    }
    
    @objc private func nearbyButtonTapped(_ sender: UIBarButtonItem) {
        guard LocationManager.sharedLocationManager.currentLocation != nil else { return }
        let newTrackingMode: MKUserTrackingMode = mapView.userTrackingMode == .none ? .followWithHeading : .none
        mapView.setUserTrackingMode(newTrackingMode, animated: true)
    }

    @objc private func dismissDetails() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Private

    @IBOutlet private var mapView: MKMapView!
    private var resetButtonItem: UIBarButtonItem!
    private var places: [Place] = []
    private let annotationIdentifier = "MapAnnotation"

    private var dataManager: DataManager {
        return .sharedDataManager
    }

    private func setupNavigationBar() {
        resetButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetButtonTapped))
        let nearbyIcon = #imageLiteral(resourceName: "location-arrow-white").withRenderingMode(.alwaysTemplate)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: nearbyIcon, style: .plain, target: self, action: #selector(nearbyButtonTapped(_:)))
        updateNavigationBar()
    }

    private func updateNavigationBar() {
        navigationItem.title = folder?.name ?? title
        navigationItem.leftBarButtonItem = (folder == nil || folder!.isRootFolder) ? nil : resetButtonItem
    }

    private func fetchItems() {
        guard isViewLoaded else { return }

        // TODO: recursive
        let places = folder?.flattenedPlacesArray ?? []
        let currentPlacesSet = Set(self.places)
        let newPlacesSet = Set(places)
        let placesToRemove = currentPlacesSet.subtracting(newPlacesSet)
        let placesToAdd = newPlacesSet.subtracting(currentPlacesSet)
        self.places = places

        // Update map annotations
        let annotationsToRemove = mapView.annotations.filter({ (annotation: MKAnnotation) -> Bool in
            if annotation.isKind(of: MKUserLocation.self) {
                return false
            }
            let mapAnnotation = annotation as! MapAnnotation
            return placesToRemove.contains(mapAnnotation.place)
        })
        mapView.removeAnnotations(annotationsToRemove)
        let annotationsToAdd = Array(placesToAdd).map({ MapAnnotation(place: $0) })
        mapView.addAnnotations(annotationsToAdd)

        // Update map region to enclose all places
        guard places.count > 0 else { return }
        var minLatitude = 90.0
        var maxLatitude = -90.0
        var minLongitude = 180.0
        var maxLongitude = -180.0
        for place in places {
            minLatitude = min(minLatitude, place.coordinate.latitude)
            maxLatitude = max(maxLatitude, place.coordinate.latitude)
            minLongitude = min(minLongitude, place.coordinate.longitude)
            maxLongitude = max(maxLongitude, place.coordinate.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLatitude + maxLatitude) / 2, longitude: (minLongitude + maxLongitude) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLatitude - minLatitude) * 1.2, longitudeDelta: (maxLongitude - minLongitude) * 1.2)
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) { return nil }
        var annotationView: MKAnnotationView
        if let reusableAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = reusableAnnotationView
            annotationView.annotation = annotation
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        }
        let button = UIButton(type: .detailDisclosure)
        annotationView.rightCalloutAccessoryView = button
        annotationView.canShowCallout = true
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let annotation = view.annotation as! MapAnnotation
        let detailsVC = DetailsViewController(place: annotation.place)
        let closeImage = #imageLiteral(resourceName: "close_gray").withRenderingMode(.alwaysTemplate)
        detailsVC.navigationItem.leftBarButtonItem = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(dismissDetails))
        let detailsNav = UINavigationController(rootViewController: detailsVC)
        present(detailsNav, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Cancel current location tracking
        if mapView.userTrackingMode != .none {
            mapView.setUserTrackingMode(.none, animated: false)
        }
    }
}
