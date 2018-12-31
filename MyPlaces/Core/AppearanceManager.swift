//
//  AppearanceManager.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/21/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import UIKit

/// Static functions for managing appearance of UI elements
struct AppearanceManager {
    
    static func setupAppearance() {
        UINavigationBar.appearance().barTintColor = UIColor.white
        UINavigationBar.appearance().isTranslucent = false
    }
}
