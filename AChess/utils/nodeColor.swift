//
//  nodeColor.swift
//  AChess
//
//  Created by zhaoheng sun on 2/19/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation
import UIKit

public let chessColorRarity = [ 1 : "normalChess", 2 : "eliteChess", 3 : "rareChess", 4 : "epicChess", 5 : "legendChess"]
public let chessKindBgImage = [
    EnumChessKind.mountain.rawValue : "mountainBg",
    EnumChessKind.ocean.rawValue : "oceanBg",
    EnumChessKind.plain.rawValue : "plainBg",
    EnumChessKind.frost.rawValue : "plainBg",
    EnumChessKind.desert.rawValue : "plainBg",
    EnumChessKind.polar.rawValue : "plainBg"
]

public let labelColorRarity = [ 1 : UIColor.white, 2 : UIColor.green, 3 : UIColor.blue, 4 : UIColor.purple, 5 : UIColor.orange]
