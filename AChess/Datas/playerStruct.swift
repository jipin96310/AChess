//
//  playerStruct.swift
//  AChess
//
//  Created by zhaoheng sun on 4/11/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation

//curCoin: GlobalNumberSettings.roundBaseCoin.rawValue + 50, curLevel: 1, curBlood: 40, curChesses: []

public struct playerStruct {
    
    var playerName: String
    var curCoin: Int
    var curLevel: Int
    var curBlood: Int
    var curChesses: [baseChessNode] //棋子
    var curAura: [String]
   

    init(playerName: String, curCoin: Int, curLevel: Int, curBlood: Int, curChesses: [baseChessNode], curAura: [String]) {
        self.playerName = playerName
        self.curCoin    = curCoin
        self.curLevel   = curLevel
        self.curBlood   = curBlood
        self.curChesses = curChesses
        self.curAura    = curAura
    }
}
