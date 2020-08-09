//
//  ChessNode.swift
//  archess
//
//  Created by zhaoheng sun on 1/12/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import SceneKit

public class baseChessNode: SCNNode {
    // MARK: - Lifecycle
    //var atk = 0
    //var def = 1
    private let nameTextNode = TextNode(textScale: SCNVector3(0.1, 0.2, 0.05))
    private let descTextNode = TextNode(textScale: SCNVector3(0.1, 0.1, 0.1))
    private let atkTextNode = TextNode()
    private let defTextNode = TextNode()
    private let priceTextNode = TextNode()
    
    private var particlePoison: SCNParticleSystem? = nil

    private let damgeTextNode = TextNode(textScale: SCNVector3(0.5, 0.5, 0.01))
    private let abilitiesTriggerTextNode = TextNode(textScale: SCNVector3(0.5, 0.5, 0.01))
    
    var isActive = false
    var rstAttackTimes = 1 //剩余攻击次数
    
    var chessName: String = "" {
        didSet {
            print(chessName.localized)
            nameTextNode.string = chessName.localized
        }
    }
    var chessDesc: String = "" {
        didSet {
            descTextNode.string = chessDesc
        }
    }
    var chessRarity: Int = 1 //棋子稀有度
    var chessLevel: Int = 1{ //棋子等级
        didSet {
            self.changeStarLabel()
                
        }
    }
    var chessStatus: Int = EnumsChessStage.forSale.rawValue {
        didSet {
            if let priceLabelNode = self.childNode(withName: "priceLabel", recursively: true) {
                if chessStatus == EnumsChessStage.forSale.rawValue {
                    priceLabelNode.isHidden = false
                } else {
                    priceLabelNode.isHidden = true
                }
            }
            if let nameLabelNode = self.childNode(withName: "nameLabel", recursively: true) {
                if chessStatus == EnumsChessStage.forSale.rawValue {
                    nameLabelNode.isHidden = false
                } else {
                    nameLabelNode.isHidden = true
                }
            }
        }
    }
    var chessPrice: Int = 3 {
        didSet {
            priceTextNode.string = String(chessPrice)
        }
    }
    var atkNum: Int? {
        didSet {
            atkTextNode.string = String(atkNum!)
        }
    }
    var defNum: Int? {
        didSet {
            defTextNode.string = String(defNum!)
        }
    }
    
    
    var damageNum: Int? {
        didSet {
            
            if let curDamage = damageNum {
                if curDamage > 0 {
                    damgeTextNode.string = "- " + String(curDamage)
                } else if curDamage < 0 {
                    damgeTextNode.string = "+ " + String(abs(curDamage))
                } else {
                    damgeTextNode.string = String(curDamage)
                }
                
            }
            damgeTextNode.runAction(SCNAction.sequence([
                SCNAction.fadeIn(duration: 0.1),
                SCNAction.wait(duration: 0.7),
                SCNAction.fadeOut(duration: 0.3)
            ]))
        }
    }
    var chessKind: String = EnumChessKind.mountain.rawValue {
        didSet {
            if let bgPicNode = self.childNode(withName: "bgpic", recursively: true) { //control the pic of bottom
                       bgPicNode.geometry?.firstMaterial?.diffuse.contents = chessKindBgImage[chessKind]!
                   }
        }
    }
    var abilities: [String] = [] {
        didSet {
            setBait()
            setPoison()
            if abilities.contains(EnumAbilities.rapid.rawValue) {
                rstAttackTimes = 2
            }
        }
    }
    var temporaryBuff: [String] = [] //临时性的Buff 类似硬壳 攻击 生命之类
        {
        didSet {
            toggleShell(status: temporaryBuff.contains(EnumAbilities.shell.rawValue))
        }
       }
    var rattleFunc: [Int : Any] = [:]
    var inheritFunc: [Int : Any] = [:]
    override init()
       {
        super.init()
        let curNode = createChess()
        
      
        //curNode.categoryBitMask = BitMaskCategoty.baseChess.rawValue
        //curNode.contactTestBitMask = BitMaskCategoty.hand.rawValue
        
        
        self.addChildNode(curNode)
        
        atkNum = 0
        defNum = 0

        if let nameLabelNode = curNode.childNode(withName: "nameLabel", recursively: true) {
            self.nameTextNode.eulerAngles = SCNVector3(-90.degreesToRadius, 0 , 0)
            self.nameTextNode.position = SCNVector3(-0.1, 0 , 0.6)
            nameLabelNode.addChildNode(self.nameTextNode)
        }
        if let descLabelNode = curNode.childNode(withName: "descLabel", recursively: true) {
            self.descTextNode.position = SCNVector3(-0.5, -0.55 , 1)
            descLabelNode.addChildNode(self.descTextNode)
        }
        if let atkLabelNode = curNode.childNode(withName: "atkLabel", recursively: true) {
            self.atkTextNode.position = SCNVector3(-0.005, -0.01 , 0.1)
            atkLabelNode.addChildNode(self.atkTextNode)
        }
        if let defLabelNode = curNode.childNode(withName: "defLabel", recursively: true) {
            self.defTextNode.position = SCNVector3(-0.005, -0.01 , 0.1)
            defLabelNode.addChildNode(self.defTextNode)
        }


        if let priceLabelNode = curNode.childNode(withName: "priceLabel", recursively: true) {
            self.priceTextNode.position = SCNVector3(-0.005, -0.01 , 0.1)
            // init price by chess level ,should after priceLabelNode created
            self.initChessPrice()
            self.priceTextNode.string = String(self.chessPrice)
            priceLabelNode.addChildNode(self.priceTextNode)
        }
        if let sideNode = curNode.childNode(withName: "side", recursively: true) {
            //bitmask
//            let shape = SCNPhysicsShape(geometry: sideNode.geometry!, options: nil)
//            let physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.static, shape: shape)
//            physicsBody.isAffectedByGravity = false
//            curNode.physicsBody = physicsBody
//            curNode.physicsBody?.categoryBitMask = BitMaskCategoty.baseChess.rawValue
//            curNode.physicsBody?.contactTestBitMask = BitMaskCategoty.hand.rawValue
    
            
            
            sideNode.geometry?.firstMaterial?.diffuse.contents = chessColorRarity[self.chessRarity] //control chess color
            self.nameTextNode.geometry?.firstMaterial?.diffuse.contents = labelColorRarity[self.chessRarity]
            self.damgeTextNode.position = SCNVector3(0, 0.5 , 0)
            self.damgeTextNode.eulerAngles = SCNVector3(-60.degreesToRadius, 0 , 0)
            sideNode.addChildNode(self.damgeTextNode)
            //
            self.abilitiesTriggerTextNode.position = SCNVector3(0, 0.5, 0.1)
            self.abilitiesTriggerTextNode.eulerAngles = SCNVector3(-60.degreesToRadius, 0 , 0)
            sideNode.addChildNode(self.abilitiesTriggerTextNode)

        }
        //补齐bitmask
        curNode.fixCategoryMasks(mask: BitMaskCategoty.baseChess.rawValue)
        
        //最后计算棋子的描述
        self.chessDesc = self.formatChessDesc()
        self.descTextNode.string = self.chessDesc
        
       }
    
//    public override func runAction(_ action: SCNAction) {
//        if !self.hasActions {
//            super.runAction(action)
//        }
//    }
    
    
    func exportCodeableStruct() -> codableChessStruct? {
        print("exportchessname", chessName)
        for i in 0 ..< chessCollectionsLevel[chessRarity - 1].count {
            if chessCollectionsLevel[chessRarity - 1][i].name == chessName {
                return codableChessStruct(chessRarityIndex: i, atkNum: atkNum!, defNum: defNum!, chessRarity: chessRarity, chessLevel: chessLevel, chessKind: chessKind, abilities: abilities, temporaryBuff: temporaryBuff)
            }
        }
        for i in 0 ..< chessDerivateCollections.count {
            if chessDerivateCollections[i].name == chessName { //稀有度为-1的是衍生物
                return codableChessStruct(chessRarityIndex: i, atkNum: atkNum!, defNum: defNum!, chessRarity: nil, chessLevel: chessLevel, chessKind: chessKind, abilities: abilities, temporaryBuff: temporaryBuff)
            }
        }
        return nil
    }
    func exportStruct() -> chessStruct {
       
        return chessStruct(name: chessName, desc: "", atkNum: atkNum ?? 1, defNum: defNum ?? 1, chessRarity: chessRarity, chessLevel: chessLevel, chessKind: chessKind, abilities: abilities, temporaryBuff: temporaryBuff, rattleFunc: rattleFunc, inheritFunc: inheritFunc)
    }
    
    
    convenience init(statusNum: Int, codeChessInfo: codableChessStruct) {
        self.init()
        chessStatus = statusNum
        let curIndex = codeChessInfo.chessRarityIndex ?? 0
        let curRaity = codeChessInfo.chessRarity ?? 1
        let curChessStruct:chessStruct
        if codeChessInfo.chessRarity != nil {
            curChessStruct = chessCollectionsLevel[curRaity - 1][curIndex] //普通怪
        } else {
            curChessStruct = chessDerivateCollections[curIndex] //衍生物
        }
        self.init(statusNum: statusNum, chessInfo: curChessStruct)
        //codeable
        atkNum = codeChessInfo.atkNum
        defNum = codeChessInfo.defNum
        atkTextNode.string = String(atkNum!)
        defTextNode.string = String(defNum!)
        chessLevel = codeChessInfo.chessLevel!
        changeStarLabel()
        chessKind = codeChessInfo.chessKind
        abilities = codeChessInfo.abilities
        temporaryBuff = codeChessInfo.temporaryBuff
        if let bgPicNode = self.childNode(withName: "bgpic", recursively: true) { //control the pic of bottom
                   bgPicNode.geometry?.firstMaterial?.diffuse.contents = chessKindBgImage[chessKind]!
               }
               
               if let shellNode = self.childNode(withName: "shell", recursively: true) { //control the shield
                   if temporaryBuff.contains(EnumAbilities.shell.rawValue) {
                       shellNode.isHidden = false
                   } else {
                       shellNode.isHidden = true
                   }
               }
               
        setBait() //诱饵
    }
    
