//
//  DataManager.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/19/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import MapKit
import CoreData
import SWXMLHash

/// Class that manages Google Earth place data.
/// The data is parsed from a KML file and stored in Core Data.
final class DataManager {

    // MARK: - Public

    static let sharedDataManager = DataManager()

    var rootFolder: Folder? {
        let fetchRequest = NSFetchRequest<Folder>(entityName: "Folder")
        fetchRequest.predicate = NSPredicate(format: "parentFolder = nil")
        guard let fetchResults = try? context.fetch(fetchRequest) else { return nil }
        return fetchResults.first
    }

    var allPlaces: [Place] {
        let fetchRequest = NSFetchRequest<Place>(entityName: "Place")
        guard let fetchResults = try? context.fetch(fetchRequest) else { return [] }
        return fetchResults
    }

    init() {
        persistentContainer = NSPersistentContainer(name: "MyPlaces")
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            // Nothing...
        })
    }

    func places(near location: CLLocation) -> [Place] {
        var placeIDToDistance: [NSManagedObjectID: CLLocationDistance] = [:]
        for place in allPlaces {
            let distance = location.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
            placeIDToDistance[place.objectID] = distance
        }
        let sortedPlaces = allPlaces.sorted { (place1, place2) -> Bool in
            guard let distance1 = placeIDToDistance[place1.objectID],
                let distance2 = placeIDToDistance[place2.objectID] else {
                    return true
            }
            return distance1 < distance2
        }
        return sortedPlaces
    }

    func places(matchingText text: String) -> [Place] {
        let fetchRequest = NSFetchRequest<Place>(entityName: "Place")
        fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", text)
        guard let fetchResults = try? context.fetch(fetchRequest) else { return [] }
        return fetchResults
    }
    
    // MARK: - Private

    private var persistentContainer: NSPersistentContainer

    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}

// MARK: - Core Data

extension DataManager {

    /// Try to save the managed object context
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            try? context.save()
        }
    }
}

// MARK: - KML Parsing

extension DataManager {

    /// Attempt to parse the given KML file and 
    func parseKMLFile(at url: URL) {
        guard let kmlData = try? Data(contentsOf: url) else { return }
        let kml = SWXMLHash.parse(kmlData)
        let documentKML = kml["kml"]["Document"]

        let documentHasMultipleFolders = documentKML.children.filter({ $0.element?.name == "Folder" }).count > 1
        let documentHasPlacemarks = documentKML.children.filter({ $0.element?.name == "Placemark" }).count > 0
        let shouldCreateNewRootFolder = documentHasPlacemarks || documentHasMultipleFolders
        if shouldCreateNewRootFolder {
            var documentName = documentKML.textOfFirstChildElement(withName: "name") ?? "My Places"
            if documentName.hasSuffix(".kml") {
                documentName = String(documentName.dropLast(4))
            }
            let folderDescription = NSEntityDescription.entity(forEntityName: "Folder", in: context)!
            let folder = NSManagedObject(entity: folderDescription, insertInto: context)
            folder.setValue(documentName, forKeyPath: "name")
            for child in documentKML.children {
                guard let element = child.element else { continue }
                switch element.name {
                case "Folder":
                    parseFolder(child, parentFolder: folder)
                case "Placemark":
                    parsePlace(child, folder: folder)
                default:
                    break
                }
            }
        } else {
            let rootFolderKML = documentKML["Folder"]
            parseFolder(rootFolderKML)
        }
        saveContext()
    }
    
    /// Parse a <Folder> KML element
    private func parseFolder(_ folderKML: XMLIndexer, parentFolder: NSManagedObject? = nil) {
        let name = folderKML.textOfFirstChildElement(withName: "name") ?? "Untitled Folder"
        let folderDescription = NSEntityDescription.entity(forEntityName: "Folder", in: context)!
        let folder = NSManagedObject(entity: folderDescription, insertInto: context)
        folder.setValue(name, forKeyPath: "name")
        if let parentFolder = parentFolder {
            folder.setValue(parentFolder, forKey: "parentFolder")
        }
        for child in folderKML.children {
            guard let element = child.element else { continue }
            switch element.name {
            case "Folder":
                parseFolder(child, parentFolder: folder)
            case "Placemark":
                parsePlace(child, folder: folder)
            default:
                break
            }
        }
    }
    
    /// Parse a <Placemark> KML element
    private func parsePlace(_ placeKML: XMLIndexer, folder: NSManagedObject) {
        let name = placeKML.textOfFirstChildElement(withName: "name") ?? "Untitled Place"
        let details = placeKML.textOfFirstChildElement(withName: "description") ?? "No Description"
        var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        if let point = placeKML.firstChildElement(withName: "Point") {
            coordinate = parseCoordinate(point)
        }
        let placeDescription = NSEntityDescription.entity(forEntityName: "Place", in: context)!
        let place = NSManagedObject(entity: placeDescription, insertInto: context)
        place.setValue(name, forKeyPath: "name")
        place.setValue(details, forKey: "details")
        place.setValue(coordinate.latitude, forKey: "latitude")
        place.setValue(coordinate.longitude, forKey: "longitude")
        place.setValue(folder, forKey: "folder")
    }
    
    /// Parse a <Point> KML element
    private func parseCoordinate(_ coordinateKML: XMLIndexer) -> CLLocationCoordinate2D {
        var longitude = 0.0
        var latitude = 0.0
        if let coordinateText = coordinateKML.textOfFirstChildElement(withName: "coordinates") {
            let components = coordinateText.components(separatedBy: ",")
            if let parsedLongitude = Double(components[0]), let parsedLatitude = Double(components[1]) {
                longitude = parsedLongitude
                latitude = parsedLatitude
            }
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension XMLIndexer {

    func firstChildElement(withName name: String) -> XMLIndexer? {
        return children.first(where: { $0.element?.name == name })
    }

    func textOfFirstChildElement(withName name: String) -> String? {
        return firstChildElement(withName: name)?.element?.text
    }
}

// MARK: - Convenience

extension Folder {

    var isRootFolder: Bool {
        return parentFolder == nil
    }
}

extension Place {

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
