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

    /// presentAlbumMenu()로 만든 viewModel을 강하게 붙잡아 둔다 — 로컬 변수로만 두면
    /// `delegate`가 weak라서 이 코디네이터가 살아있는 동안에도 viewModel이 바로 해제돼버려서
    /// 합치기/분리/여행자 관리/삭제(전부 delegate?.xxx() 경유)가 조용히 아무 반응 없는 버그가 있었다.
    private var menuViewModel: AlbumDetailViewModel?

    init(diContainer: AlbumDetailDIContainer,
         navigationController: UINavigationController) {
        self.diContainer = diContainer
        self.navigationController = navigationController

        super.init()
    }

    public override func start() {
        let viewModel = diContainer.makeAlbumDetailViewModel()
        wireActions(of: viewModel)

        let vc = AlbumDetailViewController(viewModel: viewModel)

        navigationController.pushViewController(vc, animated: true)
        self.viewController = vc
    }

    /// 메인/전체보기 화면에서 앨범을 길게 눌렀을 때 — 상세 화면으로 들어가지 않고 "..." 메뉴와
    /// 완전히 동일한 메뉴를 그 화면 위에 바로 띄운다. 합치기/분리/이름변경/사진추가 등 메뉴에서
    /// 이어지는 동작도 이 코디네이터가 (상세 화면 진입 없이) 그대로 처리한다. 이 동작들
    /// (mergeTapped/splitTapped/travelerManagementTapped/deleteAlert)은 전부 album.id만 있으면
    /// 되고 사진 로딩(.appear) 여부와 무관하게 동작하므로 안전하다.
    func presentAlbumMenu(album: Album) {
        let viewModel = diContainer.makeAlbumDetailViewModel()
        self.menuViewModel = viewModel
        wireActions(of: viewModel)
        showAlbumOptions(album: album)
    }

    private func wireActions(of viewModel: AlbumDetailViewModel) {
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
    }

    private func pop() {
        navigationController.popViewController(animated: true)
        self.remove(coordinator: self)
    }

    func showAlbumRenameSheet(album: Album) {
        // 한 번도 직접 이름을 바꾼 적 없는 앨범은 자동 생성된 이름(예: "인물 3", "부산 여행")이 그대로 채워지지 않도록 비워서 보여준다
        // (isEdited는 병합/제외/분리 등 구조 변경 여부라 이름 변경 여부와는 별개 — isRenamed로 따로 구분)
        let sheet: AlbumRenameSheet
        if album.from == "face" || album.from == "animal" {
            sheet = AlbumRenameSheet(
                albumName: album.isRenamed ? album.displayName : "",
                title: "이름 변경",
                subtitle: "이름을 정해주세요"
            )
        } else {
            // 인물/동물이 아닌 타입(날짜/장소/카테고리/여행/중복)은 자동 생성된 이름도 그 자체로
            // 의미가 있어서(예: "부산 여행") isRenamed 여부와 무관하게 항상 현재 이름을 채워 보여준다
            sheet = AlbumRenameSheet(albumName: album.displayName)
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
        var options: [OptionRowConfig] = []

        // 날짜/카테고리/장소/중복 앨범은 이름이 자동 분류 기준 그 자체라서(예: "2026년", "카페") 사용자가
        // 바꿀 수 있게 두지 않는다 — 인물/동물/여행 앨범만 이름 변경 가능
        let renameableTypes: Set<String> = ["face", "animal", "travel"]
        if renameableTypes.contains(album.from) {
            options.append(
                OptionRowConfig(icon: "pencil.line", title: "앨범명 변경", style: .normal) { [weak self] in
                    self?.showAlbumRenameSheet(album: album)
                }
            )
        }

        if album.from == "face" || album.from == "animal" {
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

        if album.from == "similar" {
            options.append(
                OptionRowConfig(icon: "trash", title: "정리 완료", style: .destructive) { [weak self] in
                    self?.delegate?.deleteAlert()
                }
            )
        } else {
            options.append(
                OptionRowConfig(icon: "trash", title: "앨범 삭제", style: .destructive) { [weak self] in
                    self?.delegate?.deleteAlert()
                }
            )
        }

        let sheet = SelectionSheet(title: album.displayName, options: options)

        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.custom { _ in sheet.preferredDetentHeight }]
            presentation.preferredCornerRadius = 28
        }

        navigationController.present(sheet, animated: true)
    }

    func showMergeTargetPicker(candidates: [AlbumMergeCandidate], isTravel: Bool, currentAlbum: Album) {
        let isAnimal = currentAlbum.from == "animal"

        guard !candidates.isEmpty else {
            let message: String
            if isTravel {
                message = "합칠 수 있는 다른 여행 앨범이 없어요"
            } else if isAnimal {
                message = "합칠 수 있는 다른 동물 앨범이 없어요"
            } else {
                message = "합칠 수 있는 다른 인물 앨범이 없어요"
            }
            let alert = UIAlertController(title: "합칠 앨범 없음", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            navigationController.present(alert, animated: true)
            return
        }

        var currentDateRangeText: String?
        if let start = currentAlbum.startDate, let end = currentAlbum.endDate {
            currentDateRangeText = AlbumMergeSheet.dateRangeFormatter.string(from: start, to: end)
        }

        let title: String
        if isTravel {
            title = "합칠 여행 선택"
        } else if isAnimal {
            title = "동일 개체 앨범 선택"
        } else {
            title = "동일 인물 앨범 선택"
        }

        let sheet = AlbumMergeSheet(
            candidates: candidates,
            title: title,
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

    // MARK: - 사진 추가 (이전/이후 헤더 토글 + 페이징 그리드가 있는 화면 하나)

    func showAddPhotos(album: Album) {
        guard let startDate = album.startDate, let endDate = album.endDate else { return }

        let detailUseCase = diContainer.makeAlbumDetailUseCase()
        let beforeViewModel = TravelPhotoPickerViewModel(
            album: album,
            direction: .before(startDate),
            imageUseCase: diContainer.makeImageUseCase(),
            detailUseCase: detailUseCase
        )
        let afterViewModel = TravelPhotoPickerViewModel(
            album: album,
            direction: .after(endDate),
            imageUseCase: diContainer.makeImageUseCase(),
            detailUseCase: detailUseCase
        )
        let vc = TravelPhotoPickerViewController(
            albumId: album.id,
            beforeViewModel: beforeViewModel,
            afterViewModel: afterViewModel,
            detailUseCase: detailUseCase
        )

        vc.onCancel = { [weak self] in
            self?.dismissAddPhotosFlow()
        }
        vc.onFinish = { [weak self] in
            self?.delegate?.refreshAfterPhotosAdded()
            self?.dismissAddPhotosFlow()
        }
        vc.onSelectPhoto = { [weak self, weak vc] photoDetails, index, selectedIdentifiers in
            guard let vc else { return }
            self?.showPickerDetail(pickerVC: vc, photoDetails: photoDetails, index: index, selectedIdentifiers: selectedIdentifiers)
        }

        // push 대신 모달로 띄운다 — 메인/더보기 화면(실제 앨범 상세로 진입하지 않은 채 길게 누르기
        // 메뉴만 띄운 상태)에서도 열 수 있어야 하고, 화면 전체를 덮는 느낌이 의도에 더 맞는다
        vc.modalPresentationStyle = .fullScreen
        navigationController.present(vc, animated: true)
    }

    /// "사진 추가" 플로우 중 몇 단계에 있든, 이 플로우 전체를 한 번에 닫는다. push가 아니라
    /// present로 띄우므로 실제 앨범 상세 화면(viewController)이 있든 없든(메인/더보기에서 진입한
    /// 경우) 항상 동작한다.
    private func dismissAddPhotosFlow() {
        navigationController.dismiss(animated: true)
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
