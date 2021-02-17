//
//  playerStruct.swift
//  AChess
//
//  Created by zhaoheng sun on 4/11/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation
import MultipeerConnectivity
//curCoin: GlobalNumberSettings.roundBaseCoin.rawValue + 50, curLevel: 1, curBlood: 40, curChesses: []

public struct playerStruct {
    
    var playerName: String
    var curCoin: Int
    var curLevel: Int
    var curBlood: Int
    var curChesses: [codableChessStruct] //棋子
    var curAura: [String]
    var isComputer: Bool
    var playerID: MCPeerID?
    var playerStatus: Bool = false //true 准备完成 false 准备未完成
   

    init(playerName: String, curCoin: Int, curLevel: Int, curBlood: Int, curChesses: [codableChessStruct], curAura: [String], isComputer: Bool, playerID: MCPeerID?) {
        self.playerName = playerName
        self.curCoin    = curCoin
        self.curLevel   = curLevel
        self.curBlood   = curBlood
        self.curChesses = curChesses
        self.curAura    = curAura
        self.isComputer = isComputer
        self.playerID = playerID
    }
    mutating func setPlayerStatus (curStatus: Bool) {
        self.playerStatus = curStatus
    }
}
