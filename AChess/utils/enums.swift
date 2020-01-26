//
//  enums.swift
//  archess
//
//  Created by zhaoheng sun on 1/4/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation

enum BitMaskCategoty:Int {
    case playGround = 0
    case hand = 1
    case baseChess = 2
}

enum ContactCategory:String {
    case playGround = "playground"
    case hand = "hand"
    case baseChess = "baseChess"
}
enum HandGestureCategory:Int {
    case closeFist = 0
    case openFist = 1
}

