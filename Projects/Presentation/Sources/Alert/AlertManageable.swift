//
//  AlertManageable.swift
//  Presentation
//
//  Created by sanghyeon on 3/29/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


public protocol AlertManageable {
    func enqueue(title: String?, message: String?, buttons: [AlertButtonConfig])
}

extension AlertManager: AlertManageable {}
