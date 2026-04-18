//
//  BaseDTO.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import Foundation

struct BaseDTO<T: Decodable>: Decodable {
    let result: Bool
    let data: T?
}

struct BaseNil: Decodable {
}

