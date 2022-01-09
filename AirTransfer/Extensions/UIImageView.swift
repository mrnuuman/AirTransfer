//
//  UIImageView.swift
//  AirTransfer
//
//  Created by Mac on 1/9/22.
//

import UIKit

extension UIImageView {

   func setRounded() {
       let radius = self.frame.width / 2
      self.layer.cornerRadius = radius
      self.layer.masksToBounds = true
   }
}
