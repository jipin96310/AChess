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
    var enableHandTracking: Bool
    var enableGestureRecognizer: Bool
    var enableButtonGestureControl: Bool

    init(isShareBoard: Bool, playerNumber: Int, isMaster: Bool, enableHandTracking: Bool,enableGestureRecognizer: Bool,enableButtonGestureControl: Bool ) {
        self.isShareBoard = isShareBoard
        self.playerNumber = playerNumber
        self.isMaster = isMaster
        self.enableHandTracking = enableHandTracking
        self.enableGestureRecognizer = enableGestureRecognizer
        self.enableButtonGestureControl = enableButtonGestureControl
    }
}
