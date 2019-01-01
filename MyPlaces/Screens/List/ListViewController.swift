//
//  ListViewController.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/19/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import UIKit
import CoreLocation

final class ListViewController: UITableViewController {

    // MARK: - Public

    private(set) var searchMode: ListSearchMode {
        didSet {
            fetchItems()
            updateNavigationBar()
            nearbyButton.isSelected = searchMode == .nearby
        }
    }

    init(searchMode: ListSearchMode) {
        self.searchMode = searchMode
        super.init(style: .plain)
    }

    // MARK: - Overrides

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for ListViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "List"
        setupNavigationBar()
        setupTableView()
        fetchItems()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar?.resignFirstResponder()
    }

    // MARK: - Actions

    @objc private func uploadButtonTapped() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.kml"], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }

    @objc private func backButtonTapped() {
        switch searchMode {
        case .folder(let folder):
            guard let parentFolder = folder?.parentFolder else { return }
            searchMode = .folder(folder: parentFolder)
        default:
            searchMode = .folder(folder: dataManager.rootFolder)
        }
    }

    @objc private func nearbyButtonTapped() {
        switch searchMode {
        case .nearby:
            searchMode = .folder(folder: dataManager.rootFolder)
        default:
            searchMode = .nearby
        }
    }

    @objc private func refresh() {
        fetchItems()
        refreshControl?.endRefreshing()
    }

    // MARK: - Private

    private var searchBar: UISearchBar!
    private var searchBarShouldBecomeFirstResponder: Bool = true
    private var uploadButtonItem: UIBarButtonItem!
    private var backButtonItem: UIBarButtonItem!
    private var nearbyButton: UIButton!
    private var nearbyButtonItem: UIBarButtonItem!
    private let cellIdentifier = "ListCell"

    private var listItems: [ListItem] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private var dataManager: DataManager {
        return .sharedDataManager
    }

    private func setupTableView() {
        tableView.keyboardDismissMode = .onDrag
        searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.frame = CGRect(x: 0, y: 0, width: 0, height: searchBar?.intrinsicContentSize.height ?? 56)
        tableView.tableHeaderView = searchBar
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    private func setupNavigationBar() {
        uploadButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(uploadButtonTapped))
        let backArrowImage = #imageLiteral(resourceName: "back_arrow_blue").withRenderingMode(.alwaysTemplate)
        backButtonItem = UIBarButtonItem(image: backArrowImage, style: .plain, target: self, action: #selector(backButtonTapped))
        nearbyButton = UIButton(type: .custom)
        nearbyButton.clipsToBounds = true
        nearbyButton.adjustsImageWhenHighlighted = false
        nearbyButton.tintColor = .systemBlue
        nearbyButton.setImage(#imageLiteral(resourceName: "location-arrow-white").withRenderingMode(.alwaysTemplate), for: .normal)
        nearbyButton.setImage(#imageLiteral(resourceName: "location-arrow-white").withRenderingMode(.alwaysOriginal), for: .selected)
        nearbyButton.setBackgroundImage(nil, for: .normal)
        nearbyButton.setBackgroundImage(#imageLiteral(resourceName: "one_pixel_007AFF"), for: .selected)
        nearbyButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 5, bottom: 5, right: 7)
        nearbyButton.layer.cornerRadius = 10
        nearbyButton.addTarget(self, action: #selector(nearbyButtonTapped), for: .touchUpInside)
        nearbyButtonItem = UIBarButtonItem(customView: nearbyButton)
        updateNavigationBar()
    }

    private func updateNavigationBar() {
        var shouldShowBackButton = false
        var shouldShowNearbyButton = true
        let navTitle: String
        switch searchMode {
        case .allPlaces:
            navTitle = "All Places"
            shouldShowBackButton = true
        case .folder(let folder):
            navTitle = folder?.name ?? "My Places"
            shouldShowBackButton = (folder != nil && !folder!.isRootFolder)
        case .nearby:
            navTitle = "Nearby"
        case .text(_):
            navTitle = "Search"
            shouldShowNearbyButton = false
        }
        navigationItem.title = navTitle
        navigationItem.leftBarButtonItem = shouldShowBackButton ? backButtonItem : uploadButtonItem
        navigationItem.rightBarButtonItem = shouldShowNearbyButton ? nearbyButtonItem : nil
    }

    private func fetchItems() {
        switch searchMode {
        case .allPlaces:
            listItems = dataManager.allPlaces.map({ listItem(forPlace: $0) }).sorted()
        case .folder(let folder):
            listItems = self.listItems(inFolder: folder)
        case .nearby:
            guard let location = LocationManager.sharedLocationManager.currentLocation else { return }
            let places = dataManager.places(near: location).prefix(10)
            listItems = places.map({ listItem(forPlace: $0, location: location)})
        case .text(let text):
            listItems = dataManager.places(matchingText: text).map({ listItem(forPlace: $0) }).sorted()
        }
    }

    private func listItems(inFolder folder: Folder?) -> [ListItem] {
        let subfolders = folder?.subfoldersArray.map({ listItem(forFolder: $0) }).sorted() ?? []
        let placeItems = folder?.placesArray.map({ listItem(forPlace: $0) }).sorted() ?? []
        var listItems = subfolders + placeItems
        if folder?.isRootFolder ?? false {
            let allPlacesItem = ListItem(itemType: .allPlaces, item: nil, itemName: "All Places", itemDetail: "")
            listItems.insert(allPlacesItem, at: 0)
        }
        return listItems
    }

    private func listItem(forFolder folder: Folder) -> ListItem {
        return ListItem(itemType: .folder, item: folder, itemName: folder.name, itemDetail: nil)
    }

    private func listItem(forPlace place: Place, location: CLLocation? = nil) -> ListItem {
        var detail: String? = nil
        if let location = location {
            let distance = location.distance(from: CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude))
            let distanceInFeet = Int(round((distance * 3.28084) / 50) * 50)
            if distanceInFeet < 1000 {
                detail = "\(distanceInFeet) feet"
            } else {
                let miles = round(distance * 0.00621371) / 10
                detail = "\(miles) miles"
            }
        }
        return ListItem(itemType: .place, item: place, itemName: place.name, itemDetail: detail)
    }
}

// MARK: - UITableViewDataSource

extension ListViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        let item = listItems[indexPath.row]
        cell.textLabel?.text = item.itemName
        cell.textLabel?.textColor = item.itemType == .folder ? UIColor.systemBlue : UIColor.black
        cell.detailTextLabel?.text = item.itemDetail
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ListViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = listItems[indexPath.row]
        switch item.itemType {
        case .folder:
            searchMode = .folder(folder: item.item as? Folder)
        case .place:
            let place = item.item as! Place
            let detailsVC = DetailsViewController(place: place)
            navigationController?.pushViewController(detailsVC, animated: true)
        case .allPlaces:
            searchMode = .allPlaces
        }
    }
}

// MARK: - UISearchBarDelegate

extension ListViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        let shouldBeginEditing = searchBarShouldBecomeFirstResponder
        searchBarShouldBecomeFirstResponder = true
        return shouldBeginEditing
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let text = searchBar.text, text.count > 0 {
            searchMode = .text(text: text)
        } else {
            searchMode = .folder(folder: dataManager.rootFolder)
            if !searchBar.isFirstResponder {
                // User tapped clear button after searching
                searchBarShouldBecomeFirstResponder = false
            }
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UIDocumentPickerDelegate

extension ListViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        dataManager.parseKMLFile(at: urls[0])
        searchMode = .folder(folder: dataManager.rootFolder)
    }
}
