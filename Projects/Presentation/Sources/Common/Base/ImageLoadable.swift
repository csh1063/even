//
//  ImageLoadable.swift
//  Presentation
//
//  Created by sanghyeon on 3/16/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

protocol ImageLoadable {
    func loadImage(id: String, size: CGSize) async -> UIImage?
}
