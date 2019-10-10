import UIKit

extension UIColor {

    /// Initialize with RGB hexadecimal value
    convenience init(hex: Int32) {
        self.init(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(hex & 0x0000FF) / 255.0,
                  alpha: 1.0)
    }
}
