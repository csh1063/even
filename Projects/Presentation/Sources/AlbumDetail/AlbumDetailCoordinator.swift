//
//  AlbumDetailCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 3/28/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Domain

@MainActor
public final class AlbumDetailCoordinator: BaseCoordinator {

    private let diContainer: AlbumDetailDIContainer
    private let navigationController: UINavigationController

    weak var delegate: AlbumDetailViewModelDelegate?

    init(diContainer: AlbumDetailDIContainer,
         navigationController: UINavigationController) {
        self.diContainer = diContainer
        self.navigationController = navigationController

        super.init()
    }

    public override func start() {
        print("start!")
        let viewModel = diContainer.makeAlbumDetailViewModel()
        self.delegate = viewModel
        viewModel.onAction = { [weak self] action in
            switch action {
            case .options(let album):
                self?.showAlbumOptions(album: album)
            case .pop:
                self?.pop()
            case .selectPhoto(let photoDetails, let index, let inSelectionMode):
                self?.showDetail(photoDetails, index: index, inSelectionMode: inSelectionMode)
            case .pickMergeTarget(let candidates, let isTravel, let currentAlbum):
                self?.showMergeTargetPicker(candidates: candidates, isTravel: isTravel, currentAlbum: currentAlbum)
            case .pickSplitClusters(let clusters):
                self?.showClusterSplitPicker(clusters: clusters)
            case .pickTravelerManagement(let travelers, let others):
                self?.showTravelerManagement(travelers: travelers, others: others)
            }
        }

        bindAlert(from: viewModel)

        let vc = AlbumDetailViewController(viewModel: viewModel)

        navigationController.pushViewController(vc, animated: true)
        self.viewController = vc
    }

    private func pop() {
        navigationController.popViewController(animated: true)
        self.remove(coordinator: self)
    }

