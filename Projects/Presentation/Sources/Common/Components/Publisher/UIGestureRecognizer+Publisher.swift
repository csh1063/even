//
//  UIGestureRecognizer+Publisher.swift
//  Presentation
//
//  Created by sanghyeon on 11/19/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import UIKit
import Combine

// MARK: - UIGestureRecognizer + Combine
extension UIGestureRecognizer {

    fileprivate struct GesturePublisher<G: UIGestureRecognizer>: Publisher {
        typealias Output = G
        typealias Failure = Never

        let gesture: G

        func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            let subscription = GestureSubscription(gesture: gesture, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }

    fileprivate final class GestureSubscription<G: UIGestureRecognizer, S: Subscriber>: Subscription
    where S.Input == G, S.Failure == Never {

        private weak var gesture: G?
        private var subscriber: S?

        init(gesture: G, subscriber: S) {
            self.gesture = gesture
            self.subscriber = subscriber
            gesture.addTarget(self, action: #selector(handle))
        }

        func request(_ demand: Subscribers.Demand) {}

        func cancel() {
            gesture?.removeTarget(self, action: #selector(handle))
            gesture = nil
            subscriber = nil
        }

        @objc private func handle() {
            guard let gesture else { return }
            _ = subscriber?.receive(gesture)
        }
    }

    fileprivate func makePublisher<G: UIGestureRecognizer>() -> AnyPublisher<G, Never> {
        GesturePublisher(gesture: self as! G)
            .eraseToAnyPublisher()
    }
}

// MARK: - 타입별 gesture publisher
extension UITapGestureRecognizer {
    var eventPublisher: AnyPublisher<UITapGestureRecognizer, Never> { makePublisher() }
}

extension UIPanGestureRecognizer {
    var eventPublisher: AnyPublisher<UIPanGestureRecognizer, Never> { makePublisher() }
}

extension UISwipeGestureRecognizer {
    var eventPublisher: AnyPublisher<UISwipeGestureRecognizer, Never> { makePublisher() }
}

extension UILongPressGestureRecognizer {
    var eventPublisher: AnyPublisher<UILongPressGestureRecognizer, Never> { makePublisher() }
}

extension UIPinchGestureRecognizer {
    var eventPublisher: AnyPublisher<UIPinchGestureRecognizer, Never> { makePublisher() }
}

extension UIRotationGestureRecognizer {
    var eventPublisher: AnyPublisher<UIRotationGestureRecognizer, Never> { makePublisher() }
}
