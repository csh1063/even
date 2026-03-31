//
//  AppDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public protocol AppDIContainer {
    
    var photoLibraryRepository: PhotoLibraryRepository {get}
    var photoAnalysisRepository: PhotoAnalysisRepository {get}
    var photoDataRepository: PhotoDataRepository {get}
    var folderDataRepository: FolderDataRepository {get}
    var photoLabelDataRepository: PhotoLabelDataRepository {get}
    
    func makeSplashViewModel() -> SplashViewModel
    func makeMainViewModel() -> MainViewModel
    func makePhotoLibraryDIContainer() -> PhotoLibraryDIContainer
    func makeAlbumDIContainer() -> AlbumDIContainer
    func makeMyPageDIContainer() -> MyPageDIContainer
}