    convenience init(statusNum: Int, chessInfo: chessStruct) {
        self.init()
        loadWithStruct(statusNum: statusNum, chessInfo: chessInfo)
        
    }
    func loadWithStruct(statusNum: Int, chessInfo: chessStruct) {
        chessStatus = statusNum
        chessName = chessInfo.name!
        //nameTextNode.string = chessName.localized
        //chessDesc = chessInfo.desc!
        //descTextNode.string = chessDesc
        atkNum = chessInfo.atkNum
        atkTextNode.string = String(atkNum!)
        defNum = chessInfo.defNum
        defTextNode.string = String(defNum!)
        chessRarity = chessInfo.chessRarity!
        chessLevel = chessInfo.chessLevel!
        changeStarLabel()
        
        chessKind = chessInfo.chessKind
        abilities = chessInfo.abilities
        temporaryBuff = chessInfo.temporaryBuff
        rattleFunc = chessInfo.rattleFunc
        inheritFunc = chessInfo.inheritFunc
        
        initChessPrice()
        priceTextNode.string = String(chessPrice)
        
        if abilities.contains(EnumAbilities.rapid.rawValue) { //如果是风怒则有两次剩余攻击机会
            rstAttackTimes = 2
        }
        
        if let aniPicNode = self.childNode(withName: "animalpic", recursively: true) {
            aniPicNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: chessName)
        }
        
