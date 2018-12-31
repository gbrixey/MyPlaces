//
//  ListItem.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/20/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

/// Types of item that can appear in the list
enum ListItemType {
    case folder
    case place
    /// This is used for special list cells such as "All Places" that don't correspond directly to a single folder or place.
    case other
}

/// Item that can be presented in the list
struct ListItem {
    let itemType: ListItemType
    let itemID: Int
    let itemName: String
    let itemDetail: String
}

// MARK: - Comparable

extension ListItem: Comparable {

    static func < (lhs: ListItem, rhs: ListItem) -> Bool {
        return lhs.itemName < rhs.itemName
    }
}
