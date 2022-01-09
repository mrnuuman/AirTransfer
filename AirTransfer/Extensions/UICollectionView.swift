//
//  UINib.swift
//  AirTransfer
//
//  Created by Mac on 1/9/22.
//

import Foundation
import UIKit

extension UICollectionView {
    func registerNibWithNames(_ name: String...) {
        name.forEach { name in
            let nib = UINib(nibName: name, bundle: .main)
            self.register(nib, forCellWithReuseIdentifier: name)
        }
    }
}
