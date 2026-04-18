//
//  MyPageViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Combine

final class MyPageViewModel: BaseViewModel {
    
    enum Input {
        case appear
        case selectItem(MyPageCellType)
    }
    
    struct Output {
        let cellTyps: AnyPublisher<[MyPageCellType], Never>
    }
    
    @Published private var cellTypes: [MyPageCellType] = []
    
    let input = PassthroughSubject<Input, Never>()
    
    private var coordinator: MyPageCoordinator?
    private var cancellables = Set<AnyCancellable>()
    
    init(coordinator: MyPageCoordinator) {
        self.coordinator = coordinator
        
        super.init()

        self.cellTypes = MyPageCellType.allCases// fetchCellTypes()
        self.bind()
    }
    
    func transform() -> Output {
        return Output (
            cellTyps: $cellTypes.eraseToAnyPublisher()
        )
    }
    
    func send(_ input: Input) {
        self.input.send(input)
    }
    
    func bind() {
        self.input.sink { input in
            Task {
                await self.handle(input)
            }
        }
        .store(in: &cancellables)
    }
    
    private func handle(_ input: Input) async {
        switch input {
        case .appear: break
        case let .selectItem(type):
            print("gogo", type)
            switch type {
            case .labels:
                self.coordinator?.moveLabels()
            case .test:
                self.coordinator?.moveTest()
            }
        }
    }
    
//    private func fetchCellTypes() -> [MyPageCellType] {
//        return [
//            .labels, .test
//        ]
//    }
}
