//
//  PhotoCell.swift
//  Presentation
//
//  Created by sanghyeon on 3/13/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Combine

final class PhotoCell: UICollectionViewCell {

    private let colors: [UIColor] = [Theme.strokeSoft]

    private let coverView = UIView()
    private let mainImageView = UIImageView()
    private let noImageView = GradientCardView()

    // 선택 모드 오버레이
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        v.isHidden = true
        return v
    }()
    
    private let checkCoverView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private let checkView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 11
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        v.backgroundColor = .clear
//        v.isHidden = true
        return v
    }()

    private let checkImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    /// 대표 사진 고르기 그리드에서, 지금 이미 대표로 저장돼 있는 사진에 붙는 태그
    private let coverTagLabel: UILabel = {
        let lb = UILabel()
        lb.text = String(localized: "대표", bundle: .module)
        lb.textColor = .white
        lb.font = .systemFont(ofSize: 10, weight: .bold)
        lb.textAlignment = .center
        lb.backgroundColor = Theme.primary
        lb.layer.cornerRadius = 8
        lb.layer.masksToBounds = true
        lb.isHidden = true
        return lb
    }()

    var onImageTap: (() -> Void)?

    private var task: Task<Void, Never>?
    private var assetIdentifier: String?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupBinding()
    }

    required init?(coder: NSCoder) {
        fatalError("PhotoCell does not support NSCoding")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
        mainImageView.image = nil
        setSelectionMode(false)
        setSelected(false)
        setCoverTag(false)
    }

    // MARK: - Setup

    private func setupView() {
        coverView.layer.masksToBounds = true
        coverView.layer.cornerRadius = 12

        mainImageView.backgroundColor = .clear
        mainImageView.contentMode = .scaleAspectFill

        contentView.addSubview(coverView)
        coverView.addSubview(noImageView)
        coverView.addSubview(mainImageView)
        coverView.addSubview(dimView)
        coverView.addSubview(checkCoverView)
        checkCoverView.addSubview(checkView)
        checkView.addSubview(checkImageView)
        coverView.addSubview(coverTagLabel)

        coverView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        mainImageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        noImageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        dimView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        checkCoverView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
        }

        coverTagLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(6)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(32)
        }

        checkView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
            make.width.height.equalTo(22)
        }
        checkImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(12)
        }
    }

    private func setupBinding() {

        self.mainImageView.tapPublisher()
            .sink { [weak self] _ in
                self?.onImageTap?()
            }
            .store(in: &cancellables)

        self.dimView.tapPublisher()
            .sink { [weak self] _ in
                self?.onImageTap?()
            }
            .store(in: &cancellables)

    }

    // MARK: - Configure

    func configure(with viewModel: PhotoCellItemViewModel, index: Int) {
        noImageView.colors = [
            colors[index % colors.count].withAlphaComponent(0.8),
            Theme.surfaceWarm
        ]
        noImageView.startShimmer()

        guard viewModel.localIdentifier.count > 3 else { return }

        assetIdentifier = viewModel.localIdentifier
        coverView.addBorder(
            color: viewModel.isUnanalysis ? Theme.negative : Theme.strokeSoft,
            borderWidth: 1
        )

        task = Task {
            let size = frame.size
            let image = await viewModel.loadImage(size: CGSize(width: size.width * 2, height: size.height * 2))
            if !Task.isCancelled && assetIdentifier == viewModel.localIdentifier {
                mainImageView.image = image
            }
            noImageView.stopShimmer()
        }
    }

    // MARK: - Selection Mode

    func setSelectionMode(_ enabled: Bool) {
        checkCoverView.isHidden = !enabled
        if !enabled {
            dimView.isHidden = true
            checkView.backgroundColor = .clear
            checkImageView.isHidden = true
        }
    }

    func setSelected(_ selected: Bool) {
        if selected {
            dimView.isHidden = false
            checkView.backgroundColor = Theme.primary
            checkView.layer.borderColor = Theme.primary.cgColor
            checkImageView.isHidden = false
        } else {
            dimView.isHidden = true
            checkView.backgroundColor = .clear
            checkView.layer.borderColor = UIColor.white.cgColor
            checkImageView.isHidden = true
        }
    }

    func setCoverTag(_ show: Bool) {
        coverTagLabel.isHidden = !show
    }
}
