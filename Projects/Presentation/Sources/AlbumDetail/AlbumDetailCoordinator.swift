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
            case .options(let folder):
                self?.showAlbumOptions(album: folder)
            case .pop:
                self?.pop()
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
    
    func showAlbumRenameSheet(album: Folder) {
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
    
    func showAlbumOptions(album: Folder) {
        let sheet = AlbumOptionsSheet(albumTitle: album.displayName)
        sheet.onRename = { [weak self] in
            self?.showAlbumRenameSheet(album: album)
        }
        sheet.onDelete = { [weak self] in
            self?.delegate?.deleteAlert()
        }

        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.custom { _ in 260 }]
            presentation.preferredCornerRadius = 28
        }

        navigationController.present(sheet, animated: true)
    }
    
}
