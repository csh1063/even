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
    private let isLabel: Bool
    private let useCase: PhotoLabelUseCase
    private var cancellables = Set<AnyCancellable>()

    var pop: (() -> Void)?

    public init(isLabel: Bool, useCase: PhotoLabelUseCase, pop: (() -> Void)?) {
        self.isLabel = isLabel
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
        self.input.sink { [weak self] input in
            guard let self else { return }
            Task { @MainActor in await self.handle(input) }
        }
        .store(in: &cancellables)

    }

    private func handle(_ input: Input) async {
        switch input {
        case .appear:
            if isLabel {
                await self.loadLabels()
            } else {
                await self.loadAddressCount()
            }
        }
    }

    private func loadLabels() async {

        do {
            print("start loadLabels")
            self.isLoading = true
//            self.photoLabels = try await self.useCase.fetchUniqueNames()
            let tuple = try await self.useCase.fetchLabelCounts()

            self.photoLabels = tuple.map { "\($0.name): \($0.count)" }

            print("end loadLabels")
            print(photoLabels)

            self.isLoading = false
        } catch {
            print("error:", error.localizedDescription)
        }
    }

    private func loadAddressCount() async {

        do {
            print("start loadLabels")
            self.isLoading = true

            let tuple = try await self.useCase.fetchAddressCounts()

            self.photoLabels = tuple.map { "\($0.name): \($0.count)" }

            print("end loadLabels")
            print(photoLabels)

            self.isLoading = false
        } catch {
            print("error:", error.localizedDescription)
        }
    }
}
