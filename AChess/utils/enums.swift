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
    case baseChessHolder = 3
    case saleScreen = 4
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

enum EnumsGameStage: Int {
    case exchangeStage = 0
    case battleStage = 1
}

enum EnumsChessStage: Int { //棋子的状态
    case forSale = 0
    case owned = 1
    case enemySide = 2
}
enum GlobalNumberSettings: Int {
    case chessNumber = 7
    case maxLevel =  5
    case roundBaseCoin = 2
}

enum BoardSide: Int {
    case enemySide = 0
    case allySide = 1
}

enum EnumNodeName: String {
    case saleStage = "saleStage"
    case storagePlace = "storagePlace"
    case allyBoard = "allyBoard"
    case enemyBoard = "enemyBoard"
}
enum EnumAbilities: Int {
    case liveInGroup = 0 //群居
    case furious     = 1 //凶猛
    case poison      = 2 //剧毒
    case rapid    = 3 // 迅捷
    case inheritAddBuff = 4 //传承加buff
}
enum EnumString: String {
    case exchangeStage = "ExchangeStage"
    case battleStage = "BattleStage"
    case poision    = "Poison"
    case liveInGroup = "LiveInGroup" //群居
    case furious    = "Furious" //凶猛
    case rapid      = "Rapid"   //迅捷
}


