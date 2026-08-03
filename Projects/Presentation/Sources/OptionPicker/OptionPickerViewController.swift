//
//  OptionPickerViewController.swift
//  Presentation
//
//  Created by sanghyeon on 5/15/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Combine

// MARK: - OptionPickerViewController

final class OptionPickerViewController: UIViewController {

    // MARK: - Properties

    var onSelect: ((String) -> Void)?

    private let pageTitle: String
    private let options: [String]
    private var selectedOption: String

    // MARK: - UI
    private let naviView = NaviBarView()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .clear
        tv.separatorColor = Theme.divider
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(title: String, options: [String], selected: String) {
        self.pageTitle = title
        self.options = options
        self.selectedOption = selected
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        setupViews()
        binding()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsTracker.shared.logScreenView("옵션 선택 - \(pageTitle)")
    }

    // MARK: - Setup

    private func setupViews() {

        naviView.setTitle(pageTitle)
        naviView.addButtons([LeftButton(type: .back), RightButton(type: .confirm)])

        view.addSubview(tableView)
        view.addSubview(naviView)

        tableView.dataSource = self
        tableView.delegate = self

        naviView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(naviView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func binding() {
        naviView.publisher
            .sink { [weak self]type in
                guard let self else {return}
                switch type {
                case .back:
                    self.navigationController?.popViewController(animated: true)
                case .confirm:
                    self.onSelect?(self.selectedOption)
                    self.navigationController?.popViewController(animated: true)
                default: break
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource

extension OptionPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let option = options[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = option
        config.textProperties.color = Theme.textPrimary
        config.textProperties.font = .systemFont(ofSize: 16)
        cell.contentConfiguration = config

        cell.backgroundColor = Theme.surface
        cell.accessoryType = option == selectedOption ? .checkmark : .none
        cell.tintColor = Theme.primary

        return cell
    }
}

// MARK: - UITableViewDelegate

extension OptionPickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let previous = options.firstIndex(of: selectedOption)
        selectedOption = options[indexPath.row]

        var indexPaths = [indexPath]
        if let prev = previous, prev != indexPath.row {
            indexPaths.append(IndexPath(row: prev, section: 0))
        }
        tableView.reloadRows(at: indexPaths, with: .none)

//        onSelect?(selectedOption)
    }
}
