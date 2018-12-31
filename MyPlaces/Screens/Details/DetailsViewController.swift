//
//  DetailsViewController.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/20/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import UIKit
import MapKit

/// View showing details about a Google Earth placemark
final class DetailsViewController: UIViewController {

    init(place: PlaceData) {
        self.place = place
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    // MARK: - Overrides
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for DetailsViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Details"
        nameLabel.text = place.placeName
        descriptionLabel.text = place.description
        createMapImage()
    }

    // MARK: - Private

    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var mapImageView: UIImageView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var pinImageView: UIImageView!

    private var place: PlaceData

    private func createMapImage() {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: place.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        options.mapType = .standard
        options.showsBuildings = false
        options.showsPointsOfInterest = false
        options.size = CGSize(width: max(UIScreen.main.bounds.width, UIScreen.main.bounds.height), height: 200)
        let mapSnapshotter = MKMapSnapshotter(options: options)
        activityIndicator.startAnimating()
        mapSnapshotter.start { [weak self] (snapshot, error) in
            guard let strongSelf = self, let snapshot = snapshot else { return }
            strongSelf.activityIndicator.stopAnimating()
            strongSelf.mapImageView.image = snapshot.image
            strongSelf.pinImageView.isHidden = false
        }
    }
}
