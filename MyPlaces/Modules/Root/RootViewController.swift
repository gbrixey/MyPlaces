//
//  RootViewController.swift
//  MyPlaces
//
//  Created by Glen Brixey on 12/31/18.
//  Copyright © 2018 Glen Brixey. All rights reserved.
//

import UIKit

final class RootViewController: UITabBarController {

    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isTranslucent = false

        let rootFolderID = DataManager.sharedDataManager.rootFolderID
        listVC = ListViewController(searchMode: .folder(folderID: rootFolderID))
        listVC.tabBarItem = UITabBarItem(title: "List", image: #imageLiteral(resourceName: "list-icon"), selectedImage: nil)
        let listNav = UINavigationController(rootViewController: listVC)

        mapVC = MapViewController(folderID: rootFolderID)
        mapVC.tabBarItem = UITabBarItem(title: "Map", image: #imageLiteral(resourceName: "map-icon"), selectedImage: nil)
        let mapNav = UINavigationController(rootViewController: mapVC)

        viewControllers = [listNav, mapNav]
    }

    // MARK: - UITabBarDelegate

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard item.title == "Map" else { return }
        if case let .folder(folderID) = listVC.searchMode {
            mapVC.folderID = folderID
        } else {
            mapVC.folderID = DataManager.sharedDataManager.rootFolderID
        }
    }

    // MARK: - Private

    private var listVC: ListViewController!
    private var mapVC: MapViewController!
}