    func showAlbumRenameSheet(album: Album) {
        // 한 번도 직접 이름을 바꾼 적 없는 앨범은 자동 생성된 이름(예: "인물 3", "부산 여행")이 그대로 채워지지 않도록 비워서 보여준다
        // (isEdited는 병합/제외/분리 등 구조 변경 여부라 이름 변경 여부와는 별개 — isRenamed로 따로 구분)
        let sheet: AlbumRenameSheet
        if album.from == "face" {
            sheet = AlbumRenameSheet(
                albumName: album.isRenamed ? album.displayName : "",
                title: "이름 변경",
                subtitle: "이름을 정해주세요"
            )
        } else {
            sheet = AlbumRenameSheet(albumName: album.isRenamed ? album.displayName : "")
        }
        sheet.onSave = { [weak self] newName in
            self?.delegate?.save(name: newName)
        }
        sheet.onCancel = { }

        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.custom { _ in 260 }]
            presentation.preferredCornerRadius = 28
        }

        navigationController.present(sheet, animated: true)
    }

    func showAlbumOptions(album: Album) {
        var options: [OptionRowConfig] = [
            OptionRowConfig(icon: "pencil.line", title: "앨범명 변경", style: .normal) { [weak self] in
                self?.showAlbumRenameSheet(album: album)
            },
            OptionRowConfig(icon: "checkmark.circle", title: "선택 모드", style: .normal) { [weak self] in
                self?.delegate?.changeMode(.select)
            }
        ]

        if album.from == "face" {
            options.append(
                OptionRowConfig(icon: "person.2.crop.square.stack", title: "앨범 합치기", style: .normal) { [weak self] in
                    self?.delegate?.mergeTapped()
                }
            )
            options.append(
                OptionRowConfig(icon: "square.on.square.dashed", title: "앨범 분리", style: .normal) { [weak self] in
                    self?.delegate?.splitTapped()
                }
            )
        }

        if album.from == "travel" {
            options.append(
                OptionRowConfig(icon: "photo.badge.plus", title: "사진 추가", style: .normal) { [weak self] in
                    self?.showAddPhotos(album: album)
                }
            )
            options.append(
                OptionRowConfig(icon: "person.2.fill", title: "여행자 관리", style: .normal) { [weak self] in
                    self?.delegate?.travelerManagementTapped()
                }
            )
            options.append(
                OptionRowConfig(icon: "arrow.triangle.merge", title: "여행 합치기", style: .normal) { [weak self] in
                    self?.delegate?.mergeTapped()
                }
            )
        }

        options.append(
            OptionRowConfig(icon: "trash", title: "앨범 삭제", style: .destructive) { [weak self] in
                self?.delegate?.deleteAlert()
            }
        )

        let sheet = SelectionSheet(title: album.displayName, options: options)

        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.custom { _ in sheet.preferredDetentHeight }]
            presentation.preferredCornerRadius = 28
        }

        navigationController.present(sheet, animated: true)
    }

    func showMergeTargetPicker(candidates: [AlbumMergeCandidate], isTravel: Bool, currentAlbum: Album) {
        guard !candidates.isEmpty else {
            let alert = UIAlertController(
                title: "합칠 앨범 없음",
                message: isTravel ? "합칠 수 있는 다른 여행 앨범이 없어요" : "합칠 수 있는 다른 인물 앨범이 없어요",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            navigationController.present(alert, animated: true)
            return
        }

        var currentDateRangeText: String?
        if let start = currentAlbum.startDate, let end = currentAlbum.endDate {
            currentDateRangeText = AlbumMergeSheet.dateRangeFormatter.string(from: start, to: end)
        }

        let sheet = AlbumMergeSheet(
            candidates: candidates,
            title: isTravel ? "합칠 여행 선택" : "동일 인물 앨범 선택",
            subtitle: isTravel ? "끊어진 두 여행을 연결해요" : nil,
            sectionHeaderText: isTravel ? currentDateRangeText.map { "현재 여행 날짜 : \($0)" } : nil,
            isTravel: isTravel,
            imageUseCase: diContainer.makeImageUseCase(),
            albumUseCase: diContainer.makeAlbumUseCase()
        )
        sheet.onConfirm = { [weak self] selectedIds in
            guard !selectedIds.isEmpty else { return }
            self?.delegate?.mergeInto(albumIds: selectedIds)
        }

        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.preferredCornerRadius = 28
        }

        navigationController.present(sheet, animated: true)
    }

    func showClusterSplitPicker(clusters: [FaceClusterSummary]) {
        guard clusters.count > 1 else {
            let alert = UIAlertController(
                title: "분리할 그룹 없음",
                message: "이 앨범은 병합된 적이 없어서 분리할 그룹이 없어요",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            navigationController.present(alert, animated: true)
            return
        }

        let sheet = ClusterSplitSheet(clusters: clusters, imageUseCase: diContainer.makeImageUseCase())
        sheet.onConfirm = { [weak self] selectedIds in
            guard !selectedIds.isEmpty else { return }
            self?.delegate?.splitInto(clusterIds: selectedIds)
        }

        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.custom { _ in sheet.preferredDetentHeight }]
            presentation.preferredCornerRadius = 28
        }

        navigationController.present(sheet, animated: true)
    }

    func showTravelerManagement(travelers: [Album], others: [Album]) {
        let sheet = TravelerManagementSheet(
            travelers: travelers,
            others: others,
            imageUseCase: diContainer.makeImageUseCase(),
            albumUseCase: diContainer.makeAlbumUseCase(),
            detailUseCase: diContainer.makeAlbumDetailUseCase()
        )
        sheet.onConfirm = { [weak self] travelerIds in
            self?.delegate?.saveTravelerManagement(travelerIds: travelerIds)
        }

        sheet.modalPresentationStyle = .pageSheet
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.preferredCornerRadius = 28
            presentation.prefersGrabberVisible = false
        }
        sheet.isModalInPresentation = true

        navigationController.present(sheet, animated: true)
    }

    // MARK: - 사진 추가 (이전 사진 → 다음 사진 2단계)

    func showAddPhotos(album: Album) {
        guard let startDate = album.startDate else { return }

        let viewModel = TravelPhotoPickerViewModel(
            album: album,
            direction: .before(startDate),
            carriedSelections: [],
            imageUseCase: diContainer.makeImageUseCase(),
            detailUseCase: diContainer.makeAlbumDetailUseCase()
        )
        let vc = TravelPhotoPickerViewController(viewModel: viewModel)

        vc.onCancel = { [weak self] in
            self?.dismissAddPhotosFlow()
        }
        vc.onNext = { [weak self] carriedSelections in
            self?.showAddPhotosStep2(album: album, carriedSelections: carriedSelections)
        }
        vc.onSelectPhoto = { [weak self, weak vc] photoDetails, index, selectedIdentifiers in
            guard let vc else { return }
            self?.showPickerDetail(pickerVC: vc, photoDetails: photoDetails, index: index, selectedIdentifiers: selectedIdentifiers)
        }

        navigationController.pushViewController(vc, animated: true)
    }

    private func showAddPhotosStep2(album: Album, carriedSelections: [PhotoInAlbum]) {
        guard let endDate = album.endDate else { return }

        let viewModel = TravelPhotoPickerViewModel(
            album: album,
            direction: .after(endDate),
            carriedSelections: carriedSelections,
            imageUseCase: diContainer.makeImageUseCase(),
            detailUseCase: diContainer.makeAlbumDetailUseCase()
        )
        let vc = TravelPhotoPickerViewController(viewModel: viewModel)

        vc.onCancel = { [weak self] in
            self?.dismissAddPhotosFlow()
        }
        vc.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        vc.onFinish = { [weak self] in
            self?.delegate?.refreshAfterPhotosAdded()
            self?.dismissAddPhotosFlow()
        }
        vc.onSelectPhoto = { [weak self, weak vc] photoDetails, index, selectedIdentifiers in
            guard let vc else { return }
            self?.showPickerDetail(pickerVC: vc, photoDetails: photoDetails, index: index, selectedIdentifiers: selectedIdentifiers)
        }

        navigationController.pushViewController(vc, animated: true)
    }

    /// "사진 추가" 플로우 중 몇 단계에 있든, 원래 앨범 상세 화면까지 한 번에 돌아간다
    private func dismissAddPhotosFlow() {
        guard let albumDetailVC = viewController else { return }
        navigationController.popToViewController(albumDetailVC, animated: true)
    }

    /// "사진 추가" 마법사에서 이미지를 탭했을 때 — 앨범 상세와 동일하게 상세(뷰어)를 선택 모드로 띄우고,
    /// 뷰어에서 선택을 바꾸면 그 결과를 다시 피커 그리드에 반영한다
    private func showPickerDetail(pickerVC: TravelPhotoPickerViewController, photoDetails: [PhotoDetail], index: Int, selectedIdentifiers: Set<String>) {
        let vm = diContainer.makeImageViewerViewModel(
            photoDetails: photoDetails,
            index: index,
            isSelectionMode: true,
            selectedIdentifiers: selectedIdentifiers
        )
        vm.onAction = { [weak pickerVC] action in
            switch action {
            case .pageChanged(let id):
                pickerVC?.scrollToItem(id: id)
            case .selectionChanged(let identifiers):
                pickerVC?.syncSelection(identifiers)
            }
        }
        let vc = ImageViewerViewController(viewModel: vm)
        navigationController.present(vc, animated: true)
    }

