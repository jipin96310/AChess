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
    case enemySide = 3
    case allySide = 4
    case storageSide = 5
    case saleScreen = 6
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
enum EnumsHandGesture: String {
    case closedFist = "closedFist"
    case openFist = "openFist"
    case none = "none"
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
    case storageSide = 2
}

enum EnumNodeName: String {
    case saleStage = "saleStage"
    case storagePlace = "storagePlace"
    case allyBoard = "allyBoard"
    case enemyBoard = "enemyBoard"
}
enum EnumAbilities: String {
    case liveInGroup = "LiveInGroup" //群居
    case furious     = "Furious" //凶猛
    case poison      = "Poison" //剧毒
    case rapid    = "Rapid" // 疾速
    case acute    = "Acute" //敏锐
    case fly = "Fly"
    case shell = "Shell"
    case bait = "Bait" //诱饵
    case ignoreBait = "IgnoreBait" //无视诱饵
    case spine = "Spine" //尖刺
    case inheritAddBuff = "InheritAddBuff" //传承加buff
    case inheritSummonSth = "InheritSummonSth" //传承召唤
    case inheritDamage = "InheritDamage" //亡语伤害
    case endRoundAddBuff = "EndRoundAddBuff" //回合结束获得buff
    case instantAddBuff = "InstantAddBuff" //战吼加指定单位buff
    case instantAddAbility = "InstantAddAbility" //战吼加指定单位ability
    case instantChooseAnAbility = "InstantChooseAnAbility" //战吼进化
    case instantChooseAnAbilityForMountain = "InstantChooseAnAbilityForMountain" //战吼种族进化
    case instantAllGainAbilityForMountain = "InstantAllGainAbilityForMountain" //战吼全体山川生物获得能力
    case instantDestroyAllyGainBuff = "InstantDestroyAllyGainBuff" //消灭一个友方棋子（不会获得金钱）获得该棋子的身材
    case immunePoison = "ImmunePoison" //免疫剧毒
    case instantSummonSth = "InstantSummonSth" //战吼召唤生物
    case instantRandomAddBuff = "InstantRandomAddBuff" //战吼随机加buff
    case instantReduceBuff = "InstantReduceBuff" //战吼减buff
    //summon case
    case summonChessAddMountainBuff = "SummonChessAddMountainBuff" //熊猫专属技能 无需适配扩展性
    case summonChessAddSelfBuff = "SummonChessAddSelfBuff" //召唤棋子增加自身buff 当前野牛专用 不扩展
    case summonChessAddBuff = "SummonChessAddBuff" //召唤棋子增加自身buff 当前狮子专用 不扩展
    case afterSummonAdjecentAddBuff = "AfterSummonAdjecentAddBuff" //使两边棋子获得效果 狒狒暂时专属
    case afterSummonChessAddShell = "AfterSummonChessAddShell" // 犀牛专属
    //attack case
    case afterEliminatedAddBuff = "AfterEliminatedAddBuff" //生物被消灭后addbuff
    case afterEliminatedAddAbilities = "AfterEliminatedAddAbilities" //生物被消灭后addAbilities
    case chooseAKind = "ChooseAKind" //选择一个种族
    case beforeAttackAoe = "BeforeAttackAoe" //攻击前对敌方全体造成aoe伤害
    case afterAttackAoe = "AfterAttackAoe" //攻击后对所有敌方全体造成aoe伤害
    case lessBloodEliminated = "LessBloodEliminated" //血量小于则被直接击杀
    case allInheritMax = "AllInheritMax" //所有传承效果为满级
    case customValue = "CustomValue" //自定义价值
    case customSellValue = "CustomSellValue" //自定义出售价格
    case stealAura = "StealAura" //获得偷取aura
    case sputtering = "Sputtering" //溅射
}
//public let EnumAbiNumToName: [Int:String] =
//    [0: "",
//     1: ""]
enum EnumString: String {
    case exchangeStage = "ExchangeStage"
    case battleStage = "BattleStage"
    case chooseAnChess = "ChooseAnChess"
    case chooseAnOption = "ChooseAnOption"
    case inheritance = "Inheritance"
//    case poision    = "Poison"
//    case liveInGroup = "LiveInGroup" //群居
//    case furious    = "Furious" //凶猛
//    case rapid      = "Rapid"   //迅捷
}
enum EnumChessKind: String {
    case mountain = "Mountain"
    case ocean = "Ocean"
    case plain = "Plain"
    case frost = "Frost"
    case desert = "Desert"
    case polar = "Polar"
}
enum EnumKeyName: Int {
    case summonChess = 0
    case summonNum = 1
    case baseDamage = 2
    case baseAttack = 3
    case baseDef = 4
    case baseKind = 5
    case baseRarity = 6
    case abilityKind = 7 //能力类型
    case isSelf = 8 //是否作用与自己
    case customValue = 9 //自定义数字
    case isShareBoard = 10 //是否共享棋盘
    case playerNumber = 11 //玩家人数
}

