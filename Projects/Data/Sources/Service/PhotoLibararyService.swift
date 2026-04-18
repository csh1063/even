//
//  PhotoLibraryService.swift
//  Data
//
//  Created by sanghyeon on 3/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain
import Photos
import PhotosUI

public final class PhotoLibraryService {
    
    private let imageManager = PHCachingImageManager()
    
    private var pHResultMap: [PHCollection: PHFetchResult<PHAsset>] = [:]
    private var allPhotos: PHFetchResult<PHAsset>?
    
//    private var assetCache: [String: PHAsset] = [:]
    private let assetCache = AssetCache()
    
    public init() {}
    
    public func getAlbumList() async throws -> [AlbumAssetEntity] {
        
        return await Task.detached(priority: .userInitiated) {
            
            var albumModelList: [AlbumAssetEntity] = [AlbumAssetEntity]()
            
            let favoriteAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                         subtype: .smartAlbumFavorites, options: nil)
            let allAlbum = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                   subtype: .smartAlbumUserLibrary,
                                                                   options: nil)
            let selfiesAlbum = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                       subtype: .smartAlbumSelfPortraits,
                                                                       options: nil)
            let panoramaAlbum = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                        subtype: .smartAlbumPanoramas,
                                                                        options: nil)
            let burstAlbum = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                     subtype: .smartAlbumBursts, options: nil)
            let screenShotAlbum = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                          subtype: .smartAlbumScreenshots,
                                                                          options: nil)
            let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)

            let albums = [allAlbum, favoriteAlbums, selfiesAlbum,
                          panoramaAlbum, burstAlbum, screenShotAlbum, userAlbums]
            for album in albums {
                album.enumerateObjects { (collection, _, _) -> Void in
                    let opt = PHFetchOptions()
                    let assets = PHAsset.fetchAssets(in: collection, options: opt)
                    if assets.count > 0 {
                        let fetchOptions = PHFetchOptions()
                        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                        
                        let newAlbum = AlbumAssetEntity(
                            name: collection.localizedTitle ?? "",
                            count: assets.count,
                            collection: collection)
                        
                        albumModelList.append(newAlbum)
                    }
                }
            }
            
            return albumModelList
        }.value
    }

    public func getPhotoList(from collection: PHAssetCollection? = nil, page: Int, reload: Bool = false) async throws -> PhotoAssetListEntity {
        
        let realPage = max(1, page)
        let countPerPage = 300
        let start = (realPage - 1) * countPerPage
//        let end = start + countPerPage
        
        let result: PHFetchResult<PHAsset>
        
        if let collection {
            if let savedResult = self.pHResultMap[collection], !reload {
                result = savedResult
            } else {
                result = PHAsset.fetchAssets(in: collection, options: .defaultOptions)
                self.pHResultMap[collection] = result
            }
        } else {
            if let savedAll = self.allPhotos, !reload {
                result = savedAll
            } else {
                result = PHAsset.fetchAssets(with: .image, options: .defaultOptions)
            }
        }
        
        let totalCount = result.count
        let rangeStart = min(start, totalCount)
//        let rangeEnd = min(end, totalCount)
        let rangeEnd = totalCount
        
        let photos = (rangeStart..<rangeEnd).map { index -> PhotoAssetEntity in
            let asset = result.object(at: index)
            
//            self.assetCache[asset.localIdentifier] = asset
            Task {
                await self.assetCache.set(asset.localIdentifier, asset: asset)
            }
            return PhotoAssetEntity(asset: asset)
        }
        
        let sortedPhotos = photos.sorted {
            let created0 = $0.asset.creationDate ?? Date.distantPast
            let created1 = $1.asset.creationDate ?? Date.distantPast
            
            if created0 == created1 {
                return $0.asset.modificationDate ?? Date.distantPast
                    > $1.asset.modificationDate ?? Date.distantPast
            } else {
                return created0 > created1
            }
        }
        
        return PhotoAssetListEntity(
            title: collection?.localizedTitle ?? "",
            photos: sortedPhotos,
            hasNext: false//rangeEnd < totalCount
        )
    }
    
    public func loadImage(id: String, type: LoadPhotoOptionType) async throws -> CGImage? {
        guard let asset = await getAsset(id: id) else { return nil }
        
        let options = PHImageRequestOptions()
        let size: CGSize
        let contentMode: PHImageContentMode
        switch type {
        case .maxSize:
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            size = PHImageManagerMaximumSize
            contentMode = .default
        case .specialSize(let specialSize):
            options.resizeMode = .fast
            options.deliveryMode = .opportunistic
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            size = specialSize
            contentMode = .aspectFit
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: contentMode,
                options: options) { image, info in
                    // 최종 결과인지 확인
                    let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                    if isDegraded { return }  // 저화질이면 무시

                    if let error = info?[PHImageErrorKey] as? Error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: image?.cgImage)
            }
        }
    }

    public func getLocationPhoto(ids: [String]) async throws -> [PHAsset] {
        let assets = PHAsset.fetchAssets(
            withLocalIdentifiers: ids,
            options: nil
        )
        
        var photosWithLocation: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in
            if asset.location != nil {
                photosWithLocation.append(asset)
            }
        }
        return photosWithLocation
    }
    
    private func getAsset(id: String) async -> PHAsset? {
        
//        if let cached = assetCache[id] { return cached }
        if let cached = await assetCache.get(id) { return cached }
        
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
        if let asset = fetched {
            await assetCache.set(id, asset: asset)
        }
//        if let asset = fetched {
//            self.assetCache[id] = asset
//        }
        return fetched
    }
    
    func startCaching(for assets: [PHAsset], targetSize: CGSize) {
        imageManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
    
    func stopCaching(for assets: [PHAsset], targetSize: CGSize) {
        imageManager.stopCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
}

extension PHFetchOptions {
    static var defaultOptions: PHFetchOptions {
        let option = PHFetchOptions()
        option.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false),
            NSSortDescriptor(key: "modificationDate", ascending: false)
        ]
        option.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        return option
    }
}

actor AssetCache {
    private var cache: [String: PHAsset] = [:]
    
    func get(_ id: String) -> PHAsset? { cache[id] }
    func set(_ id: String, asset: PHAsset) { cache[id] = asset }
}
