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
    var abilities: [Int] //特殊能力的枚举数组
    var rattleFunc: [()] //战吼方法
    var inheritFunc: [()] //传承方法
    init(name: String, desc: String, atkNum: Int, defNum: Int, chessRarity: Int, abilities: [Int], rattleFunc: [()], inheritFunc: [()]) {
        self.name = name
        self.desc = desc
        self.atkNum = atkNum
        self.defNum = defNum
        self.chessRarity = chessRarity
        self.abilities = abilities
        self.rattleFunc = rattleFunc
        self.inheritFunc = inheritFunc
    }
}
