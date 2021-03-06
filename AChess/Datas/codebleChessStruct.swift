//
//  codeableChess.swift
//  AChess
//
//  Created by zhaoheng sun on 5/31/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation

import Foundation

public struct codableChessStruct: Codable {
    var chessRarityIndex: Int //当前稀有度的序号
    var atkNum: Int
    var defNum: Int
    var chessRarity: Int? //棋子稀有度
    var chessLevel:Int //棋子等级
    var chessKind: String //棋子类型
    var abilities: [String]
    var temporaryBuff: [String]

    init(chessRarityIndex: Int, atkNum: Int, defNum: Int, chessRarity: Int?,chessLevel: Int, chessKind: String, abilities:[String], temporaryBuff: [String]) {
        self.chessRarityIndex = chessRarityIndex
        self.atkNum = atkNum
        self.defNum = defNum
        self.chessRarity = chessRarity
        self.chessLevel = chessLevel
        self.chessKind = chessKind
        self.abilities = abilities
        self.temporaryBuff = temporaryBuff
    }
    
    func decode() -> chessStruct {
        let curIndex = chessRarityIndex
        let curRaity = chessRarity ?? 1
        var curChessStruct:chessStruct
        if chessRarity != nil {
            curChessStruct = chessCollectionsLevel[curRaity - 1][curIndex] //普通怪
        } else {
            curChessStruct = chessDerivateCollections[curIndex] //衍生物
        }
        curChessStruct.atkNum = atkNum
        curChessStruct.defNum = defNum
        curChessStruct.chessLevel = chessLevel
        curChessStruct.chessKind = chessKind
        curChessStruct.abilities = abilities
        curChessStruct.temporaryBuff = temporaryBuff
        return curChessStruct
    }
    mutating func AddBilities(Abilities: [String]) {
        var tempAbilities:[String] = []
        Abilities.forEach{ (curAbi) in
            if !abilities.contains(curAbi) {
                tempAbilities.append(curAbi)
            }
        }
        abilities += tempAbilities
    }
}
