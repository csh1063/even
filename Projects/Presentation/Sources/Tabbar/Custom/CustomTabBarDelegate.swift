//
//  CustomTabBarDelegate.swift
//  RxTest
//
//  Created by sanghyeon on 6/28/24.
//

import Foundation
import UIKit

protocol CustomTabBarDelegate: AnyObject {
    func tabBarController(_ tabBarController: CustomTabBarController, shouldSelect viewController: UIViewController) -> Bool
    func tabBarController(_ tabBarController: CustomTabBarController, didSelect viewController: UIViewController)
}

extension CustomTabBarDelegate {
    func tabBarController(_ tabBarController: CustomTabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
    }
    func tabBarController(_ tabBarController: CustomTabBarController, didSelect viewController: UIViewController) {
    }
}
