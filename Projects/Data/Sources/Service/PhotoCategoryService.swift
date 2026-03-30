//
//  PhotoCategoryService.swift
//  Data
//
//  Created by sanghyeon on 3/29/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

final class PhotoCategoryService {
    
    // MARK: - 단어 목록 로드
    private var photoCategories: [String: [String]] = {
        let bundle = Bundle(for: PhotoCategoryService.self)
        guard let url = bundle.url(forResource: "PhotoCategories", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let array = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return [:] }
        return array
    }()
    
}
