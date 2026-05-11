//
//  OpenSourceViewController.swift
//  Presentation
//
//  Created by sanghyeon on 5/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit

final class OpenSourceViewController: UIViewController {

    // MARK: - Properties
    private let viewModel = OpenSourceViewModel()
    private var expandedIndexes: Set<Int> = []

    // MARK: - UI
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(OpenSourceCell.self, forCellReuseIdentifier: OpenSourceCell.reuseIdentifier)
        tableView.backgroundColor = Theme.background
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.separatorColor = Theme.strokeSoft
        return tableView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "오픈소스 라이선스"
        view.backgroundColor = Theme.background

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDataSource
extension OpenSourceViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.licenses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OpenSourceCell.reuseIdentifier,
            for: indexPath
        ) as? OpenSourceCell else {
            return UITableViewCell()
        }
        let license = viewModel.licenses[indexPath.row]
        let isExpanded = expandedIndexes.contains(indexPath.row)
        cell.configure(with: license, isExpanded: isExpanded)
        cell.onURLTapped = { [weak self] url in
            self?.openURL(url)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension OpenSourceViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if expandedIndexes.contains(indexPath.row) {
            expandedIndexes.remove(indexPath.row)
        } else {
            expandedIndexes.insert(indexPath.row)
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - Private
private extension OpenSourceViewController {
    func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
