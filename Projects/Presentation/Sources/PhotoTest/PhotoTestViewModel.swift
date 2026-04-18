//
//  PhotoTestViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 4/8/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain
import Combine

@MainActor
public final class PhotoTestViewModel: BaseViewModel {
    
    enum Input {
        case sameCount
        case koreanCount
        case coorToAddress
    }
    
    struct Output {
        
    }
    
    var pop: (() -> Void)?
    
    private let input = PassthroughSubject<Input, Never>()
    private let useCase: PhotoTestUseCase
    private var cancellables = Set<AnyCancellable>()
    
    public init(useCase: PhotoTestUseCase, pop: (() -> Void)?) {
        self.useCase = useCase
        self.pop = pop
        
        super.init()
        
        self.bind()
    }
    
    func send(_ input: Input) {
        self.input.send(input)
    }
    
    private func bind() {
        self.input.sink { [weak self] input in
            guard let self else { return }
            Task { await self.handle(input) }
        }
        .store(in: &cancellables)
    }
    
    private func handle(_ input: Input) async {
        switch input {
        case .sameCount:
            print("start sameCount")
            do {
                try await self.useCase.countByPsition()
            } catch {
                print("error", error.localizedDescription)
            }
        case .koreanCount:
            print("start koreanCount")
            do {
                try await self.useCase.countIsKorea()
            } catch {
                print("error", error.localizedDescription)
            }
        case .coorToAddress:
            print("start coorToAddress")
            do {
                try await self.useCase.getAddressByCoordinate()
            } catch {
                print("error", error.localizedDescription)
            }
        }
    }
}
