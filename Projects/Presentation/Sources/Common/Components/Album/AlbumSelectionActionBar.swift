//
//  AlbumSelectionActionBar.swift
//  Presentation
//
//  Created by sanghyeon on 7/22/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//
//  메인/전체보기 화면에서 앨범을 여러 개 선택했을 때 쓰는 하단 액션바 — 앨범 상세의
//  bottomBar(선택한 사진 개수 + 삭제/제외 버튼)와 같은 역할을 앨범 목록 레벨에서 한다.

import UIKit
import SnapKit
import Combine

final class AlbumSelectionActionBar: UIView {

    private let countLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = Theme.textSecondary
        lb.font = .systemFont(ofSize: 14, weight: .regular)
        lb.text = "0개 선택"
        return lb
    }()

    private let deleteButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "trash")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        config.baseForegroundColor = .white
        config.baseBackgroundColor = Theme.negative
        config.cornerStyle = .medium
        return UIButton(configuration: config)
    }()

    private let deleteSubject = PassthroughSubject<Void, Never>()
    var deletePublisher: AnyPublisher<Void, Never> { deleteSubject.eraseToAnyPublisher() }

    /// 앨범 상세의 bottomBar와 동일하게 맞춘 값 — 고정 높이 88 + 중심에서 -10 오프셋으로,
    /// safe area(홈 인디케이터)를 안전 마진으로 흡수한다. 예전엔 이 뷰 스스로
    /// safeAreaLayoutGuide 기준으로 배치했었는데, 그 값이 setupView 시점엔 아직 0으로
    /// 읽혀서(레이아웃 전) 버튼이 바 밖으로 걸쳐 보이는 버그가 있었다 — 앨범 상세와 동일한
    /// 고정 수치 방식으로 통일해서 해결.
    init() {
        super.init(frame: .zero)
        backgroundColor = Theme.background
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 8

        addSubview(countLabel)
        addSubview(deleteButton)

        countLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview().offset(-10)
        }
        deleteButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview().offset(-10)
            make.height.equalTo(44)
            make.width.equalTo(44)
        }

        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("AlbumSelectionActionBar does not support NSCoding")
    }

    func setSelectedCount(_ count: Int) {
        countLabel.text = "\(count)개 선택"
        deleteButton.isEnabled = count > 0
        deleteButton.alpha = count > 0 ? 1.0 : 0.4
    }

    @objc private func deleteTapped() {
        deleteSubject.send()
    }
}
