import UIKit

/// Static functions for managing appearance of UI elements
struct AppearanceManager {
    
    static func setupAppearance() {
        UINavigationBar.appearance().barTintColor = UIColor.white
        UINavigationBar.appearance().isTranslucent = false
    }
}
