//
//  ListItem.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/20/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import CoreData

struct ListItem {
    let itemType: ItemType
    let item: NSManagedObject?
    let itemName: String?
    let itemDetail: String?
}

// MARK: - ListItem.ItemType

extension ListItem {

    enum ItemType {
        case folder
        case place
        case allPlaces
    }
}

// MARK: - Comparable

extension ListItem: Comparable {

    static func < (lhs: ListItem, rhs: ListItem) -> Bool {
        let lhsItemName = lhs.itemName ?? ""
        let rhsItemName = rhs.itemName ?? ""
        return lhsItemName < rhsItemName
    }
}
