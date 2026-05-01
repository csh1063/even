//
//  AlertManager.swift
//  Presentation
//
//  Created by sanghyeon on 3/29/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import UIKit

public final class AlertManager {

    public static let shared = AlertManager()
    private init() {}

    // MARK: - Queue
    private var queue: [AlertItem] = []
    private var isPresenting: Bool = false
    private var alertWindow: UIWindow?

    // MARK: - Public
    public func enqueue(
        title: String?,
        message: String? = nil,
        buttons: [AlertButtonConfig]
    ) {
        let item = AlertItem(title: title, message: message, buttons: buttons)
        queue.append(item)
        presentNextIfNeeded()
    }

    // MARK: - Private
    private func presentNextIfNeeded() {
        guard !isPresenting, !queue.isEmpty else { return }

        isPresenting = true
        let item = queue.removeFirst()
        present(item: item)
    }

    private func present(item: AlertItem) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            isPresenting = false
            return
        }
        
        let style: UIUserInterfaceStyle
        if let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            
            style = keyWindow.overrideUserInterfaceStyle
            
        } else {
            style = .unspecified
        }

        let window = UIWindow(windowScene: windowScene)
        window.windowLevel     = .alert + 1
        window.backgroundColor = .clear
        window.rootViewController = UIViewController()
        window.overrideUserInterfaceStyle = style

        alertWindow = window
        window.makeKeyAndVisible()

        let viewModel = AlertViewModel(item: item)
        let alertVC   = AlertViewController(viewModel: viewModel) { [weak self] in
            self?.cleanup()
        }

        window.rootViewController?.present(alertVC, animated: false)
    }

    private func cleanup() {
        alertWindow?.isHidden = true
        alertWindow = nil
        isPresenting = false
        presentNextIfNeeded() // 다음 alert 자동 처리
    }
}
