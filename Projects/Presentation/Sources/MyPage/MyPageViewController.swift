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
        let tableView: UITableView = UITableView(frame: .zero, style: .plain)
        
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 40, right: 0)
        tableView.alwaysBounceVertical = true
        
        tableView.register(MyCell.self, forCellReuseIdentifier: MyCell.cellName)
        tableView.backgroundColor = .Theme.background
        
        return tableView
    }()
    
    private var cellTypes: [MyPageCellType] = []
    private var viewModel: MyPageViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: MyPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.setupView()
        self.setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError(Self.fatalMessage)
    }
    
    private func setupView() {
        
        naviView.setTitle("MY PAGE")
        naviView.addRightButtons([(.setting, .Theme.text)])
        
        tableView.dataSource = self
        tableView.delegate = self
        
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
                self.cellTypes = cellTypes
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

extension MyPageViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: MyCell.cellName, for: indexPath) as? MyCell {
            cell.selectionStyle = .none
            cell.configure(with: cellTypes[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.viewModel.send(.selectItem(cellTypes[indexPath.row]))
    }
}

