//
//  FolderCellItemViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 3/23/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain
import UIKit

struct FolderCellItemViewModel: Hashable {
    let id: UUID
    let localIdentifier: String
    let displayName: String
    let formattedDate: String               // 날짜
    let labels: [String] = []               // CoreML 분석 라벨
    var isSelected: Bool = false            // 선택 상태
    var isFavorite: Bool = false            // 즐겨찾기
    
    let folder: Folder
    
    private let imageLoader: any ImageLoadable
    
    init(folder: Folder, imageLoader: any ImageLoadable) {
        self.id = folder.id
        self.localIdentifier = folder.photos.first?.localIdentifier ?? ""
        self.displayName = folder.displayName.replacingOccurrences(of: "_", with: " ")
        self.formattedDate = ""
        self.folder = folder
        self.imageLoader = imageLoader
    }
    
    func loadImage(size: CGSize) async -> UIImage? {
        await imageLoader.loadImage(id: localIdentifier, size: size)
    }
    
    static func == (lhs: FolderCellItemViewModel, rhs: FolderCellItemViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
