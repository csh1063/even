//
//  UserDefaultsService.swift
//  Data
//
//  Created by sanghyeon on 5/1/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public final class UserDefaultsService {
    private let defaults = UserDefaults.standard
    
    public func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    public func set(_ v: String, forK k: String) {
        defaults.set(v, forKey: k)
    }

    public func set(_ v: Int, forK k: String) {
        defaults.set(v, forKey: k)
    }
    
    public func set(_ v: Bool, forK k: String) {
        defaults.set(v, forKey: k)
    }
    
    public func string(_ k: String) -> String {
        return defaults.string(forKey: k) ?? ""
    }
    
    public func int(_ k: String) -> Int {
        return defaults.integer(forKey: k)
    }
    
    public func bool(_ k: String) -> Bool? {
        return defaults.bool(forKey: k)
    }
    
    public func get(forKey key: String) -> Any? {
        defaults.object(forKey: key)
    }
    
    public func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
