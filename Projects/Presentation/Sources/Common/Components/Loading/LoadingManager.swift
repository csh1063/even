//
//  LoadingManager.swift
//  Presentation
//
//  Created by sanghyeon on 5/6/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

public final class LoadingManager {

    public static let shared = LoadingManager()
    private init() {}

    private var dimView: UIView?
    private var loadingView: CardStackLoadingView?
    private var dismissTimer: DispatchWorkItem?

    public func show(allowDismiss: Bool = true) {
        guard loadingView == nil else { return }

        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        let dimView = UIView(backgroundColor: .black.withAlphaComponent(0.2))
        let view = CardStackLoadingView()
        window.addSubview(dimView)
        window.addSubview(view)

        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.snp.makeConstraints { make in
            make.center.equalTo(dimView)
            make.width.height.equalTo(60)
        }

        view.alpha = 0
        view.startAnimating()
        UIView.animate(withDuration: 0.2) { view.alpha = 1 }

        self.dimView = dimView
        self.loadingView = view

        guard allowDismiss else { return }

        let workItem = DispatchWorkItem { [weak self] in
            self?.loadingView?.showDismissButton()
        }
        dismissTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: workItem)
    }

    public func hide() {
        dismissTimer?.cancel()
        dismissTimer = nil

        guard let view = loadingView, let dimView = dimView else { return }
        UIView.animate(withDuration: 0.2) {
            view.alpha = 0
        } completion: { _ in
            view.stopAnimating()
            view.removeFromSuperview()
            dimView.removeFromSuperview()
            self.loadingView = nil
            self.dimView = nil
        }
    }
}
