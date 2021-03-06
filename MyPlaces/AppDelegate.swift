import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - UIApplicationDelegate

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = RootViewController()
        window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        LocationManager.sharedLocationManager.stopTrackingLocation()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Nothing...
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Nothing...
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        LocationManager.sharedLocationManager.startTrackingLocation()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DataManager.sharedDataManager.saveContext()
    }
}
