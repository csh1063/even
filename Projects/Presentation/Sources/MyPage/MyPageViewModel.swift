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
    private var analyzedDate: String = ""
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
        return Output (
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
            print("gogo", data)
            switch data.type {
            case .allLibraryPhoto, .allPhoto, .unanalysisPhoto, .analyzedDate: break
            case .analysis: tabbarViewModel.send(.analysis)
            case .reAnalysis: tabbarViewModel.send(.reanalysis)
            case .reset: tabbarViewModel.send(.clear)
            case .locationAnalysis, .locationAutoFolder: break
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
                await self.testDisplayMode()
            default:
                self.onAction?(.move(data))
            }
        }
    }
    
    private func testDisplayMode() async {
        do {
            let mode = try await myPageUseCase.nextDisplayMode()
            
            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) {
                
                switch mode {
                case "dark":
                    window.overrideUserInterfaceStyle = .dark
                case "light":
                    window.overrideUserInterfaceStyle = .light
                default:
                    window.overrideUserInterfaceStyle = .unspecified
                }
            }
            
            switch mode {
            case "light":
                self.displayMode = "라이트"
            case "dark":
                self.displayMode = "다크"
            default:
                self.displayMode = "시스템 설정"
            }
            self.cells()
        } catch  {
            print("error", error.localizedDescription)
        }
    }
    
    private func loadAll() async {
        do {
            async let count = myPageUseCase.photoCount()
            async let date = myPageUseCase.lastAnalyzeDate()
            async let unanalysis = myPageUseCase.photoUnanalysisCount()
            async let displayMode = myPageUseCase.getDisplayMode()
            self.photoCount = try await count
            self.analyzedDate = relativeDate(from: try await date)
            self.unanalysisCount = try await unanalysis
            
            self.photoPermission = "허용"
            
            switch try await displayMode {
            case "light":
                self.displayMode = "라이트"
            case "dark":
                self.displayMode = "다크"
            default:
                self.displayMode = "시스템 설정"
            }
            self.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            
            self.cells()
        } catch {
            
        }
    }
    
    private func cells() {
        
        self.cellTypes = [
            MyCellHeader(name: "내 라이브러리", order: 0): [
                MyCellData(type: .allPhoto, value: "\(photoCount.formatted())장"),
                MyCellData(type: .unanalysisPhoto, value: "\(unanalysisCount.formatted())장")
            ],
            MyCellHeader(name: "사진 분석", order: 10): [
                MyCellData(type: .analyzedDate, value: analyzedDate),
                MyCellData(type: .analysis),
                MyCellData(type: .reAnalysis),
                MyCellData(type: .reset)
            ],
            MyCellHeader(name: "백 그라운드 작업", order: 20): [
                MyCellData(type: .locationAnalysis, value: "-", isOn: false),
                MyCellData(type: .locationAutoFolder, value: "-", isOn: false)
            ],
            MyCellHeader(name: "정리 옵션", order: 30): [
                MyCellData(type: .autoAnalysis, isOn: true, isPrimary: false),
            ],
            MyCellHeader(name: "접근 및 권한", order: 40): [
                MyCellData(type: .terms),
                MyCellData(type: .privacy),
                MyCellData(type: .photoPermission, value: self.photoPermission)
            ],
            MyCellHeader(name: "앱 설정", order: 50): [
                MyCellData(type: .displayMode, value: displayMode),
                MyCellData(type: .feedback),
                MyCellData(type: .version, value: version)
            ],
            MyCellHeader(name: "실험실", order: 60): [
                MyCellData(type: .labels),
                MyCellData(type: .test)
            ]
        ]
    }
    
    private func relativeDate(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        guard let date = formatter.date(from: dateString) else { return dateString }
        
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
