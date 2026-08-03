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
        let tableView = UITableView(frame: .zero, style: .grouped)

        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 100, right: 0)
        tableView.alwaysBounceVertical = true
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 58

        tableView.register(MyCell.self, forCellReuseIdentifier: MyCell.cellName)
        tableView.register(MyPageCell.self, forCellReuseIdentifier: MyPageCell.cellName)
        tableView.backgroundColor = Theme.background

        return tableView
    }()

    private var dataSource: UITableViewDiffableDataSource<MyCellHeader, MyCellData>!

    private var viewModel: MyPageViewModel

    private var cancellables = Set<AnyCancellable>()

    override var pageTitle: String? { "설정" }

    init(viewModel: MyPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        self.setupView()
        self.setupBindings()

        self.viewModel.send(.appear)
    }

//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//    }

    required init?(coder: NSCoder) {
        fatalError(Self.fatalMessage)
    }

    private func setupView() {

        naviView.setTitle(String(localized: "설정", bundle: .module),
                          color: Theme.textPrimary,
                          font: .systemFont(ofSize: 32, weight: .bold))

//        naviView.addButtons([RightButton(type: .setting)])

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
                // applySnapshot이 이미 diffable snapshot으로 갱신하는데, 뒤에 reloadData()를 또 부르면
                // 테이블 전체가 통째로 다시 그려지면서 깜빡였다 — diffable 갱신만으로 충분해서 제거함
                self.applySnapshot(with: cellTypes)
            }
            .store(in: &cancellables)
    }
}

extension MyPageViewController {
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<MyCellHeader, MyCellData>(tableView: tableView, cellProvider: { tableView, indexPath, itemIdentifier in
            switch itemIdentifier.type {
//            case .labels, .test:
//                if let cell = tableView.dequeueReusableCell(withIdentifier: MyCell.cellName, for: indexPath) as? MyCell {
//                    cell.configure(with: itemIdentifier.type)
//                    return cell
//                }
            case .locationAnalysis, .locationAutoAlbum:
                break
            default:
                if let cell = tableView.dequeueReusableCell(withIdentifier: MyPageCell.cellName, for: indexPath) as? MyPageCell {
                    let cellPosition = self.calCellPosition(itemIdentifier: itemIdentifier, indexPath: indexPath)
                    cell.configure(with: itemIdentifier, cellPosition: cellPosition)
                    return cell
                }
            }

            let defaultCell = UITableViewCell()
            defaultCell.backgroundColor = .blue
            return defaultCell
        })
    }

    private func calCellPosition(itemIdentifier: MyCellData, indexPath: IndexPath) -> CellPosition {

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
        return cellPosition
    }

    private func applySnapshot(with albums: [MyCellHeader: [MyCellData]]) {
        var snapshot = NSDiffableDataSourceSnapshot<MyCellHeader, MyCellData>()

        let sections: [MyCellHeader] = Array(albums.keys).sorted { $0.order < $1.order }

        snapshot.appendSections(sections)

        sections.forEach { section in
            snapshot.appendItems(albums[section] ?? [], toSection: section)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension MyPageViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        self.viewModel.send(.selectItem(item))
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
