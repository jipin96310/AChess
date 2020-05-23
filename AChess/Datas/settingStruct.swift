//
//  settingStruct.swift
//  AChess
//
//  Created by zhaoheng sun on 5/23/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation


public struct settingStruct {
    
    var isShareBoard: Bool
    var playerNumber: Double
   
   

    init(isShareBoard: Bool, playerNumber: Double) {
        self.isShareBoard = isShareBoard
        self.playerNumber    = playerNumber
    }
}
