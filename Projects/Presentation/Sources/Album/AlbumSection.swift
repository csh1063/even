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
    case face
    case similar
    case category
    case location
    case date

    var title: String {
        switch self {
        case .date:     return String(localized: "시간", bundle: .module)
        case .travel:     return String(localized: "여행", bundle: .module)
        case .location:  return String(localized: "장소", bundle: .module)
        case .category: return String(localized: "분류", bundle: .module)
        case .face:     return String(localized: "인물", bundle: .module)
        case .similar: return String(localized: "중복", bundle: .module)
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

    /// 홈 화면 "인물" 섹션에 함께 노출되는 from 값들 — 얼굴/동물은 같은 섹션에서 섞여 보이지만
    /// 병합/분리/여행자연결/이름변경 문구/"나" 하이라이트 등 모든 동작은 이 상수와 무관하게
    /// AlbumType 케이스(.face vs .animal)와 album.from으로 계속 분리되어 있다.
    static let faceSectionFromValues: Set<String> = ["face", "animal"]
}

enum AlbumType: Hashable {
    case date(DateAlbumCellViewModel)
    case travel(TravelAlbumCellViewModel)
    case location(LocationAlbumCellViewModel)
    case category(CategoryAlbumCellViewModel)
    case face(FaceAlbumCellViewModel)
    case animal(AnimalAlbumCellViewModel)
    case similar(SimilarAlbumCellViewModel)

    var album: Album {
        switch self {
        case .date(let vm):     return vm.album
        case .travel(let vm):   return vm.album
        case .location(let vm): return vm.album
        case .category(let vm): return vm.album
        case .face(let vm):     return vm.album
        case .animal(let vm):   return vm.album
        case .similar(let vm):  return vm.album
        }
    }
}
