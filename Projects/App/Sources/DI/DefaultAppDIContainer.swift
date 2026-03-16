//
//  DefaultAppDIContainer.swift
//  App
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Presentation
import Data
import Domain

@MainActor
final class DefaultAppDIContainer: AppDIContainer {
    
    init() {
        
    }
    
    // MARK: Splash
    func makeSplashRepository() {
        
    }
    
    func makeSplashUsecase() {
        
    }
    
    func makeSplashViewModel() -> SplashViewModel {
        SplashViewModel()
    }
    
    // MARK: Main
    func makeMainRepository() {
        
    }
    
    func makeMainUsecase() {
        
    }
    
    func makeMainViewModel() -> MainViewModel {
        MainViewModel()
    }
    
    // MARK: Home
    func makeHomeRepository() -> PhotoLibararyRepository {
        let service = PhotoLibararyService()
        return DefaultPhotoLibararyRepository(service: service)
    }
    
    func makeHomeUsecase() -> PhotoLibraryUsecase {
        return DefaultPhotoLibraryUsecase(repository: makeHomeRepository())
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(usecase: makeHomeUsecase())
    }
}
