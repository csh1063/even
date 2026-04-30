//
//  AnalysisProgressManager.swift
//  Presentation
//
//  Created by sanghyeon on 4/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Combine

final class AnalysisProgressManager {
    static let shared = AnalysisProgressManager()
    
    var isPresenting: Bool = false
    
    private var window: UIWindow?
    private var floatingView: MiniProgressView?
    private var isHiding: Bool = false
    
    func show(
        locationProgress: AnyPublisher<Double, Never>,
        folderProgress: AnyPublisher<Double, Never>
    ) {
        guard !isPresenting else {return}
        
        isPresenting = true
        
        let view = MiniProgressView()
        view.bind(locationProgress: locationProgress, folderProgress: folderProgress)
        
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }
        
        window.addSubview(view)
        
        view.snp.makeConstraints { make in
            make.trailing.equalTo(80)
            make.bottom.equalTo(window).offset(-120)
            make.width.height.equalTo(72)
        }
        window.layoutIfNeeded()
        
        self.window = window
        self.floatingView = view
        
        view.snp.updateConstraints { make in
            make.trailing.equalTo(-20)
        }
        
        UIView.animate(withDuration: 0.5) {
            window.layoutIfNeeded()
        }
    }
    
    func hide() {
        
        guard !isHiding else { return }
        isHiding = true

        guard let window else {
            floatingView?.removeFromSuperview()
            floatingView = nil
            isPresenting = false
            return
        }
        
        self.floatingView?.snp.updateConstraints { make in
            make.trailing.equalTo(80)
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.5) {
            window.layoutIfNeeded()
        } completion: { success in
            if success {
                self.floatingView?.removeFromSuperview()
                self.floatingView = nil
                self.isPresenting = false
                self.isHiding = false
            }
        }
    }
}
