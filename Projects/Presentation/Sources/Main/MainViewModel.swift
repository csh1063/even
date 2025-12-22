//
//  MainViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Combine

public final class MainViewModel {
    
    enum Input {
        
    }
    
    struct Output {
        
    }
    
    let input = PassthroughSubject<Input, Never>()
    var output: Output
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        self.output = Output()
        self.bind()
    }
    
    private func bind() {
        self.input.sink { input in
            
        }
        .store(in: &cancellables)
    }
}