        if let sideNode = self.childNode(withName: "side", recursively: true) { //control the side color/image
            sideNode.geometry?.firstMaterial?.diffuse.contents = chessColorRarity[chessRarity]!
            nameTextNode.geometry?.firstMaterial?.diffuse.contents = labelColorRarity[chessRarity]
        }
        if let bgPicNode = self.childNode(withName: "bgpic", recursively: true) { //control the pic of bottom
            bgPicNode.geometry?.firstMaterial?.diffuse.contents = chessKindBgImage[chessKind]!
        }
        
        if let shellNode = self.childNode(withName: "shell", recursively: true) { //control the shield
            if temporaryBuff.contains(EnumAbilities.shell.rawValue) {
                shellNode.isHidden = false
            } else {
                shellNode.isHidden = true
            }
        }
        
        setBait() //诱饵
        
        if let priceLabelNode = self.childNode(withName: "priceLabel", recursively: true) {
            if chessStatus == EnumsChessStage.forSale.rawValue {
                priceLabelNode.isHidden = false
            } else {
                priceLabelNode.isHidden = true
            }
        }
        if let nameLabelNode = self.childNode(withName: "nameLabel", recursively: true) {
            print(self.nameTextNode)
            print(self.nameTextNode.parent)
            if chessStatus == EnumsChessStage.forSale.rawValue {
                nameLabelNode.isHidden = false
            } else {
                nameLabelNode.isHidden = true
            }
        }
        //最后计算棋子的描述
        chessDesc = formatChessDesc()
        descTextNode.string = chessDesc
    }
    
    func changeStarLabel() {
        if let curStarLabel = self.childNode(withName: "starLabel", recursively: true) {
            if chessLevel == 1 {
                 curStarLabel.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "1star")
            } else if chessLevel == 2 {
                 curStarLabel.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "2stars")
            } else if chessLevel == 3 {
                 curStarLabel.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "3stars")
            }
        }
    }
  /// 实现Copy协议
  ///
  /// - Returns: 拷贝的对象
  func copyable() -> baseChessNode {
      return baseChessNode(statusNum: chessStatus, chessInfo: chessStruct(name: chessName, desc: chessDesc, atkNum: atkNum!, defNum: defNum!, chessRarity: chessRarity, chessLevel: chessLevel,chessKind: chessKind, abilities: abilities, temporaryBuff: temporaryBuff, rattleFunc: rattleFunc, inheritFunc: inheritFunc))
  }
    func abilityTrigger(abilityEnum : String) {
        abilitiesTriggerTextNode.string = abilityEnum //之后要改成多语言
        abilitiesTriggerTextNode.runAction(SCNAction.sequence([
            SCNAction.fadeIn(duration: 0.1),
            SCNAction.wait(duration: 0.7),
            SCNAction.fadeOut(duration: 0.3)
        ]))
    }
    func AddBuff(AtkNumber: Int?, DefNumber: Int?) {      
        if let attAddNum = AtkNumber {
            if attAddNum + atkNum! <= 0{
                atkNum = 1
            } else {
                atkNum! += attAddNum
            }
           
            atkTextNode.runAction(SCNAction.sequence([
                SCNAction.scale(by: 2, duration: 0.5),
                SCNAction.scale(by: 0.5, duration: 0.5)
            ]))
        }
        if let defAddNum = DefNumber {
            if defAddNum + defNum! <= 0{
                defNum = 1
            } else {
                defNum! += defAddNum
            }
            defTextNode.runAction(SCNAction.sequence([
                SCNAction.scale(by: 2, duration: 0.5),
                SCNAction.scale(by: 0.5, duration: 0.5)
            ]))
        }
       
    }
    func getDamage(damageNumber: Int, chessBoard: inout [baseChessNode]) -> Bool { //true alive false eliminated
        if damageNumber <= 0 {
            return true
        }
        if temporaryBuff.contains(EnumAbilities.shell.rawValue) {
           toggleShell(status: false)
        } else {
            damageNum = damageNumber
            defNum = defNum! - damageNumber
            if defNum! <= 0 {
                for index in 0 ..< chessBoard.count {
                    if chessBoard[index] == self {
                        chessBoard.remove(at: index)
                        break
                    }
                }
                return false
            }
        }
       return true
    }
    
 
    
    func toggleShell(status: Bool) { //control shell turn on/off
        if let shellNode = self.childNode(withName: "shell", recursively: true) {
             if status == true {
                       if !temporaryBuff.contains(EnumAbilities.shell.rawValue) {
                          temporaryBuff.append(EnumAbilities.shell.rawValue)
                       }
                        
                        shellNode.runAction(SCNAction.sequence([
                            SCNAction.fadeOpacity(to: 0.1, duration: 0.5),
                          SCNAction.customAction(duration: 0, action: { _,_ in
                              shellNode.isHidden = false
                          })
                        ]))
                   } else {
                      if temporaryBuff.contains(EnumAbilities.shell.rawValue) {
                          temporaryBuff.remove(at: temporaryBuff.lastIndex(of: EnumAbilities.shell.rawValue)!) //已经判断必定能找到
                       }
                        shellNode.runAction(SCNAction.sequence([
                          SCNAction.fadeOut(duration: 0.5),
                          SCNAction.customAction(duration: 0, action: { _,_ in
                              shellNode.isHidden = true
                          })
                        ]))
                }
        }
    }
    
    func AddBilities(Abilities: [String]) { //添加所属能力 需要加上一个字从空中飘到描述里的动画
        var tempAbilities:[String] = []
        Abilities.forEach{ (curAbi) in
            if !abilities.contains(curAbi) {
                tempAbilities.append(curAbi)
            }
        }
         abilities += tempAbilities
        //最后计算棋子的描述 可以移动到abilities监听器里
        chessDesc = formatChessDesc()
    }
    func AddTempBuff(tempBuff: [String]) { //添加临时能力
        var tempBuffArr:[String] = []
        tempBuff.forEach{ (curAbi) in
            if !abilities.contains(curAbi) {
                tempBuffArr.append(curAbi)
            }
        }
         temporaryBuff += tempBuffArr
    }
    //
    func setBait() {
        if let baitNode = self.childNode(withName: "baitLine", recursively: true) { // contol the bait line
            if abilities.contains(EnumAbilities.bait.rawValue) {
                baitNode.isHidden = false
            } else {
                baitNode.isHidden = true
            }
        }
    }
    
    func setPoison() {
        if abilities.contains(EnumAbilities.poison.rawValue) {
            particlePoison = addParticleSystem(particleName: "particals.scnassets/poison.scnp")
        } else {
            if let curPar = particlePoison {
                if let particleNode = self.childNode(withName: "particleNode", recursively: true) {
                    particleNode.removeParticleSystem(curPar)
                }
            }
        }
    }
    
    
    func formatChessDesc() -> String{ //当前只需要abilities里面的 后期有必要可以加上战吼之类的 TODO!!
        var tempDescStr = ""
        abilities.forEach{(curAbi) in
            var abilityDesc = curAbi.localized
            if case let curBaseAtt as Int = rattleFunc[EnumKeyName.baseAttack.rawValue] {
                abilityDesc = abilityDesc.replacingOccurrences(of: "<att>", with: String(curBaseAtt * chessLevel))
            }
            
            if case let curBaseDef as Int = rattleFunc[EnumKeyName.baseDef.rawValue] {
                abilityDesc = abilityDesc.replacingOccurrences(of: "<def>", with: String(curBaseDef * chessLevel))
            }
            
            //kind
            if case let curInstantKind as [String] = rattleFunc[EnumKeyName.baseKind.rawValue] { //数组形式的basekind
                abilityDesc = abilityDesc.replacingOccurrences(of: "[kind]", with: (curInstantKind).joined(separator: " "))
            }
            if case let curInstantKind as [String: Int] = rattleFunc[EnumKeyName.baseKind.rawValue] { //数组形式的basekind
                let kinds = Array(curInstantKind.keys)
                abilityDesc = abilityDesc.replacingOccurrences(of: "[kind]", with: (kinds).joined(separator: " "))
            }
            
           
            if let curValue = rattleFunc[EnumKeyName.customValue.rawValue] {
                abilityDesc = abilityDesc.replacingOccurrences(of: "<value>", with: (String(curValue as! Int)))
            }
            
   
            if case let curRattleChess as [chessStruct] = rattleFunc[EnumKeyName.summonChess.rawValue] {
                var curSummonName:String = ""
                curRattleChess.forEach{ (curSummon) in
                    curSummonName += ((curSummon.name ?? "") + " ")
                }
                abilityDesc = abilityDesc.replacingOccurrences(of: "[chesses]", with: curSummonName)
            }
            
       
            if case let curAfterKind as [String] = rattleFunc[EnumKeyName.baseKind.rawValue] {
                var curAfterKindStr = ""
                for i in 0 ..< curAfterKind.count {
                    curAfterKindStr += (curAfterKind[i]).localized
                    if i != curAfterKind.count - 1 {
                        curAfterKindStr += "Or".localized
                    }
                }
                abilityDesc = abilityDesc.replacingOccurrences(of: "[cKind]", with: curAfterKindStr)
            }
            
            if case let curAfterAbility as [String] = rattleFunc[EnumKeyName.abilityKind.rawValue] {
                var curAfterAbilityStr = ""
                for i in 0 ..< curAfterAbility.count {
                    curAfterAbilityStr += (curAfterAbility[i]).localized
                    if i != curAfterAbility.count - 1 {
                        curAfterAbilityStr += "And".localized
                    }
                }
                abilityDesc = abilityDesc.replacingOccurrences(of: "[aKind]", with: curAfterAbilityStr)
            }
            
         
            
            //damage appear
            if case let curInheritDamage as Int = inheritFunc[EnumKeyName.baseDamage.rawValue] {
                abilityDesc = abilityDesc.replacingOccurrences(of: "<dam>", with: (String(curInheritDamage * chessLevel)))
            }
            if case let curRattleDamage as Int = rattleFunc[EnumKeyName.baseDamage.rawValue] {
                abilityDesc = abilityDesc.replacingOccurrences(of: "<dam>", with: (String(curRattleDamage * chessLevel)))
            }
            
            
            
            if case let curRattleNum as Int = inheritFunc[EnumKeyName.summonNum.rawValue] {
                abilityDesc = abilityDesc.replacingOccurrences(of: "<num>", with: (String(curRattleNum)))
            }
   
            //部分特殊技能
            if curAbi == EnumAbilities.summonChessAddMountainBuff.rawValue {
                abilityDesc = abilityDesc.replacingOccurrences(of: "<att>", with: String(1 * chessLevel))
                abilityDesc = abilityDesc.replacingOccurrences(of: "<def>", with: String(1 * chessLevel))
            } else if curAbi == EnumAbilities.summonChessAddBuff.rawValue {
                abilityDesc = abilityDesc.replacingOccurrences(of: "<att>", with: String(1 * chessLevel))
                abilityDesc = abilityDesc.replacingOccurrences(of: "<def>", with: String(1 * chessLevel))
            } else if curAbi == EnumAbilities.acute.rawValue {
                abilityDesc = abilityDesc.replacingOccurrences(of: "<def>", with: String(20 * chessLevel) + "%")
            } else if curAbi == EnumAbilities.liveInGroup.rawValue {
                abilityDesc = abilityDesc.replacingOccurrences(of: "<def>", with: String(20 * chessLevel) + "%")
            }
            
      
            
           tempDescStr += abilityDesc
           tempDescStr += " "
            
//            if curAbi == EnumAbilities.acute.rawValue {
//                tempDescStr += curAbi.localized.replacingOccurrences(of: "<percent>", with: String(chessLevel * 20))
//            } else if curAbi == EnumAbilities.liveInGroup.rawValue {
//                tempDescStr += curAbi.localized.replacingOccurrences(of: "<percent>", with: String(chessLevel * 20))
//            } else if curAbi == EnumAbilities.instantAddBuff.rawValue {
//
//                let curBaseAtt = rattleFunc[EnumKeyName.baseAttack.rawValue] ?? 1
//                let curBaseDef = rattleFunc[EnumKeyName.baseDef.rawValue] ?? 1
//                let curInstantKind = rattleFunc[EnumKeyName.baseKind.rawValue] ?? []
//                let tempStr = (curInstantKind as! [String]).joined(separator: " ")
//
//
//                tempDescStr += curAbi.localized.replacingOccurrences(of: "<att>", with: String(curBaseAtt as! Int * chessLevel)).replacingOccurrences(of: "def", with: String(curBaseDef as! Int * chessLevel)).replacingOccurrences(of: "[kind]", with: tempStr)
//
//
//
//               tempDescStr += curAbi.localized.replacingOccurrences(of: "<kind>", with: String(chessLevel * 1))
//            } else if curAbi == EnumAbilities.beforeAttackAoe.rawValue {
//               tempDescStr += curAbi.localized.replacingOccurrences(of: "<kind>", with: String(chessLevel * 1))
//            } else if curAbi == EnumAbilities.endRoundAddBuff.rawValue {
//                let curEndAtt = rattleFunc[EnumKeyName.baseAttack.rawValue] ?? 1
//                let curEndDef = rattleFunc[EnumKeyName.baseDef.rawValue] ?? 1
//                let curEndKindMap  = rattleFunc[EnumKeyName.baseKind.rawValue] ?? [:]
//                var tempKindString = ""
//                for (key, val) in curEndKindMap as! [String : Int] {
//                    tempKindString += (key + ",")
//                }
//                tempKindString += "Chess".localized
//                if case let isSelf as Bool = rattleFunc[EnumKeyName.isSelf.rawValue]{
//                    if isSelf {
//                        tempKindString = "Self".localized
//                    }
//                }
//
//                tempDescStr += curAbi.localized.replacingOccurrences(of: "<att>", with: String(curEndAtt as! Int * chessLevel)).replacingOccurrences(of: "def", with: String(curEndDef as! Int * chessLevel)).replacingOccurrences(of: "[kind]", with: tempKindString)
//            } else if curAbi == EnumAbilities.instantSummonSth.rawValue {
//                if case let curRattleChess as [chessStruct] = rattleFunc[EnumKeyName.summonChess.rawValue] {
//                    var curSummonName:String = ""
//                    curRattleChess.forEach{ (curSummon) in
//                        curSummonName += ((curSummon.name ?? "") + " ")
//                    }
//                    tempDescStr += curAbi.localized.replacingOccurrences(of: "[chesses]",with: curSummonName)
//                }
//            } else if curAbi == EnumAbilities.inheritDamage.rawValue {
//                if case let curRattleDamage as Int = inheritFunc[EnumKeyName.baseDamage.rawValue] {
//                    if case let curRattleNum as Int = inheritFunc[EnumKeyName.summonNum.rawValue] {
//                        tempDescStr += curAbi.localized.replacingOccurrences(of: "<dam>", with: String(curRattleDamage * chessLevel)).replacingOccurrences(of: "<num>", with: String(curRattleNum))
//                    }
//                }
//
//            } else if curAbi == EnumAbilities.instantRandomAddBuff.rawValue {
//                if case let curRattleAtt as Int = rattleFunc[EnumKeyName.baseAttack.rawValue] {
//                    if case let curRattleDef as Int = rattleFunc[EnumKeyName.baseDef.rawValue] {
//                        if case let curRattleNum as Int = rattleFunc[EnumKeyName.summonNum.rawValue] {
//                            if case let curRattleKind as String = rattleFunc[EnumKeyName.baseKind.rawValue] {
//                                tempDescStr += curAbi.localized.replacingOccurrences(of: "<att>", with: String(curRattleAtt)).replacingOccurrences(of: "<def>", with: String(curRattleDef)).replacingOccurrences(of: "<num>", with: String(curRattleNum)).replacingOccurrences(of: "[kind]", with: curRattleKind)
//                            }
//                        }
//                    }
//                }
//            } else if curAbi == EnumAbilities.afterEliminatedAddBuff.rawValue {
//                if case let curAfterKind as [String] = rattleFunc[EnumKeyName.baseKind.rawValue] {
//
//                    let curEndAtt = rattleFunc[EnumKeyName.baseAttack.rawValue] ?? 1
//                    let curEndDef = rattleFunc[EnumKeyName.baseDef.rawValue] ?? 1
//
//                    var curAfterKindStr = " "
//                    curAfterKind.forEach { kindStr in
//                        curAfterKindStr += kindStr.localized
//                        curAfterKindStr += " "
//                    }
//
//                    tempDescStr += curAbi.localized.replacingOccurrences(of: "<att>", with: String(curEndAtt as! Int)).replacingOccurrences(of: "<def>", with: String(curEndDef as! Int)).replacingOccurrences(of: "[kind]", with: curAfterKindStr)
//
//                }
//            }  else if curAbi == EnumAbilities.afterEliminatedAddAbilities.rawValue {
//                if case let curAfterKind as [String] = rattleFunc[EnumKeyName.baseKind.rawValue] {
//                        if case let curAfterAbility as [String] = rattleFunc[EnumKeyName.abilityKind.rawValue] {
//                           var curAfterKindStr = ""
//                            for i in 0 ..< curAfterKind.count {
//                                curAfterKindStr += (curAfterKind[i]).localized
//                                if i != curAfterKind.count - 1 {
//                                    curAfterKindStr += "Or".localized
//                                }
//                            }
//                            var curAfterAbilityStr = ""
//                            for i in 0 ..< curAfterAbility.count {
//                                curAfterAbilityStr += (curAfterAbility[i]).localized
//                                if i != curAfterAbility.count - 1 {
//                                    curAfterAbilityStr += "And".localized
//                                }
//                            }
//                            tempDescStr += curAbi.localized.replacingOccurrences(of: "[cKind]", with: curAfterKindStr).replacingOccurrences(of: "[aKind]", with: curAfterAbilityStr)
//                        }
//                }
//            } else if curAbi == EnumAbilities.afterSummonAdjecentAddBuff.rawValue {
//                let curEndAtt = rattleFunc[EnumKeyName.baseAttack.rawValue] ?? 1
//                                  let curEndDef = rattleFunc[EnumKeyName.baseDef.rawValue] ?? 1
//
//                tempDescStr += curAbi.localized.replacingOccurrences(of: "<att>", with: String(curEndAtt as! Int)).replacingOccurrences(of: "<def>", with: String(curEndDef as! Int))
//
//            } else if curAbi == EnumAbilities.customValue.rawValue || curAbi == EnumAbilities.customSellValue.rawValue {
//                let curValue = rattleFunc[EnumKeyName.customValue.rawValue] ?? 1
//                tempDescStr += curAbi.localized.replacingOccurrences(of: "<value>", with: String(curValue as! Int))
//
//            } else {
//                let curBasedamage = rattleFunc[EnumKeyName.baseDamage.rawValue] ?? 1
//                tempDescStr += curAbi.localized.replacingOccurrences(of: "<dam>", with: String(curBasedamage as! Int * chessLevel))
//            }
//                tempDescStr += " "
        }
        return tempDescStr
    }
    
    //用于标识棋子可被选择 用于战吼 等场景。当前的操作就是把棋子变绿 之后确定棋子模型后优化
    func setActive() {
        isActive = true
        if let sideNode = self.childNode(withName: "side", recursively: true) {
            sideNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        }
    }
    func cancelActive() {
      isActive = false
       if let sideNode = self.childNode(withName: "side", recursively: true) {
           sideNode.geometry?.firstMaterial?.diffuse.contents = chessColorRarity[chessRarity]
        }
    }
    /*攻击频率相关方法*/
    func attackOnce() {
        if rstAttackTimes > 0 {
            rstAttackTimes -= 1
        }
    }
    func recoverAttackTimes() {
        if abilities.contains(EnumAbilities.rapid.rawValue){
            rstAttackTimes = 2
        } else {
            rstAttackTimes = 1
        }
    }
    
    func initChessPrice() {
        if abilities.contains(EnumAbilities.customValue.rawValue) {
            
            if case let curValue as Int = rattleFunc[EnumKeyName.customValue.rawValue]{
                chessPrice = curValue
            } else {
                chessPrice = 1
            }
         
            
        } else {
           chessPrice = (chessRarity / 2) + 3
        }
    }
    
    func addParticleSystem(particleName: String) -> SCNParticleSystem? {
        if let particleNode = self.childNode(withName: "particleNode", recursively: true) {
            if let particle = SCNParticleSystem(named: particleName, inDirectory: nil) {
                particle.emitterShape = SCNSphere(radius: 0.01)
                particleNode.addParticleSystem(particle)
                return particle
            }
        }
        return nil
    }
   
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
//    public func plusPoints() {
//        handPoints += 1
//    }
//    public func subPoints() {
//        if handPoints > 0 {
//            handPoints -= 1
//        } else {
//            handPoints = 0
//        }
//    }
}
