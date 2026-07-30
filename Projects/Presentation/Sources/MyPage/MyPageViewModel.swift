//
//  MyPageViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Combine
import Domain
import UIKit

enum MyPageViewModelAction {
    case move(MyCellData)
}

final class MyPageViewModel: BaseViewModel {

    enum Input {
        case appear
        case analysis
        case clear
        case selectItem(MyCellData)
    }

    struct Output {
        let cellTyps: AnyPublisher<[MyCellHeader: [MyCellData]], Never>
    }

    @Published private var cellTypes: [MyCellHeader: [MyCellData]] = [:]
    private var libraryCount: Int = 0
    private var photoCount: Int = 0
    private var analyzedDate: String = "-"
    private var analyzedDataSize: String = ""
    private var unanalysisCount: Int = 0
    private var photoPermission: String = ""
    private var displayMode: String = ""
    private var version: String = ""

    let input = PassthroughSubject<Input, Never>()

    var onAction: ((MyPageViewModelAction) -> Void)?

    private var tabbarViewModel: TabbarViewModel
    private var myPageUseCase: MyPageUseCase
    private var cancellables = Set<AnyCancellable>()

    init(tabbarViewModel: TabbarViewModel, myPageUseCase: MyPageUseCase) {
        self.tabbarViewModel = tabbarViewModel
        self.myPageUseCase = myPageUseCase

        super.init()

        self.cells()
        self.bind()
    }

    func transform() -> Output {
        return Output(
            cellTyps: $cellTypes.eraseToAnyPublisher()
        )
    }

    func send(_ input: Input) {
        self.input.send(input)
    }

    private func bind() {
        self.input.sink { [weak self] input in
            guard let self else { return }
            Task { @MainActor in await self.handle(input) }
        }
        .store(in: &cancellables)

        self.tabbarViewModel.transform()
            .isComplete
            .sink { isComplete in
                if isComplete {
                    self.send(.appear)
                }
            }
            .store(in: &cancellables)
    }

    private func handle(_ input: Input) async {
        switch input {
        case .appear:
            await loadAll()
        case .analysis:
            tabbarViewModel.send(.analysis)
        case .clear:
            tabbarViewModel.send(.clear)
        case let .selectItem(data):
            switch data.type {
            case .allLibraryPhoto, .allPhoto, .unanalysisPhoto, .analyzedDate: break
            case .analysis: tabbarViewModel.send(.analysis)
            case .reAutoAlbum: tabbarViewModel.send(.reAutoAlbum)
            case .reset: tabbarViewModel.send(.clear)
            case .locationAnalysis, .locationAutoAlbum: break
            case .autoAnalysis: break // toggle
            case .photoPermission:
                showAlert(
                    title: "사진 접근 권한",
                    message: "설정에서 사진 접근 권한을 변경할 수 있어요.",
                    buttons: [
                        AlertButtonConfig(title: "취소", style: .cancel, action: nil),
                        AlertButtonConfig(title: "설정으로 이동", style: .default) {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(url)
                        }
                    ]
                )
            case .version: break
            case .displayMode:
                await self.nextDisplayMode()
            default:
                self.onAction?(.move(data))
            }
        }
    }

    func changeDisplayMode(_ mode: String) async {
        do {
            let value = DisplayMode.from(mode).rawValue
            try await myPageUseCase.changeDisplayMode(value)

            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) {

                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                    window.overrideUserInterfaceStyle = DisplayMode(value).style
                }
            }

