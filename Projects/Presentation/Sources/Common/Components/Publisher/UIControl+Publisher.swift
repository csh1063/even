//
//  UIControl+Publisher.swift
//  Presentation
//
//  Created by sanghyeon on 11/19/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import UIKit
import Combine
import Foundation
import UIKit
import Combine

extension UIControl {

    fileprivate struct EventPublisher<Control: UIControl>: Publisher {
        typealias Output = Control
        typealias Failure = Never

        let control: Control
        let events: UIControl.Event

        func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            let subscription = EventSubscription(control: control, events: events, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }

    fileprivate final class EventSubscription<Control: UIControl, S: Subscriber>: Subscription
    where S.Input == Control, S.Failure == Never {

        private weak var control: Control?
        private let events: UIControl.Event
        private var subscriber: S?

        init(control: Control, events: UIControl.Event, subscriber: S) {
            self.control = control
            self.events = events
            self.subscriber = subscriber
            control.addTarget(self, action: #selector(handleEvent(_:)), for: events)
        }

        func request(_ demand: Subscribers.Demand) {}

        func cancel() {
            control?.removeTarget(self, action: #selector(handleEvent(_:)), for: events)
            control = nil
            subscriber = nil
        }

        @objc private func handleEvent(_ sender: UIControl) {
            guard let control = sender as? Control else { return }
            _ = subscriber?.receive(control)
        }
    }

    fileprivate func makePublisher<Control: UIControl>(for events: UIControl.Event) -> AnyPublisher<Control, Never> {
        EventPublisher(control: self as! Control, events: events)
            .eraseToAnyPublisher()
    }
}

// MARK: - UIButton
extension UIButton {
    var tapPublisher: AnyPublisher<UIButton, Never> {
        makePublisher(for: .touchUpInside)
    }

    func publisher(for events: UIControl.Event) -> AnyPublisher<UIButton, Never> {
        makePublisher(for: events)
    }
}

// MARK: - UITextField
extension UITextField {
    var textPublisher: AnyPublisher<String?, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: self)
            .map { ($0.object as? UITextField)?.text }
            .eraseToAnyPublisher()
    }
}

// MARK: - UISwitch
extension UISwitch {
    var isOnPublisher: AnyPublisher<Bool, Never> {
        publisher(for: \.isOn)
            .eraseToAnyPublisher()
    }
}

// MARK: - UISlider
extension UISlider {
    var valuePublisher: AnyPublisher<Float, Never> {
        publisher(for: \.value)
            .eraseToAnyPublisher()
    }
}

// MARK: - UISegmentedControl
extension UISegmentedControl {
    var selectedPublisher: AnyPublisher<Int, Never> {
        publisher(for: \.selectedSegmentIndex)
            .eraseToAnyPublisher()
    }
}

// MARK: - UIDatePicker
extension UIDatePicker {
    var datePublisher: AnyPublisher<Date, Never> {
        publisher(for: \.date)
            .eraseToAnyPublisher()
    }
}
