//
//  Photo.swift
//  Data
//
//  Created by sanghyeon on 3/16/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import SwiftData
import Foundation

//@Model
//class Photo {
//    @Attribute(.unique) var id: UUID
//    var localIdentifier: String  // Photos 라이브러리 참조
//    var createdAt: Date
//    var analyzedAt: Date?
//    var dominantColor: String?   // HEX 저장 ex) "#FF5733"
//    
//    @Relationship(deleteRule: .cascade)
//    var labels: [PhotoLabel] = []
//    
//    @Relationship(deleteRule: .nullify)
//    var folderMappings: [FolderPhotoMap] = []
//    
//    init(localIdentifier: String) {
//        self.id = UUID()
//        self.localIdentifier = localIdentifier
//        self.createdAt = Date()
//    }
//}
