//
//  AlbumEntity.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation

@Model
public final class AlbumEntity {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var displayName: String
    public var createdAt: Date
    public var startDate: Date?
    public var endDate: Date?

    public var isAuto: Bool              // 자동 생성 앨범 여부
    public var coverPhotoIdentifier: String?
    public var photoCount: Int = 0
    public var from: String
    public var isEdited: Bool = false        // 병합/제외/분리 등 구조가 변경된 적 있는지
    public var isRenamed: Bool = false       // 사용자가 이름을 직접 바꾼 적 있는지

    // 여행 앨범 한정 — 이 여행에 사진이 한 장이라도 겹치는 얼굴 앨범 id들.
    // 관계(Relationship) 대신 단순 id 배열로 저장해서 자기참조 관계의 복잡함을 피한다.
    // "누가 포함되는지"는 여행 앨범을 생성할 때 고정되고, "그 사람 이름이 뭔지"는 매번 얼굴 앨범을
    // 다시 조회해서 보여주므로 이름을 나중에 바꿔도 자동으로 반영된다.
    public var linkedFaceAlbumIds: [UUID] = []

    @Relationship(deleteRule: .nullify)
    public var photos: [PhotoEntity] = []

    @Relationship(deleteRule: .cascade)
    public var keywords: [AlbumKeywordEntity] = []

    @Relationship(deleteRule: .cascade)
    public var clusters: [ClusterEntity] = []
    public init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        createdAt: Date = Date(),
        startDate: Date? = nil,
        endDate: Date? = nil,
        isAuto: Bool = false,
        coverPhotoIdentifier: String? = nil,
        from: String
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.isAuto = isAuto
        self.coverPhotoIdentifier = coverPhotoIdentifier
        self.from = from
    }
}
