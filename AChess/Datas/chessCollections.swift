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
        chessStruct(name: EnumChessName.mountainBird.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities:  [EnumAbilities.fly.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.wildRabbit.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities:  [EnumAbilities.instantSummonSth.rawValue], temporaryBuff:[], rattleFunc: [EnumKeyName.summonChess.rawValue : chessDerivateCollections[0], EnumKeyName.summonNum.rawValue : 1 ], inheritFunc: [:]),
        chessStruct(name: EnumChessName.hedgehog.rawValue.localized, desc: "", atkNum: 1, defNum: 2, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.spine.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:])
    ],
    [ //level2。 15个。   15
        chessStruct(name: EnumChessName.tarsier.rawValue, desc: "", atkNum: 2, defNum: 2, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.plain.rawValue,abilities: [EnumAbilities.bait.rawValue, EnumAbilities.inheritSummonSth.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [EnumKeyName.summonChess.rawValue : chessDerivateCollections[1], EnumKeyName.summonNum.rawValue : 1 ]),
        chessStruct(name: "狐狸", desc: "迅敏", atkNum: 1, defNum: 3, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.rapid.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: "蟾蜍", desc: "剧毒", atkNum: 1, defNum: 2, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.plain.rawValue, abilities: [EnumAbilities.poison.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:])
    ],
    [ //level3。 15个。   15
        chessStruct(name: "土狼", desc: "凶猛", atkNum: 2, defNum: 2, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: "白狼", desc: "隐匿", atkNum: 1, defNum: 3, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:])
    ],
    [ //level4。 9个    12
        chessStruct(name: "棕熊", desc: "咆哮", atkNum: 2, defNum: 2, chessRarity: 4, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
    ],
    [ //level5。 6个      9
        chessStruct(name: "熊猫", desc: "稀有", atkNum: 4, defNum: 6, chessRarity: 5, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),

    ]
]


public var chessDerivateCollections = [
    chessStruct(name: EnumChessName.wildRabbit.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]), // 001 小野兔
    chessStruct(name: EnumChessName.pygmyTarsier.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]), // 002 侏儒眼镜猴
]
