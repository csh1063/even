//
//  ClusterEntity.swift
//  Data
//
//  Created by sanghyeon on 6/9/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import SwiftData

@Model
public final class ClusterEntity {
    @Attribute(.unique) public var id: UUID
    public var centroidData: Data
    public var excludedPhotoIds: [String] = []
    public var createdAt: Date = Date()

    /// 합치기(mergeAlbums)로 이 클러스터가 다른 앨범에 흡수되기 직전의 원래 앨범 이름 —
    /// 나중에 분리(splitAlbum)할 때 새 이름을 새로 매기지 않고 이 값으로 복원하기 위함.
    /// 이미 값이 있으면(과거에 또 합쳐진 적 있음) 덮어쓰지 않아 제일 처음 이름을 계속 보존한다.
    public var originalName: String?
    public var originalDisplayName: String?
    public var originalIsRenamed: Bool = false

    @Relationship(deleteRule: .nullify)
    public var album: AlbumEntity?

    @Relationship(deleteRule: .nullify)
    public var faceEmbeddings: [FaceEmbeddingEntity] = []

    public init(id: UUID = UUID(), centroidData: Data) {
        self.id = id
        self.centroidData = centroidData
    }
}
