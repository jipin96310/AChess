//
//  MainController.swift
//  AChess
//
//  Created by zhaoheng sun on 5/16/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import UIKit

class MainController: UINavigationController {
    
  
    @IBOutlet weak var navi: UINavigationBar!
    override func viewDidLoad() {
        navi.isHidden = true
    }
    
}
