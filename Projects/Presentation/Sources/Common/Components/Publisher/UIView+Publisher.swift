//
//  UIView+Publisher.swift
//  Presentation
//
//  Created by sanghyeon on 11/19/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import UIKit
import Combine

extension UIView {
    func tapPublisher() -> AnyPublisher<UITapGestureRecognizer, Never> {
        let gesture = UITapGestureRecognizer()
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(gesture)
        return gesture.eventPublisher
    }
}
