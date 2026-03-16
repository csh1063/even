//
//  ImageData.swift
//  Domain
//
//  Created by sanghyeon on 3/13/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

public struct ImageData {
    public let image: UIImage?
//    let width: CGFloat
//    let height: CGFloat
    
    public init(cgImage: CGImage?) {
        if let cgImage {
            self.image = UIImage(cgImage: cgImage)
        } else {
            self.image = nil
        }
    }
}
