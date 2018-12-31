//
//  ListSearchMode.swift
//  MyPlaces
//
//  Created by Glen Brixey on 12/28/18.
//  Copyright © 2018 Glen Brixey. All rights reserved.
//

enum ListSearchMode: Equatable {
    /// All place data shown with no folder hierarchy
    case allPlaces
    /// Subfolders and places within the given folder
    case folder(folderID: Int?)
    /// Nearest places shown first with no folder hierarchy
    case nearby
    /// Places matching the given text, with no folder hierarchy
    case text(text: String)
}
