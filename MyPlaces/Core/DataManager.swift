import MapKit
import CoreData
import SWXMLHash

/// Class that manages Google Earth place data.
/// The data is parsed from a KML file and stored in Core Data.
class DataManager {

    // MARK: - Public

    static let sharedDataManager = DataManager()

    var rootFolder: Folder? {
        let fetchRequest: NSFetchRequest<Folder> = Folder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "parentFolder = nil")
        guard let fetchResults = try? context.fetch(fetchRequest) else { return nil }
        return fetchResults.first
    }

    var allPlaces: [Place] {
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
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
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
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

    /// Attempt to parse the given KML file and store the data in Core Data
    func parseKMLFile(at url: URL) {
        guard let kmlData = try? Data(contentsOf: url) else { return }
        deleteEverything()
        let kml = SWXMLHash.parse(kmlData)
        let documentKML = kml[KMLNames.kml][KMLNames.document]

        let documentHasMultipleFolders = documentKML.children.filter({ $0.element?.name == KMLNames.folder }).count > 1
        let documentHasPlacemarks = documentKML.children.filter({ $0.element?.name == KMLNames.placemark }).count > 0
        let shouldCreateNewRootFolder = documentHasPlacemarks || documentHasMultipleFolders
        if shouldCreateNewRootFolder {
            var documentName = documentKML.textOfFirstChildElement(withName: KMLNames.name) ?? "My Places"
            if documentName.hasSuffix(".kml") {
                documentName = String(documentName.dropLast(4))
            }
            let folder = Folder(context: context)
            folder.name = documentName
            for child in documentKML.children {
                guard let element = child.element else { continue }
                switch element.name {
                case KMLNames.folder:
                    parseFolder(child, parentFolder: folder)
                case KMLNames.placemark:
                    parsePlace(child, folder: folder)
                default:
                    break
                }
            }
        } else {
            let rootFolderKML = documentKML[KMLNames.folder]
            parseFolder(rootFolderKML)
        }
        saveContext()
    }

    /// Deletes everything in Core Data
    private func deleteEverything() {
        let _ = try? context.execute(NSBatchDeleteRequest(fetchRequest: Folder.fetchRequest()))
        let _ = try? context.execute(NSBatchDeleteRequest(fetchRequest: Place.fetchRequest()))
    }
    
    /// Parse a <Folder> KML element
    private func parseFolder(_ folderKML: XMLIndexer, parentFolder: Folder? = nil) {
        let name = folderKML.textOfFirstChildElement(withName: KMLNames.name) ?? "Untitled Folder"
        let folder = Folder(context: context)
        folder.name = name
        folder.parentFolder = parentFolder
        for child in folderKML.children {
            guard let element = child.element else { continue }
            switch element.name {
            case KMLNames.folder:
                parseFolder(child, parentFolder: folder)
            case KMLNames.placemark:
                parsePlace(child, folder: folder)
            default:
                break
            }
        }
    }
    
    /// Parse a <Placemark> KML element
    private func parsePlace(_ placeKML: XMLIndexer, folder: Folder) {
        let name = placeKML.textOfFirstChildElement(withName: KMLNames.name) ?? "Untitled Place"
        let details = placeKML.textOfFirstChildElement(withName: KMLNames.description) ?? "No Description"
        var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        if let point = placeKML.firstChildElement(withName: KMLNames.point) {
            coordinate = parseCoordinate(point)
        }
        let place = Place(context: context)
        place.name = name
        place.details = details
        place.latitude = coordinate.latitude
        place.longitude = coordinate.longitude
        place.folder = folder
    }
    
    /// Parse a <Point> KML element
    private func parseCoordinate(_ coordinateKML: XMLIndexer) -> CLLocationCoordinate2D {
        var longitude = 0.0
        var latitude = 0.0
        if let coordinateText = coordinateKML.textOfFirstChildElement(withName: KMLNames.coordinates) {
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
        return children.first(where: { $0.element?.name.lowercased() == name.lowercased() })
    }

    func textOfFirstChildElement(withName name: String) -> String? {
        return firstChildElement(withName: name)?.element?.text
    }
}

struct KMLNames {

    static let kml: String = "kml"
    static let document: String = "Document"
    static let folder: String = "Folder"
    static let placemark: String = "Placemark"
    static let name: String = "name"
    static let description: String = "description"
    static let point: String = "Point"
    static let coordinates: String = "coordinates"
}

// MARK: - Convenience

extension Folder {

    var isRootFolder: Bool {
        return parentFolder == nil
    }

    var subfoldersArray: [Folder] {
        return (subfolders?.allObjects as? [Folder]) ?? []
    }

    var placesArray: [Place] {
        return (places?.allObjects as? [Place]) ?? []
    }

    /// Returns all places in this folder and its descendant folders
    var flattenedPlacesArray: [Place] {
        return subfoldersArray.reduce(placesArray, { $0 + $1.flattenedPlacesArray })
    }
}

extension Place {

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