            self.displayMode = DisplayMode(value).text
            self.cells()
        } catch {
            debugLog("error: \(error.localizedDescription)")
        }
    }

    private func nextDisplayMode() async {
        let nextMode = DisplayMode.from(self.displayMode).next.text
        await self.changeDisplayMode(nextMode)
    }

    private func loadAll() async {
        do {
            self.isLoading = true
            async let count = myPageUseCase.photoCount()
            async let date = myPageUseCase.lastAnalyzeDate()
            async let unanalysis = myPageUseCase.photoUnanalysisCount()
            async let permission = myPageUseCase.checkPermission()
            async let displayMode = myPageUseCase.getDisplayMode()
            async let dataSize = myPageUseCase.analysisDataSize()
            self.photoCount = try await count
            self.analyzedDate = relativeDate(from: try await date)
            self.unanalysisCount = try await unanalysis
            // SwiftData 스토어는 완전히 비어도 테이블/인덱스 최소 페이지 크기 때문에 수백 KB가
            // 남는다 — 이 정도는 사용자에게 "삭제됐는데 왜 안 지워졌지"로 보일 뿐이라 0으로 취급.
            // ByteCountFormatter는 0바이트를 "Zero KB"라는 특수 문구로 표시해서, 0인 경우는
            // 포매터를 거치지 않고 직접 문자열로 표시한다.
            let rawDataSize = try await dataSize
            self.analyzedDataSize = rawDataSize < 500_000
                ? "0MB"
                : ByteCountFormatter.string(fromByteCount: rawDataSize, countStyle: .file)

            switch try await permission {
            case .fullAccess:
                self.photoPermission = "전체 허용"
            case .limitedAccess:
                self.photoPermission = "일부 허용"
            default:
                self.photoPermission = "거부"
            }

            self.displayMode = DisplayMode(try await displayMode).text
            self.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

            self.isLoading = false

            self.cells()
        } catch {

        }
    }

    private func cells() {

        var analyzedItems = if analyzedDate == "-" {
            [
                MyCellData(type: .analyzedDate, value: analyzedDate),
                MyCellData(type: .analyzedData, value: analyzedDataSize),
                MyCellData(type: .analysis)
            ]
        } else {
            [
                MyCellData(type: .analyzedDate, value: analyzedDate),
                MyCellData(type: .analyzedData, value: analyzedDataSize),
                MyCellData(type: .analysis),
                MyCellData(type: .reAutoAlbum)
            ]
        }

        // 분석이 중간에 끊겨 analyzedDate가 아직 "-"여도, 조금이라도 분석된 사진이 있으면 reset은 보여준다
        if photoCount > unanalysisCount {
            analyzedItems.append(MyCellData(type: .reset))
        }

        self.cellTypes = [
            MyCellHeader(name: "내 라이브러리", order: 0): [
                MyCellData(type: .allPhoto, value: "\(photoCount.formatted())장"),
                MyCellData(type: .unanalysisPhoto, value: "\(unanalysisCount.formatted())장")
            ],
            MyCellHeader(name: "사진 분석", order: 10): analyzedItems,
//            MyCellHeader(name: "백 그라운드 작업", order: 20): [
//                MyCellData(type: .locationAnalysis, value: "-", isOn: false),
//                MyCellData(type: .locationAutoAlbum, value: "-", isOn: false)
//            ],
//            MyCellHeader(name: "정리 옵션", order: 30): [
//                MyCellData(type: .autoAnalysis, isOn: false, isPrimary: false),
//                MyCellData(type: .continueLocation, isOn: false, isPrimary: false),
//            ],
            MyCellHeader(name: "접근 및 권한", order: 40): [
                MyCellData(type: .terms),
                MyCellData(type: .privacy),
                MyCellData(type: .openSource),
                MyCellData(type: .photoPermission, value: self.photoPermission)
            ],
            MyCellHeader(name: "앱 설정", order: 50): [
                MyCellData(type: .displayMode, value: displayMode),
                MyCellData(type: .feedback),
                MyCellData(type: .version, value: version)
            ]
        ]
        
        #if DEBUG
        self.cellTypes[MyCellHeader(name: "실험실", order: 60)] = [
            MyCellData(type: .labels),
            MyCellData(type: .test),
            MyCellData(type: .addressCount)
        ]
        #endif
    }

    private func relativeDate(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        guard let date = formatter.date(from: dateString) else { return "-" }

        let calendar = Calendar.current
        let now = Date()
        let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        let weeks = days / 7

        switch days {
        case 0: return "오늘"
        case 1: return "어제"
        case 2...6: return "\(days)일 전"
        case 7...27:
            return weeks == 1 ? "1주 전" : "\(weeks)주 전"
        default:
            let output = DateFormatter()
            output.dateFormat = "yyyy.MM.dd"
            return output.string(from: date)
        }
    }
}
