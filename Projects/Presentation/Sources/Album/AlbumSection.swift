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
    case similar
    case category
    case face
    case location
    case date

    var title: String {
        switch self {
        case .date:     return "시간"
        case .travel:     return "여행"
        case .location:  return "장소"
        case .category: return "분류"
        case .face:     return "인물"
        case .similar: return "중복"
        }
    }

    var type: String {
        switch self {
        case .date:     return "date"
        case .travel:     return "travel"
        case .location:  return "location"
        case .category: return "category"
        case .face:     return "face"
        case .similar: return "similar"
        }
    }
}

enum AlbumType: Hashable {
    case date(DateAlbumCellViewModel)
    case travel(TravelAlbumCellViewModel)
    case location(LocationAlbumCellViewModel)
    case category(CategoryAlbumCellViewModel)
    case face(FaceAlbumCellViewModel)
    case similar(SimilarAlbumCellViewModel)

    var album: Album {
        switch self {
        case .date(let vm):     return vm.album
        case .travel(let vm):   return vm.album
        case .location(let vm): return vm.album
        case .category(let vm): return vm.album
        case .face(let vm):     return vm.album
        case .similar(let vm):  return vm.album
        }
    }
}
