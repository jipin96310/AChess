//
//  chessCollections.swift
//  AChess
//
//  Created by zhaoheng sun on 2/10/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation

public var chessCollectionsLevel = [
    [ //level1。15个。   18
        chessStruct(name: "山鸡", desc: "战吼", atkNum: 1, defNum: 2, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.instantDestroyAllyGainBuff.rawValue], rattleFunc: [], inheritFunc: []),
        chessStruct(name: "白蚁", desc: "群居", atkNum: 1, defNum: 5, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities:  [EnumAbilities.immunePoison.rawValue], rattleFunc: [], inheritFunc: []),
        chessStruct(name: "龙虾", desc: "传承+1/+1", atkNum: 1, defNum: 1, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.endRoundAddBuffForGreen.rawValue], rattleFunc: [], inheritFunc: [])
    ],
    [ //level2。 15个。   15
        chessStruct(name: "土狗", desc: "凶猛", atkNum: 1, defNum: 1, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.plain.rawValue,abilities: [EnumAbilities.poison.rawValue], rattleFunc: [], inheritFunc: []),
        chessStruct(name: "狐狸", desc: "迅敏", atkNum: 1, defNum: 3, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.rapid.rawValue], rattleFunc: [], inheritFunc: []),
        chessStruct(name: "蟾蜍", desc: "剧毒", atkNum: 1, defNum: 2, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.plain.rawValue, abilities: [EnumAbilities.poison.rawValue], rattleFunc: [], inheritFunc: [])
    ],
    [ //level3。 15个。   15
        chessStruct(name: "土狼", desc: "凶猛", atkNum: 2, defNum: 2, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], rattleFunc: [], inheritFunc: []),
        chessStruct(name: "白狼", desc: "隐匿", atkNum: 1, defNum: 3, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], rattleFunc: [], inheritFunc: [])
    ],
    [ //level4。 9个    12
        chessStruct(name: "棕熊", desc: "咆哮", atkNum: 2, defNum: 2, chessRarity: 4, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], rattleFunc: [], inheritFunc: []),
        chessStruct(name: "华南虎", desc: "隐匿", atkNum: 1, defNum: 3, chessRarity: 4, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], rattleFunc: [], inheritFunc: [])
    ],
    [ //level5。 6个      9
       chessStruct(name: "熊猫", desc: "稀有", atkNum: 4, defNum: 6, chessRarity: 5, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], rattleFunc: [], inheritFunc: []),
        chessStruct(name: "龙", desc: "飞行", atkNum: 7, defNum: 7, chessRarity: 5, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], rattleFunc: [], inheritFunc: [])
    ]
]
