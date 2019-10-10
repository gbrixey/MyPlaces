import UIKit

class RootViewController: UITabBarController {

    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isTranslucent = false

        let rootFolder = DataManager.sharedDataManager.rootFolder
        listVC = ListViewController(searchMode: .folder(folder: rootFolder))
        listVC.tabBarItem = UITabBarItem(title: "List", image: #imageLiteral(resourceName: "list-icon"), selectedImage: nil)
        let listNav = UINavigationController(rootViewController: listVC)
        listNav.navigationBar.standardAppearance = AppearanceManager.navBarAppearance

        mapVC = MapViewController(folder: rootFolder)
        mapVC.tabBarItem = UITabBarItem(title: "Map", image: #imageLiteral(resourceName: "map-icon"), selectedImage: nil)
        let mapNav = UINavigationController(rootViewController: mapVC)
        mapNav.navigationBar.standardAppearance = AppearanceManager.navBarAppearance

        viewControllers = [listNav, mapNav]
    }

    // MARK: - UITabBarDelegate

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard item.title == "Map" else { return }
        if case let .folder(folder) = listVC.searchMode {
            mapVC.folder = folder
        } else {
            mapVC.folder = DataManager.sharedDataManager.rootFolder
        }
    }

    // MARK: - Private

    private var listVC: ListViewController!
    private var mapVC: MapViewController!
}
