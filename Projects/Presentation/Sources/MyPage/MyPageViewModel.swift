//
//  MyPageViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Combine

public final class MyPageViewModel: BaseViewModel {
    
    enum Input {
        
    }
    
    struct Output {
        
    }
    
    let input = PassthroughSubject<Input, Never>()
    var output: Output
    
    private var cancellable = Set<AnyCancellable>()
    
    override init() {
        self.output = Output()
        
        super.init()
        
        self.bind()
    }
    
    func bind() {
        self.input.sink { input in
            
        }
        .store(in: &cancellable)
    }
}
