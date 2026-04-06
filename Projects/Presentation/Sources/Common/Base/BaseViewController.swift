//
//  BaseViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

open class BaseViewController: UIViewController {
    
    private lazy var loadingView: UIView = {
        let view = UIView()
        let actor = UIActivityIndicatorView()
        view.backgroundColor = .black.withAlphaComponent(0.3)
        view.addSubview(actor)
        
        actor.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
        
        return view
    }()
    
    static var fatalMessage: String {
        return "\(Self.self) does not support NSCoding"
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .Theme.background
        print("==== \(Self.self) viewDidLoad        ====================")
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        print("==== \(Self.self) viewWillAppear     ====================")
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("==== \(Self.self) viewDidAppear      ====================")
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("==== \(Self.self) viewWillDisappear  ====================")
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("==== \(Self.self) viewDidDisappear   ====================")
    }
}
