//
//  AlertViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 3/29/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import Foundation

final class AlertViewModel {
    let title: String?
    let message: String?
    let buttons: [AlertButtonConfig]

    init(item: AlertItem) {
        self.title   = item.title
        self.message = item.message
        self.buttons = item.buttons
    }
}