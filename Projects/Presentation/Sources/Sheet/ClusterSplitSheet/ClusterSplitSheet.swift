//
//  ClusterSplitSheet.swift
//  Presentation
//
//  Created by sanghyeon on 7/10/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Domain

/// 병합된 얼굴 앨범을 원래 클러스터 단위로 되돌려 분리하기 위한 선택 시트
final class ClusterSplitSheet: UIViewController {

    // MARK: - Properties

    private let clusters: [FaceClusterSummary]
    private let imageUseCase: PhotoImageUseCase
    private var selectedIds: Set<UUID> = []

    var onConfirm: (([UUID]) -> Void)?

    // MARK: - UI

    private let grabberView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.strokeSoft
        v.layer.cornerRadius = 2.5
        return v
    }()

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = String(localized: "앨범 분리", bundle: .module)
        lb.font = .systemFont(ofSize: 20, weight: .bold)
        lb.textColor = Theme.textPrimary
        return lb
    }()

    private let subtitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = String(localized: "떼어낼 그룹을 선택하세요 — 선택한 그룹은 새 앨범으로 분리돼요", bundle: .module)
        lb.font = .systemFont(ofSize: 14, weight: .regular)
        lb.textColor = Theme.textSecondary
        lb.numberOfLines = 0
        return lb
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private lazy var rowStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        return sv
    }()

    private let confirmButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "선택한 그룹 분리하기", bundle: .module)
        config.baseForegroundColor = .white
        config.baseBackgroundColor = Theme.primary
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        return btn
    }()

    // MARK: - Init

    init(clusters: [FaceClusterSummary], imageUseCase: PhotoImageUseCase) {
        self.clusters = clusters
        self.imageUseCase = imageUseCase
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("ClusterSplitSheet does not support NSCoding.")
    }

    // MARK: - Detent

    /// 클러스터 개수에 맞춰 시트가 늘어나도록 계산한 높이 — 많아지면 화면의 80%에서 멈추고 스크롤로 처리
    var preferredDetentHeight: CGFloat {
        let rowHeight: CGFloat = 64
        let rowSpacing: CGFloat = 12
        let rowsTotal = clusters.isEmpty ? 0 : CGFloat(clusters.count) * rowHeight + CGFloat(clusters.count - 1) * rowSpacing
        // grabber(10+5) + gap(16) + header(약 45) + gap(20) + rows + confirmButton 영역(12+52+32)
        let contentHeight: CGFloat = 10 + 5 + 16 + 45 + 20 + rowsTotal + 12 + 52 + 32
        let maxHeight = UIScreen.main.bounds.height * 0.8
        return min(contentHeight, maxHeight)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupRows()
        updateConfirmButton()
    }

    // MARK: - Setup

    private func setupLayout() {
        view.backgroundColor = Theme.surface

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4

        view.addSubview(grabberView)
        view.addSubview(headerStack)
        view.addSubview(scrollView)
        view.addSubview(confirmButton)
        scrollView.addSubview(rowStack)

        grabberView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(42)
            make.height.equalTo(5)
        }
        headerStack.snp.makeConstraints { make in
            make.top.equalTo(grabberView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(confirmButton.snp.top).offset(-12)
        }
        rowStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }
        confirmButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(32)
            make.height.equalTo(52)
        }

        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
    }

    private func setupRows() {
        clusters.forEach { cluster in
            let row = ClusterSplitRow(cluster: cluster)
            row.snp.makeConstraints { make in make.height.equalTo(64) }
            row.onToggle = { [weak self] isChosen in
                guard let self else { return }
                if isChosen { selectedIds.insert(cluster.id) } else { selectedIds.remove(cluster.id) }
                updateConfirmButton()
            }
            rowStack.addArrangedSubview(row)

            guard let coverPhotoId = cluster.coverPhotoId else { return }
            Task { [weak row] in
                guard let cgImage: CGImage = try? await imageUseCase.loadImage(
                    id: coverPhotoId,
                    type: .specialSize(CGSize(width: 96, height: 96))
                ).cgImage else { return }
                row?.setThumbnail(UIImage(cgImage: cgImage))
            }
        }
    }

    private func updateConfirmButton() {
        let count = selectedIds.count
        confirmButton.isEnabled = count > 0
        confirmButton.alpha = count > 0 ? 1.0 : 0.4
    }

    // MARK: - Actions

    @objc private func confirmTapped() {
        let ids = Array(selectedIds)
        dismiss(animated: true) { [weak self] in self?.onConfirm?(ids) }
    }
}

// MARK: - ClusterSplitRow

private final class ClusterSplitRow: UIControl {

    let clusterId: UUID
    var onToggle: ((Bool) -> Void)?

    private(set) var isChosen = false {
        didSet { updateAppearance() }
    }

    private let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = Theme.strokeSoft
        return iv
    }()

    private let countLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 15, weight: .semibold)
        lb.textColor = Theme.textPrimary
        return lb
    }()

    private let checkmarkView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    init(cluster: FaceClusterSummary) {
        self.clusterId = cluster.id
        super.init(frame: .zero)

        countLabel.text = String(localized: "\(cluster.photoCount)장", bundle: .module)
        setupLayout()

        backgroundColor = Theme.surface
        layer.cornerRadius = 16
        layer.masksToBounds = true
        addBorder(color: Theme.strokeSoft, borderWidth: 1)

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        addBorder(color: isChosen ? Theme.primary : Theme.strokeSoft, borderWidth: isChosen ? 2 : 1)
    }

    func setThumbnail(_ image: UIImage?) {
        thumbnailView.image = image
    }

    private func setupLayout() {
        addSubview(thumbnailView)
        addSubview(countLabel)
        addSubview(checkmarkView)

        thumbnailView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.width.equalTo(thumbnailView.snp.height)
        }
        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailView.snp.trailing).offset(14)
            make.centerY.equalToSuperview()
        }
        checkmarkView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }
    }

    @objc private func handleTap() {
        isChosen.toggle()
        onToggle?(isChosen)
    }

    private func updateAppearance() {
        checkmarkView.image = UIImage(systemName: isChosen ? "checkmark.circle.fill" : "circle")
        checkmarkView.tintColor = isChosen ? Theme.primary : Theme.textTertiary
        addBorder(color: isChosen ? Theme.primary : Theme.strokeSoft, borderWidth: isChosen ? 2 : 1)
    }
}
