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

    var album: Album { get }

    var imageLoader: any ImageLoadable {get}
}

extension AlbumCellViewModel {

    func loadImage(size: CGSize) async -> UIImage? {
        await imageLoader.loadImage(id: localIdentifier, size: size)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        // photoCount/localIdentifier(커버 사진)까지 비교해야 한다 — id와 displayName만 같으면
        // "안 바뀐 셀"로 취급돼서 UICollectionViewDiffableDataSource가 다시 안 그려준다(합치기/사진
        // 추가로 사진 수·커버는 바뀌었는데 이름은 그대로인 흔한 경우에 갱신이 안 되던 원인이었음)
        lhs.id == rhs.id
            && lhs.displayName == rhs.displayName
            && lhs.photoCount == rhs.photoCount
            && lhs.localIdentifier == rhs.localIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
