//
//  MainViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Combine

public final class MainViewModel: BaseViewModel {
    
    enum Input {
        case clickLogout
    }
    
    struct Output {
        public let logout: AnyPublisher<Void, Never>
    }
    
    let input = PassthroughSubject<Input, Never>()
    var output: Output
    
    let logoutSubject = PassthroughSubject<Void, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        self.output = Output(
            logout: logoutSubject.eraseToAnyPublisher()
        )
        
        super.init()
        
        self.bind()
    }
    
    private func bind() {
        self.input.sink { [weak self] input in
            switch input {
            case .clickLogout:
                self?.logout()
            }
        }
        .store(in: &cancellables)
    }
    
    private func logout() {
        Task {
            self.logoutSubject.send()
        }
    }
}
