//
//  FolderData.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/20/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

/// Entity representing a places folder on Google Earth
struct FolderData {
    let folderID: Int
    let folderName: String
    let parentFolderID: Int?
    let subfolderIDs: [Int]
    let placeIDs: [Int]
}
