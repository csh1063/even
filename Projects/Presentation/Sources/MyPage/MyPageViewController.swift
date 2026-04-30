//
//  MyPageViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

final class MyPageViewController: BaseViewController {
    
    private let naviView = NaviBarView(type: .title(.leading))
    
    private var tableView: UITableView = {
        let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 100, right: 0)
        tableView.alwaysBounceVertical = true
        
        tableView.register(MyCell.self, forCellReuseIdentifier: MyCell.cellName)
        tableView.register(MyPageCell.self, forCellReuseIdentifier: MyPageCell.cellName)
        tableView.backgroundColor = Theme.background
        
        return tableView
    }()
    
    private var dataSource: UITableViewDiffableDataSource<MyCellHeader, MyCellData>!
    
    private var viewModel: MyPageViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: MyPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.setupView()
        self.setupBindings()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.viewModel.send(.appear)
    }
    
    required init?(coder: NSCoder) {
        fatalError(Self.fatalMessage)
    }
    
    private func setupView() {
        
        naviView.setTitle("마이 페이지",
                          color: Theme.textPrimary,
                          font: .systemFont(ofSize: 32, weight: .bold))
        
        naviView.addButtons([RightButton(type: .setting)])
        
        tableView.delegate = self
        
        configureDataSource()
        
        view.addSubview(naviView)
        view.addSubview(tableView)
        
        naviView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.view)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(naviView.snp.bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }
    }
    
    private func setupBindings() {
        let output = viewModel.transform()
        
        output.cellTyps
            .receive(on: DispatchQueue.main)
            .sink { cellTypes in
                self.applySnapshot(with: cellTypes)
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

extension MyPageViewController {
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<MyCellHeader, MyCellData>(tableView: tableView, cellProvider: { tableView, indexPath, itemIdentifier in
            switch itemIdentifier.type {
            case .labels, .test:
                if let cell = tableView.dequeueReusableCell(withIdentifier: MyCell.cellName, for: indexPath) as? MyCell {
                    cell.configure(with: itemIdentifier.type)
                    return cell
                }
                return UITableViewCell()
            case .locationAnalysis, .locationAutoFolder:
                let defaultCell = UITableViewCell()
                defaultCell.backgroundColor = Theme.accent
                print("indexPath row", indexPath.row, ", item", indexPath.item)
                return defaultCell
            default:
                if let cell = tableView.dequeueReusableCell(withIdentifier: MyPageCell.cellName, for: indexPath) as? MyPageCell {
                    
                    let sectionId = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
                    let items = self.dataSource.snapshot().itemIdentifiers(inSection: sectionId)
                    let isFirst = items.first == itemIdentifier
                    let isLast = items.last == itemIdentifier
                    
                    let cellPosition: CellPosition
                    if items.count == 1 {
                        cellPosition = .single
                    } else if isFirst {
                        cellPosition = .top
                    } else if isLast {
                        cellPosition = .bottom
                    } else {
                        cellPosition = .middle
                    }
                    
                    cell.configure(with: itemIdentifier, cellPosition: cellPosition)
                    return cell
                }
                
                let defaultCell = UITableViewCell()
                defaultCell.backgroundColor = .blue
                print("indexPath row", indexPath.row, ", item", indexPath.item)
                return defaultCell
            }
        })
    }
    
    private func applySnapshot(with folders: [MyCellHeader: [MyCellData]]) {
        var snapshot = NSDiffableDataSourceSnapshot<MyCellHeader, MyCellData>()
        
        let sections: [MyCellHeader] = Array(folders.keys).sorted { $0.order < $1.order }
        
        snapshot.appendSections(sections)
        
        sections.forEach { section in
            snapshot.appendItems(folders[section] ?? [], toSection: section)
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension MyPageViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        self.viewModel.send(.selectItem(cellTypes[indexPath.row]))
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = MyHeaderView()
        let sectionData = dataSource.snapshot().sectionIdentifiers[section]
        view.configuration(with: sectionData)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 52
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}

