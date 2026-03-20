//
//  PhotoCellItemViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 3/16/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain
import UIKit

struct PhotoCellItemViewModel: Hashable {
    let localIdentifier: String
    let formattedDate: String               // 날짜
    let labels: [String] = []               // CoreML 분석 라벨
    var isSelected: Bool = false            // 선택 상태
    var isFavorite: Bool = false            // 즐겨찾기
    
    let photo: PhotoInAlbum
    private let imageLoader: any ImageLoadable
    
    init(photo: PhotoInAlbum, imageLoader: any ImageLoadable) {
        self.localIdentifier = photo.localIdentifier
        self.formattedDate = ""
        self.photo = photo
        self.imageLoader = imageLoader
    }
    
    func loadImage(size: CGSize) async -> UIImage? {
        await imageLoader.loadImage(id: photo.localIdentifier, size: size)
    }
    
    static func == (lhs: PhotoCellItemViewModel, rhs: PhotoCellItemViewModel) -> Bool {
        lhs.localIdentifier == rhs.localIdentifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(localIdentifier)
    }
}
