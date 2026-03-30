//
//  BaseViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 3/29/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import Combine

@MainActor
open class BaseViewModel {
    // 모든 ViewModel이 공유하는 alert 스트림
    let alertPublisher = PassthroughSubject<AlertItem, Never>()

    func showAlert(title: String?, message: String? = nil, buttons: [AlertButtonConfig]) {
        let item = AlertItem(title: title, message: message, buttons: buttons)
        alertPublisher.send(item)
    }
}
