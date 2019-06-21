//
//  UIColorExtensions.swift
//  MyPlaces
//
//  Created by Glen Brixey on 5/21/17.
//  Copyright © 2017 Glen Brixey. All rights reserved.
//

import UIKit

extension UIColor {

    static let systemBlue = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)

    /// Initialize with RGB hexadecimal value
    convenience init(hex: Int32) {
        self.init(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(hex & 0x0000FF) / 255.0,
                  alpha: 1.0)
    }
}
