//
//  nodeColor.swift
//  AChess
//
//  Created by zhaoheng sun on 2/19/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation
import UIKit

public let chessColorRarity = [ 1 : UIImage(named: "normalChess"), 2 : UIImage(named: "eliteChess"), 3 : UIImage(named: "rareChess"), 4 : UIImage(named: "epicChess"), 5 : UIImage(named: "legendChess")]
public let chessKindBgImage = [
    EnumChessKind.mountain.rawValue : UIImage(named: "mountainBg"),
    EnumChessKind.ocean.rawValue : UIImage(named: "oceanBg"),
    EnumChessKind.plain.rawValue : UIImage(named: "plainBg")
]
