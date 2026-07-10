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
            case .pickMergeTarget(let candidates):
                self?.showMergeTargetPicker(candidates: candidates)
            case .pickSplitClusters(let clusters):
                self?.showClusterSplitPicker(clusters: clusters)
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
        let sheet = AlbumRenameSheet(albumName: album.displayName)
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

    func showMergeTargetPicker(candidates: [AlbumMergeCandidate]) {
        guard !candidates.isEmpty else {
            let alert = UIAlertController(
                title: "합칠 앨범 없음",
                message: "합칠 수 있는 다른 인물 앨범이 없어요",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            navigationController.present(alert, animated: true)
            return
        }

        let sheet = AlbumMergeSheet(candidates: candidates, imageUseCase: diContainer.makeImageUseCase(), albumUseCase: diContainer.makeAlbumUseCase())
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
