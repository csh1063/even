////
////  SwiftDataStack.swift
////  Data
////
////  Created by sanghyeon on 3/21/26.
////  Copyright © 2026 sanghyeon. All rights reserved.
////
//
//import SwiftData
//// Data 모듈
//public final class SwiftDataStack {
//    
//    public static let shared = SwiftDataStack()
//    
//    public let container: ModelContainer
//    
//    public init() {
//        let schema = Schema([
//            PhotoEntity.self,
//            FolderEntity.self,
//            FolderPhotoMapEntity.self,
//            PhotoLabelEntity.self,
//            FolderKeywordEntity.self
//        ])
//        
//        let config = ModelConfiguration(
//            schema: schema,
//            isStoredInMemoryOnly: false
//        )
//        
//        do {
//            container = try ModelContainer(for: schema, configurations: config)
//        } catch {
//            fatalError("SwiftData 초기화 실패: \(error)")
//        }
//    }
//    
//    public var context: ModelContext {
//        ModelContext(container)
//    }
//}
