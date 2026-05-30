//
//  AlbumSection.swift
//  Presentation
//
//  Created by sanghyeon on 5/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain

enum AlbumSection: Int, CaseIterable {
    case travel
    case location
    case date
    case category
    case face

    var title: String {
        switch self {
        case .date:     return "시간"
        case .travel:     return "여행"
        case .location:  return "장소"
        case .category: return "분류"
        case .face:     return "인물"
        }
    }
}

enum AlbumType: Hashable {
    case date(DateAlbumCellViewModel)
    case travel(TravelAlbumCellViewModel)
    case location(LocationAlbumCellViewModel)
    case category(CategoryAlbumCellViewModel)
    case face(FaceCellViewModel)
    
    var folder: Folder {
        switch self {
        case .date(let vm):     return vm.folder
        case .travel(let vm):   return vm.folder
        case .location(let vm): return vm.folder
        case .category(let vm): return vm.folder
        case .face(let vm):     return vm.folder
        }
    }
}
