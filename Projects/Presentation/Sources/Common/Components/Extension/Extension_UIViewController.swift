import UIKit
//import Instabug

extension UIViewController {
    enum SignCloseType {
        case success
        case cancel
    }

    func modalName(_ name: String, type: SignCloseType) -> String {
        switch type {
        case .success: return "\(name)Success"
        case .cancel: return "\(name)Cancel"
        }
    }

//    func showSignUpView(_ toggle: Bool = false, focus: Bool = false, name: String) {
//        let signViewController = SignViewController(isSignIn: toggle || AuthKeyChain.shared.isBeforeLogin)
//        signViewController.signInSuccess = self.modalName(name, type: .success)
//        signViewController.signInCancel = self.modalName(name, type: .cancel)
//        signViewController.isFocus = focus
//        if let tabbar = self.navigationController?.tabBarController {
//            tabbar.present(signViewController, animated: false, completion: nil)
//        } else {
//            self.present(signViewController, animated: false, completion: nil)
//        }
//    }
}

extension UITabBarController {
    open override var childForStatusBarStyle: UIViewController? {
        return selectedViewController
    }
}

extension UINavigationController {
    open override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
}
