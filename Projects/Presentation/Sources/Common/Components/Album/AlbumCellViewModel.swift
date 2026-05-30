//
//  AlbumCellViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 5/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Domain

protocol AlbumCellViewModel: Hashable {
    var id: UUID { get }
    var localIdentifier: String { get }
    var displayName: String { get }
    var formattedDate: String { get }
    var photoCount: Int { get }
    
    var folder: Folder { get }
    
    var imageLoader: any ImageLoadable {get}
}

extension AlbumCellViewModel {
    
    func loadImage(size: CGSize) async -> UIImage? {
        await imageLoader.loadImage(id: localIdentifier, size: size)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.displayName == rhs.displayName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
