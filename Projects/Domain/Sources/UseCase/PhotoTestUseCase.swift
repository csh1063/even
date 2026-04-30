//
//  PhotoTestUseCase.swift
//  Domain
//
//  Created by sanghyeon on 4/8/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoTestUseCase {
    func countByPsition() async throws
    func countIsKorea() async throws
    func getAddressByCoordinate() async throws
}

final public class DefaultPhotoTestUseCase: PhotoTestUseCase {
    
    private let repository: PhotoDataRepository
    private let geoRepository: GeoRepository
    
    public init(repository: PhotoDataRepository, geoRepository: GeoRepository) {
        self.repository = repository
        self.geoRepository = geoRepository
    }
    
    public func countByPsition() async throws {
        
        let photos = try repository.fetchPhotos()
        let unique = Dictionary(grouping: photos) {
            if let latitude = $0.latitude, let longitude = $0.longitude {
                let lat = (latitude * 10000).rounded() / 10000
                let lng = (longitude * 10000).rounded() / 10000
                return "lat: \(lat), long: \(lng)"
            } else {
                return ""
            }
        }
        
        for (key, value) in unique {
            print("photo", key, ":", value.count)
        }
        print("unique total", unique.count)
    }
    
    public func countIsKorea() async throws {
        let photos = try repository.fetchPhotos()
        
        let unique = Dictionary(grouping: photos) {
            if let latitude = $0.latitude, let longitude = $0.longitude {
                if isKorea(latitude: latitude, longitude: longitude) {
                    return "is korea"
                } else {
                    return "no korea"
                }
            } else {
                return ""
            }
        }
        for (key, value) in unique {
            print("photo", key, ":", value.count)
        }
    }
    
    public func getAddressByCoordinate() async throws {
        let photos = try repository.fetchPhotos()
        let koreaPhotos = photos.filter {
            if let latitude = $0.latitude, let longitude = $0.longitude {
                return isKorea(latitude: latitude, longitude: longitude)
            }
            return false
        }
        
        let address = try await self.geoRepository.locationToaddress(koreaPhotos)
        
        for (id, value) in address {
            print("id:", id,
                  ", value:", value.administrativeArea ?? "??",
                  ", ", value.locality ?? "??",
                  ", ", value.subLocality ?? "??",
                  ", ", value.thoroughfare ?? "??")
        }
    }
    
    private func isKorea(latitude: Double, longitude: Double) -> Bool {
        // 한국 바운딩 박스로 1차 필터 — 폴리곤 순회보다 훨씬 빠름
        return (32.0...39.5).contains(latitude) &&
               (123.5...132.5).contains(longitude)
    }
}