//棋子名字
enum EnumChessName: String {
    /*mountain*/
    case mountainBird = "MountainBird" //山雀
    case wildRabbit = "WildRabbit" //野兔
    case hedgehog = "Hedgehog" //刺猬
    case tarsier = "Tarsier" //眼镜猴
    case snubNosedMonkey = "SnubNosedMonkey" //金丝猴
    case wolfSpider = "WolfSpider" //狼蛛
    case pheasant = "Pheasant" //山鸡
    case alpDog = "AlpDog" //高山犬
    case argali = "Argali" //盘羊
    case pygmyTarsier = "PygmyTarsier" //侏儒眼镜猴
    case yak = "Yak" //牦牛
    case snowLeopard = "SnowLeopard" //雪豹
    case pangolin = "Pangolin" //雪豹
    case mountainWolf = "MountainWolf" //落基山狼
    case boar         = "Boar" //野猪
    case quasipaa     = "Quasipaa" //石蛙
    case goldenEagle  = "GoldenEagle" //金雕
    case whiteTiger = "WhiteTiger" //白虎
    case blackBear = "BlackBear" //黑熊
    case panda     = "Panda" //熊猫
    case tigerSnake = "TigerSnake" //虎蛇
    /*ocean*/
    case killerWhale = "KillerWhale"//虎鲸
    case greatWhite = "GreatWhite"; //大白鲨
    case crucian    = "Crucian"; //鲫鱼
    case sardine = "Sardine"; //沙丁鱼
    case riverCrab = "RiverCrab"; //河蟹
    case freshwaterCrocodile = "FreshwaterCrocodile"; //淡水鳄
    case cyaneaNozakii = "CyaneaNozakii"; //霞水母
    case lobster = "Lobster"; //澳洲大龙虾
    case abalone = "Abalone"; //鲍鱼
    case tuna = "Tuna"; //金枪鱼
    case spiderCrab = "SpiderCrab"; //蜘蛛蟹
    case carp = "Carp"; //鲤鱼
    case dragonFish = "Dragonfish"; //深海龙鱼
    case prawn = "Prawn"; //明虾
    case dolphin = "Dolphin"; //海豚
    case pagurian = "Pagurian"; //寄居蟹
    case puffer = "Puffer"; //河豚
    case seaTurtle = "SeaTurtle"; //海龟
    case salamander = "Salamander"; //大鲵
    case electricEel = "ElectricEel"; //电鳗
    /*plain*/
    case flickertail = "Flickertail"; //金花鼠
    case duck = "Duck"; //鸭子
    case rooster = "Rooster"; //公鸡
    case hen = "Hen"; //母鸡
    case marmot = "Marmot"; //土拨鼠
    case weasel = "Weasel"; //黄鼠狼
    case mouse = "Mouse"; //老鼠
    case tigerFrog = "TigerFrog"; // 虎纹蛙
    case dog = "Dog"; //家狗
    case wildCat = "WildCat"; //野猫
    case sheep = "Sheep"; //绵羊
    case bat = "Bat"; //蝙蝠
    case buffalo = "Buffalo"; //野牛
    case baboon = "Baboon"; //狒狒
    case cheetah = "Cheetah"; //猎豹
    case giraffe = "Giraffe"; //长颈鹿
    case rhinoceros = "Rhinoceros"; //犀牛
    case kingCobra = "KingCobra"; //王蛇
    case ratel = "Ratel"; //蜜獾
    case lion = "Lion"; //狮子
    case elephant = "Elephant"; //大象
    case vegetarian = "Vegetarian"; //素食主义者
    case scientist = "Scientist"; //科学家
    case martialArtist = "MartialArtist";//武术家
    
}
//光环名称
enum EnumAuraName: String {
    case mountainLevel1 = "MountainLevel1" //崇山峻岭
    case mountainLevel2 = "MountainLevel2" //虎啸龙吟
    case oceanLevel1 = "OceanLevel1"
    case oceanLevel2 = "OceanLevel2"
    case plainLevel1 = "PlainLevel1"
    case plainLevel2 = "PlainLevel2"
}
//技能类型
enum EnumAbilityType: String {
    case inherit = "Inheritance"
}
//command
enum EnumMessageCommand: String {
    case switchGameStage = "SwitchGameStage"
    case winTheGame = "WinTheGame"
}

enum EnumBoardString: String {
    case enemyBoard = "enemyBoard"
    case allyBoard = "allyBoard"
}



