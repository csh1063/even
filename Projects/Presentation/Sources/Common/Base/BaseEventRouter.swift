//
//  BaseEventRouter.swift
//  Presentation
//
//  Created by sanghyeon on 1/6/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public enum BaseEvent {
    case logout
}

public protocol BaseEventRouter: AnyObject {
    func route(_ event: BaseEvent)
}
