//
//  DataManager.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/19/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import MapKit
import SWXMLHash
import MobileCoreServices

/// Class that manages Google Earth place data.
/// The data is parsed from a KML file and stored in Core Data.
final class DataManager {

    // MARK: - Public

    static let sharedDataManager = DataManager()

    var rootFolderID: Int? {
        return rootFolder?.folderID
    }

    func nameOfFolder(withID folderID: Int?) -> String? {
        guard let folderID = folderID else { return nil }
        return folder(withID: folderID).folderName
    }

    func parentFolderIDForFolder(withID folderID: Int?) -> Int? {
        guard let folderID = folderID else { return nil }
        let folder = self.folder(withID: folderID)
        return folder.parentFolderID
    }

    /// Returns places contained by the folder with the given folder id.
    /// Not recursive, i.e. does not search subfolders of this folder.
    func placesForFolder(withID folderID: Int?) -> [PlaceData] {
        guard let folderID = folderID else {
            return allPlaces
        }
        let folder = self.folder(withID: folderID)
        return folder.placeIDs.map({ places[$0]! })
    }

    /// Returns subfolders directly contained by the folder with the given ID
    func subfoldersForFolder(withID folderID: Int?) -> [FolderData] {
        guard let folderID = folderID else {
            return []
        }
        let folder = self.folder(withID: folderID)
        return folder.subfolderIDs.map({ folders[$0]! })
    }

    /// Returns places contained by the folder with the given folder id or by any descendent of that folder.
    func recursivePlacesForFolder(withID folderID: Int?) -> [PlaceData] {
        guard let folderID = folderID else {
            return allPlaces
        }
        let folder = self.folder(withID: folderID)
        var recursivePlaces = folder.placeIDs.map({ places[$0]! })
        for subfolderID in folder.subfolderIDs {
            recursivePlaces.append(contentsOf: recursivePlacesForFolder(withID: subfolderID))
        }
        return recursivePlaces
    }

    func place(withID placeID: Int) -> PlaceData? {
        return places[placeID]
    }

    func places(near location: CLLocation) -> [PlaceData] {
        var placeIDToDistance: [Int: CLLocationDistance] = [:]
        for place in allPlaces {
            let distance = location.distance(from: CLLocation(latitude: place.coordinate.latitude,
                                                              longitude: place.coordinate.longitude))
            placeIDToDistance[place.placeID] = distance
        }
        let sortedPlaces = allPlaces.sorted { (place1, place2) -> Bool in
            guard let distance1 = placeIDToDistance[place1.placeID],
                let distance2 = placeIDToDistance[place2.placeID] else {
                    return true
            }
            return distance1 < distance2
        }
        return sortedPlaces
    }

    func places(matchingText text: String) -> [PlaceData] {
        return allPlaces.filter({ $0.placeName.lowercased().contains(text.lowercased()) })
    }
    
    // MARK: - Private

    private var rootFolder: FolderData?
    private var folders: [Int: FolderData] = [:]
    private var places: [Int: PlaceData] = [:]

    private var allPlaces: [PlaceData] {
        return Array(places.values)
    }

    /// Returns the folder with the given id, generates a `fatalError` if a folder with this ID cannot be found.
    private func folder(withID folderID: Int) -> FolderData {
        guard let folder = folders[folderID] else {
            fatalError("Bad folder id")
        }
        return folder
    }
}

// MARK: - XML Parsing

extension DataManager {

    func parseXMLFile(at url: URL) {
        guard let xmlData = try? Data(contentsOf: url) else { return }
        let xml = SWXMLHash.parse(xmlData)
        var folderID = 1
        var placeID = 10001
        rootFolder = parseFolder(xml["kml"]["Document"]["Folder"], folderID: &folderID, parentFolderID: nil, placeID: &placeID)
    }
    
    /// Parse a <Folder> XML element
    private func parseFolder(_ folder: XMLIndexer, folderID: inout Int, parentFolderID: Int?, placeID: inout Int) -> FolderData {
        let id = folderID
        folderID += 1
        var name = "Untitled Folder"
        var placeIDs: [Int] = []
        var subfolderIDs: [Int] = []
        for child in folder.children.makeIterator() {
            guard let element = child.element else {
                continue
            }
            switch element.name {
            case "Folder":
                let subfolder = parseFolder(child, folderID: &folderID, parentFolderID: id, placeID: &placeID)
                subfolderIDs.append(subfolder.folderID)
            case "name":
                name = element.text
            case "Placemark":
                let place = parsePlace(child, placeID: &placeID)
                placeIDs.append(place.placeID)
            default:
                break
            }
        }
        let folder = FolderData(folderID: id, folderName: name, parentFolderID: parentFolderID, subfolderIDs: subfolderIDs, placeIDs: placeIDs)
        folders[id] = folder
        return folder
    }
    
    /// Parse a <Placemark> XML element
    private func parsePlace(_ place: XMLIndexer, placeID: inout Int) -> PlaceData {
        let id = placeID
        placeID += 1
        var name = "Untitled Place"
        var description = "No Description"
        var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        for child in place.children.makeIterator() {
            guard let element = child.element else {
                continue
            }
            switch element.name {
            case "description":
                description = element.text
            case "name":
                name = element.text
            case "Point":
                coordinate = parseCoordinate(child)
            default:
                break
            }
        }
        let place = PlaceData(placeID: id, placeName: name, description: description, coordinate: coordinate)
        places[id] = place
        return place
    }
    
    /// Parse a <Point> XML element
    private func parseCoordinate(_ coordinate: XMLIndexer) -> CLLocationCoordinate2D {
        var longitude = 0.0
        var latitude = 0.0
        for child in coordinate.children.makeIterator() {
            guard let element = child.element,
                element.name == "coordinates" else {
                    continue
            }
            let components = element.text.components(separatedBy: ",")
            if let parsedLongitude = Double(components[0]), let parsedLatitude = Double(components[1]) {
                longitude = parsedLongitude
                latitude = parsedLatitude
            }
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
