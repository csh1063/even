//
//  FeedbackType.swift
//  Presentation
//
//  Created by sanghyeon on 5/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine
import Domain

enum FeedbackType: String, CaseIterable {
    case contact = "contact"
    case feature = "feature"
    case bug = "bug"

    var title: String {
        switch self {
        case .contact: return "문의하기"
        case .feature: return "기능 제안"
        case .bug: return "버그 신고"
        }
    }
}

final class FeedbackViewModel: BaseViewModel {

    enum Input {
        case changeSegment(FeedbackType)
        case changeText(String)
    }

    struct Output {
        let isSubmitEnabled: AnyPublisher<Bool, Never>
        let submitResult: AnyPublisher<Result<Void, Error>?, Never>
        let isLoading: AnyPublisher<Bool, Never>
    }

    private var selectedType: FeedbackType = .contact
    private var content: String = ""

    @Published private var isSubmitEnabled: Bool = false
    @Published private var submitResult: Result<Void, Error>?

    private let input = PassthroughSubject<Input, Never>()

    private let useCase: FeedbackUseCase
    private var cancellables = Set<AnyCancellable>()

    init(useCase: FeedbackUseCase) {
        self.useCase = useCase

        super.init()
        self.bind()
    }

    func send(_ input: Input) {
        self.input.send(input)
    }

    func transForm() -> Output {
        Output(
            isSubmitEnabled: $isSubmitEnabled.eraseToAnyPublisher(),
            submitResult: $submitResult.eraseToAnyPublisher(),
            isLoading: $isLoading.eraseToAnyPublisher()
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
        case .changeSegment(let type):
            self.selectedType = type
        case .changeText(let text):
            content = text
            isSubmitEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    func submit() async {
        guard isSubmitEnabled else { return }
        isLoading = true

        do {
            try await useCase.writeFeedback(
                type: selectedType.rawValue,
                content: content.trimmingCharacters(in: .whitespacesAndNewlines))
            submitResult = .success(())
        } catch {
            debugLog("피드백 제출 실패: \(error.localizedDescription)")
            submitResult = .failure(error)
        }

        isLoading = false
    }
}
