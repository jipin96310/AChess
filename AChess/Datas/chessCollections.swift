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
        chessStruct(name: EnumChessName.wildRabbit.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities:  [EnumAbilities.instantSummonSth.rawValue], temporaryBuff:[], rattleFunc: [EnumKeyName.summonChess.rawValue : [chessDerivateCollections[0]]], inheritFunc: [:]),
        chessStruct(name: EnumChessName.hedgehog.rawValue.localized, desc: "", atkNum: 1, defNum: 2, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.spine.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.crucian.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.inheritAddBuff.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [EnumKeyName.baseAttack.rawValue : 1, EnumKeyName.baseDef.rawValue : 1]),
        chessStruct(name: EnumChessName.sardine.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.acute.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.riverCrab.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [], temporaryBuff:[EnumAbilities.shell.rawValue], rattleFunc: [:], inheritFunc: [:])
    ],
    [ //level2。 15个。   15
        chessStruct(name: EnumChessName.tarsier.rawValue.localized, desc: "", atkNum: 2, defNum: 2, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.plain.rawValue,abilities: [EnumAbilities.bait.rawValue, EnumAbilities.inheritSummonSth.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [EnumKeyName.summonChess.rawValue : [chessDerivateCollections[1]]]),
        chessStruct(name: EnumChessName.snubNosedMonkey.rawValue.localized, desc: "", atkNum: 2, defNum: 3, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.rapid.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.wolfSpider.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.bait.rawValue, EnumAbilities.inheritDamage.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [EnumKeyName.baseDamage.rawValue:3, EnumKeyName.summonNum.rawValue:1]),
        chessStruct(name: EnumChessName.pheasant.rawValue.localized, desc: "", atkNum: 1, defNum: 3, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.fly.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.alpDog.rawValue.localized, desc: "", atkNum: 1, defNum: 3, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.inheritAddBuff.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [EnumKeyName.baseAttack.rawValue:1, EnumKeyName.summonNum.rawValue:1, EnumKeyName.baseDef.rawValue:1]),
        chessStruct(name: EnumChessName.argali.rawValue.localized, desc: "", atkNum: 2, defNum: 3, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.liveInGroup.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.lobster.rawValue.localized, desc: "", atkNum: 2, defNum: 2, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [], temporaryBuff:[EnumAbilities.instantAddBuff.rawValue], rattleFunc: [EnumKeyName.baseAttack.rawValue : 1, EnumKeyName.baseDef.rawValue : 1], inheritFunc: [:]),
        chessStruct(name: EnumChessName.abalone.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.inheritAddBuff.rawValue, EnumAbilities.bait.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [EnumKeyName.baseAttack.rawValue : 0, EnumKeyName.baseDef.rawValue : 4]),
        chessStruct(name: EnumChessName.tuna.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.instantAddBuff.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [EnumKeyName.baseAttack.rawValue : 0, EnumKeyName.baseDef.rawValue : 2]),
        chessStruct(name: EnumChessName.tuna.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.inheritAddBuff.rawValue, EnumAbilities.bait.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [EnumKeyName.baseAttack.rawValue : 0, EnumKeyName.baseDef.rawValue : 4]),
        chessStruct(name: EnumChessName.spiderCrab.rawValue.localized, desc: "", atkNum: 3, defNum: 1, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.bait.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.carp.rawValue.localized, desc: "", atkNum: 1, defNum: 4, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.spine.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.salamander.rawValue.localized, desc: "", atkNum: 2, defNum: 3, chessRarity: 2, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.chooseAKind.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
    ],
    [ //level3。 15个。   15
        chessStruct(name: EnumChessName.yak.rawValue.localized, desc: "", atkNum: 2, defNum: 5, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.liveInGroup.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.snowLeopard.rawValue.localized, desc: "", atkNum: 4, defNum: 2, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.rapid.rawValue, EnumAbilities.acute.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.pangolin.rawValue.localized, desc: "", atkNum: 2, defNum: 4, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.bait.rawValue], temporaryBuff:[EnumAbilities.shell.rawValue], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.mountainWolf.rawValue.localized, desc: "", atkNum: 3, defNum: 2, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.rapid.rawValue, EnumAbilities.liveInGroup.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.boar.rawValue.localized, desc: "", atkNum: 3, defNum: 4, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.immunePoison.rawValue, EnumAbilities.spine.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.quasipaa.rawValue.localized, desc: "", atkNum: 1, defNum: 6, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.bait.rawValue, EnumAbilities.instantAddBuff.rawValue], temporaryBuff:[], rattleFunc: [EnumKeyName.baseKind.rawValue : EnumChessKind.mountain.rawValue, EnumKeyName.baseAttack.rawValue: 1, EnumKeyName.baseDef.rawValue : 3], inheritFunc: [:]),
        chessStruct(name: EnumChessName.dragonFish.rawValue.localized, desc: "", atkNum: 1, defNum: 4, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.bait.rawValue, EnumAbilities.instantAddAbility.rawValue], temporaryBuff:[], rattleFunc: [EnumKeyName.abilityKind.rawValue : EnumAbilities.bait.rawValue], inheritFunc: [:]),
        chessStruct(name: EnumChessName.prawn.rawValue.localized, desc: "", atkNum: 1, defNum: 2, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.endRoundAddBuff.rawValue], temporaryBuff:[], rattleFunc: [EnumKeyName.baseKind.rawValue : [EnumChessKind.ocean.rawValue : 1], EnumKeyName.baseAttack.rawValue : 1 , EnumKeyName.baseDef.rawValue : 1], inheritFunc: [:]),
        chessStruct(name: EnumChessName.dolphin.rawValue.localized, desc: "", atkNum: 3, defNum: 3, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.ignoreBait.rawValue, EnumAbilities.liveInGroup.rawValue, EnumAbilities.immunePoison.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.pagurian.rawValue.localized, desc: "", atkNum: 3, defNum: 1, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.afterEliminatedAddAbilities.rawValue], temporaryBuff:[EnumAbilities.shell.rawValue], rattleFunc: [EnumKeyName.baseKind.rawValue : [EnumChessKind.ocean.rawValue], EnumKeyName.abilityKind.rawValue : [EnumAbilities.shell.rawValue]], inheritFunc: [:]),
        chessStruct(name: EnumChessName.puffer.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.instantAddAbility.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [EnumKeyName.baseKind.rawValue : EnumChessKind.ocean.rawValue ,EnumKeyName.abilityKind.rawValue : EnumAbilities.poison.rawValue]),
        chessStruct(name: EnumChessName.seaTurtle.rawValue.localized, desc: "", atkNum: 2, defNum: 4, chessRarity: 3, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.endRoundAddBuff.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [EnumKeyName.baseAttack.rawValue : 1 , EnumKeyName.baseDef.rawValue : 1])
    ],
    [ //level4。 9个    12
        chessStruct(name: EnumChessName.goldenEagle.rawValue.localized, desc: "", atkNum: 6, defNum: 3, chessRarity: 4, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.fly.rawValue, EnumAbilities.ignoreBait.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.whiteTiger.rawValue.localized, desc: "", atkNum: 5, defNum: 5, chessRarity: 4, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.furious.rawValue, EnumAbilities.instantRandomAddBuff.rawValue], temporaryBuff:[], rattleFunc: [EnumKeyName.baseAttack.rawValue:2, EnumKeyName.baseDef.rawValue:2, EnumKeyName.summonNum.rawValue:2, EnumKeyName.baseKind.rawValue: EnumChessKind.mountain.rawValue], inheritFunc: [:]),
        chessStruct(name: EnumChessName.blackBear.rawValue.localized, desc: "", atkNum: 4, defNum: 8, chessRarity: 4, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.instantChooseAnAbility.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
        chessStruct(name: EnumChessName.electricEel.rawValue.localized, desc: "", atkNum: 3, defNum: 2, chessRarity: 4, chessLevel: 1,chessKind: EnumChessKind.ocean.rawValue, abilities: [EnumAbilities.beforeAttackAoe.rawValue], temporaryBuff:[], rattleFunc: [EnumKeyName.baseDamage.rawValue : 2], inheritFunc: [:]),
        
    ],
    [ //level5。 6个      9
       chessStruct(name: EnumChessName.panda.rawValue.localized, desc: "", atkNum: 5, defNum: 5, chessRarity: 5, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.summonChessAddMountainBuff.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]),
       chessStruct(name: EnumChessName.tigerSnake.rawValue.localized, desc: "", atkNum: 5, defNum: 1, chessRarity: 5, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [EnumAbilities.poison.rawValue, EnumAbilities.inheritSummonSth.rawValue], temporaryBuff:[], rattleFunc: [:], inheritFunc: [EnumKeyName.baseRarity.rawValue : 3, EnumKeyName.summonNum.rawValue : 2])

    ]
]


public var chessDerivateCollections = [
    chessStruct(name: EnumChessName.wildRabbit.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]), // 001 小野兔
    chessStruct(name: EnumChessName.pygmyTarsier.rawValue.localized, desc: "", atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1,chessKind: EnumChessKind.mountain.rawValue, abilities: [], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]), // 002 侏儒眼镜猴
]
