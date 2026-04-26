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
    var isUnanalysis: Bool
    
//    let photo: PhotoInAlbum
    private let imageLoader: any ImageLoadable
    
    init(localIdentifier: String, imageLoader: any ImageLoadable, isUnanalysis: Bool = false) {
        self.localIdentifier = localIdentifier
        self.formattedDate = ""
        self.imageLoader = imageLoader
        self.isUnanalysis = isUnanalysis
    }
//    init(photo: PhotoInAlbum, imageLoader: any ImageLoadable) {
//        self.localIdentifier = photo.localIdentifier
//        self.formattedDate = ""
//        self.photo = photo
//        self.imageLoader = imageLoader
//    }
    
    func loadImage(size: CGSize) async -> UIImage? {
        await imageLoader.loadImage(id: localIdentifier, size: size)
    }
    
    static func == (lhs: PhotoCellItemViewModel, rhs: PhotoCellItemViewModel) -> Bool {
        lhs.localIdentifier == rhs.localIdentifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(localIdentifier)
    }
}
