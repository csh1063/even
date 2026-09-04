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
    /// 사용자가 "대표 사진 변경"으로 직접 고른 적 있는지 — true면 스플래시 동기화/사진 추가/클러스터링
    /// 재계산 등 자동 커버 갱신 로직이 이 값을 덮어쓰지 않는다
    public var coverPhotoManuallySet: Bool = false
    public var photoCount: Int = 0
    public var from: String
    public var isEdited: Bool = false        // 병합/제외/분리 등 구조가 변경된 적 있는지
    public var isRenamed: Bool = false       // 사용자가 이름을 직접 바꾼 적 있는지

    // 여행 앨범 한정 — 이 여행에 사진이 한 장이라도 겹치는 얼굴 앨범 id들.
    // 관계(Relationship) 대신 단순 id 배열로 저장해서 자기참조 관계의 복잡함을 피한다.
    // "누가 포함되는지"는 여행 앨범을 생성할 때 고정되고, "그 사람 이름이 뭔지"는 매번 얼굴 앨범을
    // 다시 조회해서 보여주므로 이름을 나중에 바꿔도 자동으로 반영된다.
    public var linkedFaceAlbumIds: [UUID] = []

    /// linkedFaceAlbumIds와 같은 개념을 동물 앨범에도 적용한 것 — 별도 필드로 두는 이유도 동일하다.
    public var linkedAnimalAlbumIds: [UUID] = []

    @Relationship(deleteRule: .nullify)
    public var photos: [PhotoEntity] = []

    @Relationship(deleteRule: .cascade)
    public var keywords: [AlbumKeywordEntity] = []

    @Relationship(deleteRule: .cascade)
    public var clusters: [ClusterEntity] = []

    @Relationship(deleteRule: .cascade)
    public var animalClusters: [AnimalClusterEntity] = []
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
