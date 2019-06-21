enum ListSearchMode: Equatable {
    /// All place data shown with no folder hierarchy
    case allPlaces
    /// Subfolders and places within the given folder
    case folder(folder: Folder?)
    /// Nearest places shown first, with no folder hierarchy
    case nearby
    /// Places matching the given text, with no folder hierarchy
    case text(text: String)
}
