//
//  chessStruct.swift
//  AChess
//
//  Created by zhaoheng sun on 2/11/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation

public struct chessStruct {
    var name: String?
    var desc: String?
    var atkNum: Int?
    var defNum: Int?
    var chessRarity: Int? //棋子稀有度
    var chessLevel:Int? //棋子等级
    var chessKind: String //棋子类型
    var abilities: [String]
    var temporaryBuff: [String]
    var rattleFunc: [Int : Any] //战吼方法
    var inheritFunc: [Int : Any] //传承方法

    init(name: String, desc: String, atkNum: Int, defNum: Int, chessRarity: Int,chessLevel: Int, chessKind: String, abilities:[String], temporaryBuff: [String],  rattleFunc: [Int : Any], inheritFunc: [Int : Any]) {
        self.name = name
        self.desc = desc
        self.atkNum = atkNum
        self.defNum = defNum
        self.chessRarity = chessRarity
        self.chessLevel = chessLevel
        self.chessKind = chessKind
        self.abilities = abilities
        self.temporaryBuff = temporaryBuff
        self.rattleFunc = rattleFunc
        self.inheritFunc = inheritFunc
    }
}
