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
        case .folder(let folderID):
            guard let parentFolderID = dataManager.parentFolderIDForFolder(withID: folderID) else { fallthrough }
            searchMode = .folder(folderID: parentFolderID)
        default:
            searchMode = .folder(folderID: dataManager.rootFolderID)
        }
    }

    @objc private func nearbyButtonTapped() {
        switch searchMode {
        case .nearby:
            searchMode = .folder(folderID: dataManager.rootFolderID)
        default:
            searchMode = .nearby
        }
    }

    // MARK: - Private

    private var searchBar: UISearchBar!
    private var searchBarShouldBecomeFirstResponder: Bool = true
    private var uploadButtonItem: UIBarButtonItem!
    private var backButtonItem: UIBarButtonItem!
    private var nearbyButton: UIButton!
    private var nearbyButtonItem: UIBarButtonItem!
    private let cellIdentifier = "ListCell"
    private let allPlacesItemID = -1

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
        case .folder(let folderID):
            navTitle = dataManager.nameOfFolder(withID: folderID) ?? "My Places"
            shouldShowBackButton = (folderID != dataManager.rootFolderID)
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
            let rootFolderID = dataManager.rootFolderID
            listItems = dataManager.recursivePlacesForFolder(withID: rootFolderID).map({ listItem(fromPlace: $0) }).sorted()
        case .folder(let folderID):
            fetchItemsInFolder(withID: folderID)
        case .nearby:
            fetchNearbyPlaces()
        case .text(let text):
            listItems = dataManager.places(matchingText: text).map({ listItem(fromPlace: $0) }).sorted()
        }
    }

    private func fetchItemsInFolder(withID folderID: Int?) {
        guard let folderID = folderID else { return }
        let subfolders = dataManager.subfoldersForFolder(withID: folderID).map({ listItem(fromFolder: $0) }).sorted()
        let places = dataManager.placesForFolder(withID: folderID).map({ listItem(fromPlace: $0) }).sorted()
        var listItems = subfolders + places
        if folderID == dataManager.rootFolderID {
            let allPlacesItem = ListItem(itemType: .other, itemID: allPlacesItemID, itemName: "All Places", itemDetail: "")
            listItems.insert(allPlacesItem, at: 0)
        }
        self.listItems = listItems
    }

    private func fetchNearbyPlaces() {
        guard let location = LocationManager.sharedLocationManager.currentLocation else { return }
        let places = dataManager.places(near: location).prefix(10)
        listItems = places.map({ listItem(fromPlace: $0, location: location)})
    }

    private func listItem(fromFolder folder: FolderData) -> ListItem {
        return ListItem(itemType: .folder, itemID: folder.folderID, itemName: folder.folderName, itemDetail: "")
    }

    private func listItem(fromPlace place: PlaceData, location: CLLocation? = nil) -> ListItem {
        var detail: String = ""
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
        return ListItem(itemType: .place, itemID: place.placeID, itemName: place.placeName, itemDetail: detail)
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
            searchMode = .folder(folderID: item.itemID)
        case .place:
            guard let place = dataManager.place(withID: item.itemID) else { return }
            let detailsVC = DetailsViewController(place: place)
            navigationController?.pushViewController(detailsVC, animated: true)
        case .other:
            if item.itemID == allPlacesItemID {
                searchMode = .allPlaces
            }
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
            searchMode = .folder(folderID: dataManager.rootFolderID)
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
        dataManager.parseXMLFile(at: urls[0])
        searchMode = .folder(folderID: dataManager.rootFolderID)
    }
}
