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
    private let nameTextNode = TextNode()
    private let descTextNode = TextNode(textScale: SCNVector3(0.1, 0.1, 0.1))
    private let atkTextNode = TextNode()
    private let defTextNode = TextNode()
    private let priceTextNode = TextNode()

    private let damgeTextNode = TextNode(textScale: SCNVector3(0.5, 0.5, 0.01))
    private let abilitiesTriggerTextNode = TextNode(textScale: SCNVector3(0.5, 0.5, 0.01))
    var chessName: String = "" {
        didSet {
            nameTextNode.string = chessName
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
    var chessStatus: Int = EnumsChessStage.forSale.rawValue
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
    var abilities: [Int] = []
    var rattleFunc: [()] = []
    var inheritFunc: [()] = []
    override init()
       {
        super.init()
        let curNode = createChess()
        
        //bitmask
        curNode.categoryBitMask = BitMaskCategoty.baseChess.rawValue
        
        self.addChildNode(curNode)
        atkNum = 0
        defNum = 0
        if let nameLabelNode = curNode.childNode(withName: "nameLabel", recursively: true) {
            nameTextNode.position = SCNVector3(-0.01, -0.02 , 0)
            nameLabelNode.addChildNode(nameTextNode)
        }
        if let descLabelNode = curNode.childNode(withName: "descLabel", recursively: true) {
            descTextNode.position = SCNVector3(-0.5, -0.55 , 1)
            descLabelNode.addChildNode(descTextNode)
        }
        if let atkLabelNode = curNode.childNode(withName: "atkLabel", recursively: true) {
            atkTextNode.position = SCNVector3(-0.005, -0.01 , 0.1)
            atkLabelNode.addChildNode(atkTextNode)
        }
        if let defLabelNode = curNode.childNode(withName: "defLabel", recursively: true) {
            defTextNode.position = SCNVector3(-0.005, -0.01 , 0.1)
            defLabelNode.addChildNode(defTextNode)
        }
        if let priceLabelNode = curNode.childNode(withName: "priceLabel", recursively: true) {
            priceTextNode.position = SCNVector3(-0.005, -0.01 , 0.1)
            // init price by chess level ,should after priceLabelNode created
            chessPrice = (chessRarity / 2) + 3
            priceTextNode.string = String(chessPrice)
            priceLabelNode.addChildNode(priceTextNode)
        }
        
        if let sideNode = curNode.childNode(withName: "side", recursively: true) {
            sideNode.geometry?.firstMaterial?.diffuse.contents = chessColorRarity[chessRarity] //control chess color
            damgeTextNode.position = SCNVector3(0, 0.5 , 0)
            damgeTextNode.eulerAngles = SCNVector3(-60.degreesToRadius, 0 , 0)
            sideNode.addChildNode(damgeTextNode)
            //
            abilitiesTriggerTextNode.position = SCNVector3(0, 0.5, 0.1)
            abilitiesTriggerTextNode.eulerAngles = SCNVector3(-60.degreesToRadius, 0 , 0)
            sideNode.addChildNode(abilitiesTriggerTextNode)
            
        }
        
        
       }
    convenience init(statusNum: Int, chessInfo: chessStruct) {
        self.init()
        chessStatus = statusNum
        chessName = chessInfo.name!
        nameTextNode.string = chessName
        chessDesc = chessInfo.desc!
        descTextNode.string = chessDesc
        atkNum = chessInfo.atkNum
        atkTextNode.string = String(atkNum!)
        defNum = chessInfo.defNum
        defTextNode.string = String(defNum!)
        chessRarity = chessInfo.chessRarity!
        chessLevel = chessInfo.chessLevel!
        changeStarLabel()
        chessPrice = (chessRarity / 2) + 2
        priceTextNode.string = String(chessPrice)
        abilities = chessInfo.abilities
        rattleFunc = chessInfo.rattleFunc
        inheritFunc = chessInfo.inheritFunc
        if let sideNode = self.childNode(withName: "side", recursively: true) {
            sideNode.geometry?.firstMaterial?.diffuse.contents = chessColorRarity[chessRarity]
        }
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
    print(chessName, defNum)
      return baseChessNode(statusNum: chessStatus, chessInfo: chessStruct(name: chessName, desc: chessDesc, atkNum: atkNum!, defNum: defNum!, chessRarity: chessRarity, chessLevel: chessLevel, abilities: abilities, rattleFunc: rattleFunc, inheritFunc: inheritFunc))
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
           atkNum! += attAddNum
            atkTextNode.runAction(SCNAction.sequence([
                SCNAction.scale(by: 2, duration: 0.5),
                SCNAction.scale(by: 0.5, duration: 0.5)
            ]))
        }
        if let defAddNum = DefNumber {
            defNum! += defAddNum
            defTextNode.runAction(SCNAction.sequence([
                SCNAction.scale(by: 2, duration: 0.5),
                SCNAction.scale(by: 0.5, duration: 0.5)
            ]))
        }
       
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
