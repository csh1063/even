////
////  PhotoMapper.swift
////  Data
////
////  Created by sanghyeon on 2/25/26.
////  Copyright © 2026 sanghyeon. All rights reserved.
////
//
//import Foundation
//import Domain
//
//extension PhotoEntity {
//
////    func toDomain() -> Photo {
////        Photo(
////            id: id ?? UUID(),
////            assetIdentifier: assetIdentifier ?? "",
////            tags: (tags?.allObjects as? [TagEntity] ?? []).map { $0.toDomain() } 
////        )
////    }
////
////    func update(from photo: Photo) {
////        id = photo.id
////        assetIdentifier = photo.assetIdentifier
////
////        // Tags
////        let currentTags = (tags?.allObjects as? [TagEntity]) ?? []
////        for tag in currentTags {
////            managedObjectContext?.delete(tag)
////        }
////        let tagEntities = photo.tags.map { tag -> TagEntity in
////            let entity = TagEntity(context: managedObjectContext!)
////            entity.update(from: tag)
////            return entity
////        }
////        tags = NSSet(array: tagEntities)
////    }
//}
