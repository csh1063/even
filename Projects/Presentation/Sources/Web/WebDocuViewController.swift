//
//  WebDocuViewController.swift
//  Presentation
//
//  Created by sanghyeon on 5/12/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import WebKit
import Combine

enum DocuType {
    case terms
    case privacy

    var title: String {
        switch self {
        case .terms: return "서비스 이용약관"
        case .privacy: return "개인정보 처리방침"
        }
    }

    var urlString: String {
        switch self {
        case .terms: return "https://csh1063.github.io/moa-web/terms-of-service"
        case .privacy: return "https://csh1063.github.io/moa-web/privacy-policy.html"
        }
    }
}

final class WebDocuViewController: BaseViewController {

    private let naviView = NaviBarView()
    private let webView = WKWebView()

    private let type: DocuType

    private var cancellables = Set<AnyCancellable>()

    init(type: DocuType) {
        self.type = type

        super.init(nibName: nil, bundle: nil)

        setupViews()
        binding()
    }

    required init?(coder: NSCoder) {
        fatalError("WebDocuViewController does not support NSCoding.")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let url = URL(string: type.urlString) {
            self.webView.load(URLRequest(url: url))
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.stopLoading()
    }

    private func setupViews() {

        view.backgroundColor = Theme.background
        webView.isOpaque = false
        webView.underPageBackgroundColor = Theme.background

        naviView.setTitle(type.title)
        naviView.addButtons([LeftButton(type: .back)])

        view.addSubview(webView)
        view.addSubview(naviView)

        naviView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        webView.snp.makeConstraints { make in
            make.top.equalTo(naviView.snp.bottom)
            make.leading.trailing.bottom.equalTo(view)
        }
    }

    private func binding() {

        naviView.publisher
            .sink { type in
                switch type {
                case .back: self.navigationController?.popViewController(animated: true)
                default: break
                }
            }
            .store(in: &cancellables)
    }
}
