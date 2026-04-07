//
//  PhotoGridViewController.swift
//  Presentation
//
//  Created by sanghyeon on 4/8/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import UIKit

class PhotoGridViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    
    // 현재 한 줄에 보여줄 아이템 개수 (기본 3개)
    private var columnCount: Int = 3 {
        didSet {
            // 값이 바뀔 때만 레이아웃 업데이트
            if oldValue != columnCount {
                updateLayout()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupPinchGesture()
    }
    
    private func setupCollectionView() {
        // 초기 레이아웃 설정
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        
        // 셀 등록 및 데이터소스 연결 (실제 구현 시 필요)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        
        view.addSubview(collectionView)
    }
    
    private func setupPinchGesture() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        collectionView.addGestureRecognizer(pinch)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            // 줌 인 (손가락 벌리기) -> 사진이 커져야 하므로 열 개수 감소
            if gesture.scale > 1.3 && columnCount > 1 {
                columnCount -= 2
                gesture.scale = 1.0 // 스케일 초기화로 연속 변경 방지
            } 
            // 줌 아웃 (손가락 오므리기) -> 사진이 작아져야 하므로 열 개수 증가
            else if gesture.scale < 0.7 && columnCount < 5 {
                columnCount += 2
                gesture.scale = 1.0
            }
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] _, _ in
            guard let self = self else { return nil }
            
            // 전체 너비에서 columnCount만큼 나눔
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(self.columnCount)),
                heightDimension: .fractionalWidth(1.0 / CGFloat(self.columnCount)) // 정사각형
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(1.0 / CGFloat(self.columnCount))
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
    }
    
    private func updateLayout() {
        // 애니메이션과 함께 레이아웃 변경 적용
        collectionView.setCollectionViewLayout(createLayout(), animated: true)
    }
}

// MARK: - DataSource (임시 데이터)
extension PhotoGridViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .systemGray
        return cell
    }
}