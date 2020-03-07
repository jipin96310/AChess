//
//  protocol.swift
//  AChess
//
//  Created by zhaoheng sun on 2/14/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation
protocol Copyable {
    
    associatedtype T
    
    func copyable() -> T
}
