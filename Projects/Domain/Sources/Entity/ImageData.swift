//
//  ImageData.swift
//  Domain
//
//  Created by sanghyeon on 3/13/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

public struct ImageData<T> {
    public let cgImage: T?
//    let width: CGFloat
//    let height: CGFloat
    
    public init(cgImage: T?) {
        self.cgImage = cgImage
    }
}
