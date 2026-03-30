//
//  SplashViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Combine

@MainActor
public final class SplashViewModel: BaseViewModel {
    
    enum Input {
        case viewWillAppear
    }
    
    struct Output {
        let finished: AnyPublisher<Bool, Never>
    }
    
    let input = PassthroughSubject<Input, Never>()
    var output: Output
    
    private let finishedSubject = PassthroughSubject<Bool, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        self.output = Output(finished: finishedSubject.eraseToAnyPublisher())
        
        super.init()
        
        self.bind()
    }
    
    func bind() {
        input.sink { [weak self] input in
            switch input {
            case .viewWillAppear: self?.start()
            }
        }
        .store(in: &cancellables)
    }

    private func start() {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3초 (1초 = 1_000_000_000 ns)
//            showAlert(
//                title: "진행?",
//                message: "진행 고고?",
//                buttons: [
//                    AlertButtonConfig(title: "껃영", style: .destructive, action: nil),
//                    AlertButtonConfig(title: "고고", style: .default) { [weak self] in
                        self?.finishedSubject.send(true)
//                    }
//                ]
//            )
        }
    }
}
