//
//  AppDelegate.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/19/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - UIApplicationDelegate

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppearanceManager.setupAppearance()
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
    }

    // MARK: - Private

    private var mainNavController: UINavigationController?
}
