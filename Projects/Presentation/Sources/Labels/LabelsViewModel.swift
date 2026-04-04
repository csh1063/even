//
//  LabelsViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain
import Combine

public final class LabelsViewModel: BaseViewModel {
    
    enum Input {
        case appear
    }
    
    struct Output {
        var photoLabels: AnyPublisher<[String], Never>
    }
    
    @Published private var photoLabels: [String] = []
    
    private let input = PassthroughSubject<Input, Never>()
    private let useCase: PhotoLabelUseCase
    private var cancellables = Set<AnyCancellable>()
    
    var pop: (() -> Void)?
    
    public init(useCase: PhotoLabelUseCase, pop: (() -> Void)?) {
        self.useCase = useCase
        self.pop = pop
        
        super.init()
        
        self.bind()
    }
    
    func send(_ input: Input) {
        self.input.send(input)
    }
    
    func transform() -> Output {
        return Output(
            photoLabels: $photoLabels.eraseToAnyPublisher()
        )
    }
    
    private func bind() {
        self.input.sink { input in
                Task {
                    await self.hander(input)
                }
            }
            .store(in: &cancellables)

    }
    
    private func hander(_ input: Input) async {
        switch input {
        case .appear:
            await self.loadLabels()
        }
    }
    
    private func loadLabels() async {
        
        do {
            print("start loadLabels")
            self.photoLabels = try await self.useCase.fetchUniqueNames()
            print("end loadLabels")
            print(photoLabels)
        } catch {
            print("error:", error.localizedDescription)
        }
    }
}