//    func showDetail(_ photoDetails: [PhotoDetail], index: Int) {
//        print("showDetail")
//        let vm = diContainer.makeImageViewerViewModel(photoDetails: photoDetails, index: index)
//        vm.onAction = { [weak self] action in
//            switch action {
//            case .pageChanged(let id):
//                (self?.viewController as? AlbumDetailViewController)?.scrollToItem(id: id)
//            }
//        }
//        let vc = ImageViewerViewController(viewModel: vm)
//        
//        navigationController.present(vc, animated: true)
//    }

    func showDetail(_ photoDetails: [PhotoDetail], index: Int, inSelectionMode: Bool) {
        let albumDetailVC = viewController as? AlbumDetailViewController

        let vm = diContainer.makeImageViewerViewModel(
            photoDetails: photoDetails,
            index: index,
            isSelectionMode: inSelectionMode,
            selectedIdentifiers: albumDetailVC?.selectedIdentifiers ?? []
        )

        vm.onAction = { [weak albumDetailVC] action in
            switch action {
            case .pageChanged(let id):
                albumDetailVC?.scrollToItem(id: id)
            case .selectionChanged(let identifiers):
                albumDetailVC?.syncSelection(identifiers)
            }
        }

        let vc = ImageViewerViewController(viewModel: vm)
        navigationController.present(vc, animated: true)
    }

}
