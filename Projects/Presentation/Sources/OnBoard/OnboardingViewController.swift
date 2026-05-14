//
//  OnboardingViewController.swift
//  Presentation
//
//  Created by sanghyeon on 5/12/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

final class OnboardingViewController: UIViewController {

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "onboarding_01",
            accentColor: Theme.background,
            title: "사진 분석",
            description: "사진 속 장소, 날짜, 내용을\n자동으로 분석해요"
        ),
        OnboardingPage(
            imageName: "onboarding_02",
            accentColor: Theme.background,
            title: "자동 분류",
            description: "분석 결과를 바탕으로\n사진을 카테고리별로 나눠요"
        ),
        OnboardingPage(
            imageName: "onboarding_03",
            accentColor: Theme.background,
            title: "앨범 정리",
            description: "정리된 사진을 앨범으로\n한눈에 확인해요"
        )
    ]

    private var currentIndex = 0

    private lazy var pageViewController: UIPageViewController = {
        let vc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        vc.dataSource = self
        vc.delegate = self
        return vc
    }()

    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = pages.count
        pc.currentPage = 0
        pc.currentPageIndicatorTintColor = Theme.primary
        pc.pageIndicatorTintColor = Theme.textTertiary
        return pc
    }()

    private lazy var nextButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "다음"
        config.baseForegroundColor = Theme.primary
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.25)
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 40, bottom: 14, trailing: 40)
        let btn = UIButton(configuration: config)
        btn.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var startButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "시작하기"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = Theme.primary
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 40, bottom: 14, trailing: 40)
        let btn = UIButton(configuration: config)
        btn.alpha = 0
        btn.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageViewController()
        setupUI()
        setScrollViewDelegate()
    }

    // MARK: - Setup

    private func setupPageViewController() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageViewController.didMove(toParent: self)

        if let first = makePageVC(at: 0) {
            pageViewController.setViewControllers([first], direction: .forward, animated: false)
        }
    }

    private func setupUI() {
        view.addSubview(pageControl)
        view.addSubview(nextButton)
        view.addSubview(startButton)

        nextButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(32)
        }

        startButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(32)
        }

        pageControl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(nextButton.snp.top).offset(-20)
        }
    }

    private func setScrollViewDelegate() {
        for subview in pageViewController.view.subviews {
            if let scrollView = subview as? UIScrollView {
                scrollView.delegate = self
            }
        }
    }

    // MARK: - Actions

    @objc private func nextTapped() {
        let next = currentIndex + 1
        guard next < pages.count, let vc = makePageVC(at: next) else { return }
        pageViewController.setViewControllers([vc], direction: .forward, animated: true)
        updateUI(for: next)
    }

    @objc private func startTapped() {
        // coordinator?.showTerms()
        self.dismiss(animated: true)
    }

    // MARK: - Helpers

    private func makePageVC(at index: Int) -> OnboardingPageViewController? {
        guard index >= 0, index < pages.count else { return nil }
        return OnboardingPageViewController(page: pages[index], index: index)
    }

    private func updateUI(for index: Int) {
        currentIndex = index
        pageControl.currentPage = index

        let isLast = index == pages.count - 1
        UIView.animate(withDuration: 0.25) {
            self.nextButton.alpha = isLast ? 0 : 1
            self.startButton.alpha = isLast ? 1 : 0
        }
    }
}

// MARK: - UIPageViewControllerDataSource

extension OnboardingViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? OnboardingPageViewController,
              vc.index > 0 else { return nil }
        return makePageVC(at: vc.index - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? OnboardingPageViewController,
              vc.index < pages.count - 1 else { return nil }
        return makePageVC(at: vc.index + 1)
    }
}

// MARK: - UIPageViewControllerDelegate

extension OnboardingViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let vc = pageViewController.viewControllers?.first as? OnboardingPageViewController
        else { return }
        print("index", vc.index)
        updateUI(for: vc.index)
    }
}

extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print(scrollView.bounces, scrollView.contentOffset)
        
        let isFirstable = currentIndex == 0
        let isLastable = currentIndex == self.pages.count - 1
        let shouldDisableBounces = isFirstable || isLastable
        scrollView.bounces = !shouldDisableBounces
    }
}
