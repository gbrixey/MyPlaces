import UIKit

/// Static functions for managing appearance of UI elements
struct AppearanceManager {
    
    static var navBarAppearance: UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        return appearance
    }
}
