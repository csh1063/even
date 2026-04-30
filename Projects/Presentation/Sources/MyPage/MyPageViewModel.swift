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

enum MyPageViewModelAction {
    case move(MyPageCellType)
}

final class MyPageViewModel: BaseViewModel {
    
    enum Input {
        case appear
        case analysis
        case clear
        case selectItem(MyPageCellType)
    }
    
    struct Output {
        let cellTyps: AnyPublisher<[MyCellHeader: [MyCellData]], Never>
    }
    
    @Published private var cellTypes: [MyCellHeader: [MyCellData]] = [:]
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
        case .appear:
            await loadAll()
        case .analysis:
            tabbarViewModel.send(.analysis)
        case .clear:
            tabbarViewModel.send(.clear)
        case let .selectItem(type):
            print("gogo", type)
            self.onAction?(.move(type))
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
            MyCellHeader(name: "내 라이브러리", order: 1): [
                MyCellData(type: .allPhoto, value: "\(photoCount.formatted())장"),
                MyCellData(type: .analysisDate, value: analyzedDate),
                MyCellData(type: .unanalysisPhoto, value: "\(unanalysisCount.formatted())장")
            ],
            MyCellHeader(name: "백 그라운드 작업", order: 2): [
                MyCellData(type: .locationAnalysis, value: "-", isOn: false),
                MyCellData(type: .locationAutoFolder, value: "-", isOn: false)
            ],
            MyCellHeader(name: "정리 옵션", order: 3): [
                MyCellData(type: .autoAnalysis, isOn: true, isPrimary: false),
//                MyCellData(type: .blarblar, value: "-", isOn: false, isPrimary: false)
            ],
            MyCellHeader(name: "접근 및 권한", order: 4): [
                MyCellData(type: .terms),
                MyCellData(type: .privacy),
                MyCellData(type: .photoPermission, value: self.photoPermission)
            ],
            MyCellHeader(name: "앱 설정", order: 5): [
                MyCellData(type: .displayMode, value: displayMode),
                MyCellData(type: .feedback),
                MyCellData(type: .version, value: version)
            ],
            MyCellHeader(name: "실험실", order: 6): [
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
