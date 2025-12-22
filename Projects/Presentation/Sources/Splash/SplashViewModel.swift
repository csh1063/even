//
//  SplashViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Combine

public final class SplashViewModel {
    
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
    
    public init() {
        self.output = Output(finished: finishedSubject.eraseToAnyPublisher())
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
            guard let self = self else { return }
            
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3초 (1초 = 1_000_000_000 ns)
            self.finishedSubject.send(true)
        }
    }
}
