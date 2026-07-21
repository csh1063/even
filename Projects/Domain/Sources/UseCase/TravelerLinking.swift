//
//  TravelerLinking.swift
//  Domain
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//
//  여행 앨범과 얼굴/동물 앨범을 "사진이 한 장이라도 겹치면 연결"하는 규칙 — 앨범 생성 시점(AutoAlbumUseCase),
//  병합 재계산·사진 추가/삭제 시점(AlbumDetailUseCase) 모두 같은 규칙을 쓰므로 한 곳에 모아둔다.

import Foundation

public enum TravelerLinking {
    public static func linkedAlbumIds(
        tripPhotoIds: Set<String>,
        candidates: [(id: UUID, photoIds: Set<String>)]
    ) -> [UUID] {
        candidates
            .filter { !$0.photoIds.isDisjoint(with: tripPhotoIds) }
            .map { $0.id }
    }
}
