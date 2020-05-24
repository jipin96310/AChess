//
//  settingStruct.swift
//  AChess
//
//  Created by zhaoheng sun on 5/23/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public struct settingStruct : Codable {
    
    var isShareBoard: Bool
    var playerNumber: Int
    var isMaster: Bool

    init(isShareBoard: Bool, playerNumber: Int, isMaster: Bool) {
        self.isShareBoard = isShareBoard
        self.playerNumber = playerNumber
        self.isMaster = isMaster
    }
}
