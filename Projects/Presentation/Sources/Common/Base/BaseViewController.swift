//
//  BaseViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

open class BaseViewController: UIViewController {

    static var fatalMessage: String {
        return "\(Self.self) does not support NSCoding"
    }

    /// 분석 도구에 기록할 화면 이름 — 서브클래스가 오버라이드. nil이면 트래킹하지 않는다.
    open var pageTitle: String? { nil }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Theme.background
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pageTitle {
            AnalyticsTracker.shared.logScreenView(pageTitle)
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
}
