//
//  ChessBoardNode.swift
//  AChess
//
//  Created by zhaoheng sun on 7/18/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//
import PromiseKit
import Foundation
import SceneKit
import ARKit

private let boardPath = "art.scnassets/playerBoard"
private let defaultSize = CGSize(width: 2.4, height: 1.6)
private let defaultBoardName = "playerBoard"
private let boardStrings = "levels"

class ChessBoardNode: SCNNode {
    

 
    let totalUpdateTime:Double = 1 //刷新时间
    var boardRootName = "DefaultBoard"
    var curStage: Int = EnumsGameStage.exchangeStage.rawValue
    var curDragPoint: baseChessNode? = nil
    var updatePromise:Resolver<Double>? = nil
    
    var showStrageBoard = true {
        didSet {
            guard let storageNodeTemp = stroageNodeTemplate else {
                return
            }
            if showStrageBoard {
                storageNodeTemp.isHidden = false
            } else {
                storageNodeTemp.isHidden = true
            }
        }
    }
    
    var boardRootNode :[[SCNNode]] = [[],[]] //chess holder
       var storageNode : [baseChessNode] = [] {
           didSet(oldBoard) {
    //
    //                   for innerIndex in 0 ..< storageNode.count {
    //                       if !oldBoard.contains(storageNode[innerIndex]) {
    //                           storageNode[innerIndex].position.y = 0.01
    //                           playerBoardNode.addChildNode(storageNode[innerIndex])
    //                       }
    //                   }
    //                   updateStorageBoardPosition()  //dont delete
           }
       }
       var storageRootNode : [SCNNode] = []
    var boardChessess:[[baseChessNode]] = [[],[]]
    {
                didSet(oldBoard) {
                    guard let curBoardNode = boardNodeTemplate else { return }
                    
                    if (curStage == EnumsGameStage.exchangeStage.rawValue) {

                        var chessTimesDic:[[String : [Int]]] = [[:],[:],[:]] //棋子map 刷新问题
                        var chessKindMap:[String : Int] = [:]
                        var newCombineChess: [baseChessNode] = []
                        var oldSubChessIndex: [Int] = []
                        //for index in 0 ..< boardNode.count {
                        for innerIndex in 0 ..< boardChessess[BoardSide.allySide.rawValue].count {
                            //if index == BoardSide.allySide.rawValue{
                            let curChessNode = boardChessess[BoardSide.allySide.rawValue][innerIndex]
                            /*光环效果-只在交易阶段更新aura*/
                            if chessKindMap[curChessNode.chessKind] != nil {
                                chessKindMap[curChessNode.chessKind]! += 1
                            } else {
                                chessKindMap[curChessNode.chessKind] = 1
                            }
                            if (curChessNode.chessLevel < 3) { //只有己方 echange stage才触发
                                /*棋子合成*/
                                if chessTimesDic[curChessNode.chessLevel][curChessNode.chessName] != nil {
                                    chessTimesDic[curChessNode.chessLevel][curChessNode.chessName]!.append(innerIndex)
                                    if chessTimesDic[curChessNode.chessLevel][curChessNode.chessName]!.count >= 3 { //合成
                                        var subChessNodes:[baseChessNode] = []
                                        chessTimesDic[curChessNode.chessLevel][curChessNode.chessName]?.forEach{(subIndex) in
                                            subChessNodes.append(boardChessess[BoardSide.allySide.rawValue][subIndex])
                                        }
                                        let newNode = generateUpgradeChess(subChessNodes)
                                        newCombineChess.append(newNode)
                                        oldSubChessIndex += chessTimesDic[curChessNode.chessLevel][curChessNode.chessName]!
                                        chessTimesDic[curChessNode.chessLevel][curChessNode.chessName] = []
                                    }
                                } else {
                                    chessTimesDic[curChessNode.chessLevel][curChessNode.chessName] = [innerIndex]
                                }
                                
                            }
                            // }
                            
                        }
                       // }
                        if oldSubChessIndex.count > 0 {//说明有棋子合成
                            //移除旧的棋子。todo!!!!! 写的方法可以优化
                            var tempIndex = -1
                            var newAllyBoard:[baseChessNode] = [] //新期盼
                            newAllyBoard = boardChessess[BoardSide.allySide.rawValue].filter{(item) in
                                tempIndex += 1
                                return !oldSubChessIndex.contains(tempIndex)
                            }
                            
                            //置入合成棋子
                            newCombineChess.forEach{(newNode) in
                                if newAllyBoard.count < GlobalCommonNumber.chessNumber {
                                    newAllyBoard.append(newNode)//直接置入本方场内 后期可以修改为置入等待区域
                                }
                            }
                            //赋值更新
                            boardChessess[BoardSide.allySide.rawValue] = newAllyBoard
                            if (curDragPoint != nil) {
                                curDragPoint!.removeFromParentNode()
                            }
                        }
                         /*棋子合成end*/
      
                    }
                    
                    
                    
                    
                    for boardIndex in 0 ..< boardChessess.count {
                        for innerIndex in 0 ..< boardChessess[boardIndex].count {
                            if !oldBoard[boardIndex].contains(boardChessess[boardIndex][innerIndex]) {
                                let curNode = self.boardChessess[boardIndex][innerIndex]
                                curNode.position.y = 0.01
                                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.1 * Double((innerIndex + 1))) {
                                        curBoardNode.addChildNode(curNode)
                                }
                            }
                        }
                    }
                    //以下为战斗回合
                    var inheritPromiseArr:[() -> (Promise<Double>)] = []
                    var isAlive = true //是否有延展性消灭
                    var needDeleteChesses:[baseChessNode] = [] //需要删除的棋子
                    for boardIndex in 0 ..< oldBoard.count {
                        for innerIndex in 0 ..< oldBoard[boardIndex].count {
                            if !boardChessess[boardIndex].contains(oldBoard[boardIndex][innerIndex]) {
                                if (curStage == EnumsGameStage.battleStage.rawValue) { //亡语生效
                                    var isMaxLevel = false
                                    /*AllInheritMax*/
                                    for subIndex in 0 ..< boardChessess[boardIndex].count {
                                        if boardChessess[boardIndex][subIndex].abilities.contains(EnumAbilities.allInheritMax.rawValue) {
                                            isMaxLevel = true
                                            break
                                        }
                                    }
                                    /*End*/
                                    let erasedChess = oldBoard[boardIndex][innerIndex]
                                    let oppoBoardSide = boardIndex == BoardSide.allySide.rawValue ? BoardSide.enemySide.rawValue : BoardSide.allySide.rawValue
                                    let curStar = isMaxLevel ? GlobalCommonNumber.maxStars : erasedChess.chessLevel
                                    self.boardChessess[boardIndex].forEach{ (curBuffChess) in
                                        if curBuffChess.abilities.contains(EnumAbilities.afterEliminatedAddBuff.rawValue) {
                                            if case let curAfterKind as [String] = curBuffChess.rattleFunc[EnumKeyName.baseKind.rawValue] {
                                                if curAfterKind.contains(erasedChess.chessKind) {
                                                    let curEndAtt = curBuffChess.rattleFunc[EnumKeyName.baseAttack.rawValue] ?? 1
                                                    let curEndDef = curBuffChess.rattleFunc[EnumKeyName.baseDef.rawValue] ?? 1
                                                    curBuffChess.AddBuff(AtkNumber: (curEndAtt as! Int) * curStar, DefNumber: (curEndDef as! Int) * curStar)
                                                }
                                            }
                                        } else if curBuffChess.abilities.contains(EnumAbilities.afterEliminatedAddAbilities.rawValue) {
                                            if case let curAfterKind as [String] = curBuffChess.rattleFunc[EnumKeyName.baseKind.rawValue] {
                                                if curAfterKind.contains(erasedChess.chessKind) {
                                                    if case let curAfterAbility as [String] = curBuffChess.rattleFunc[EnumKeyName.abilityKind.rawValue] {
                                                        curBuffChess.AddTempBuff(tempBuff: curAfterAbility)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if erasedChess.abilities.contains(EnumAbilities.inheritAddBuff.rawValue) { //有传承加buff结算一下
                                        let addNum = erasedChess.inheritFunc[EnumKeyName.summonNum.rawValue] ?? 1
                                        let curRandomArr = randomDiffNumsFromArrs(outputNums: addNum as! Int, inputArr: self.boardChessess[boardIndex])
                                        curRandomArr.forEach{ (attChess) in
                                            //需要给attchess加buff
                                            attChess.AddBuff(AtkNumber: curStar * (erasedChess.inheritFunc[EnumKeyName.baseAttack.rawValue] as! Int), DefNumber: curStar * (erasedChess.inheritFunc[EnumKeyName.baseDef.rawValue] as! Int))
                                        }
                                    }
                                    
                                    
                                    if erasedChess.abilities.contains(EnumAbilities.inheritDamage.rawValue) {
                                        if case let curRattleDamage as Int = erasedChess.inheritFunc[EnumKeyName.baseDamage.rawValue] {
                                            if case let curRattleNum as Int = erasedChess.inheritFunc[EnumKeyName.summonNum.rawValue] {
                                                let damageChess = randomDiffNumsFromArrs(outputNums: curRattleNum, inputArr: self.boardChessess[oppoBoardSide])
                                                abilityTextTrigger(textContent: EnumAbilityType.inherit.rawValue.localized, textPos: erasedChess.position, textType: EnumAbilityType.inherit.rawValue)
    //                                            erasedChess.abilityTrigger(abilityEnum: EnumAbilities.inheritDamage.rawValue.localized)
                                                for vIndex in 0 ..< damageChess.count {
                                                    let curChess = damageChess[vIndex] as! baseChessNode
                                                    inheritPromiseArr.append({() in
                                                        return Promise<Double>(resolver: {(resolver) in
                                                            let damTime = self.dealDamageAction(startVector: erasedChess.position, endVector: curChess.position)
                                                            delay(damTime, task: {
                                                                    isAlive = curChess.getDamage(damageNumber: curRattleDamage * curStar, chessBoard: &self.boardChessess[oppoBoardSide])
                                                                    resolver.fulfill(self.totalUpdateTime)
                                                            })
                                                        })
                                                    })
                                                    
                                                }
                                            }
                                        }
                                    }
                                    if erasedChess.abilities.contains(EnumAbilities.inheritSummonSth.rawValue) {
                                        if case var curHeritChess as [chessStruct] = erasedChess.inheritFunc[EnumKeyName.summonChess.rawValue] {
                                            erasedChess.abilityTrigger(abilityEnum: EnumAbilities.inheritSummonSth.rawValue.localized)
                                            if erasedChess.chessName == EnumChessName.mouse.rawValue && curHeritChess.count > 0 { //老鼠特殊处理
                                                let randomNum = Int.randomIntNumber(lower: 1, upper: 5)
                                                let newSummonArr = Array(repeating: curHeritChess[0], count: randomNum)
                                                curHeritChess = newSummonArr
                                            }
                                            
                                            var newChesses:[baseChessNode] = []
                                            curHeritChess.forEach{ curC in
                                                newChesses.append(baseChessNode(statusNum: EnumsChessStage.enemySide.rawValue, chessInfo: curC))
                                            }
                                            //for index in 0 ..< curHeritChess.count { //appendnewnode里会计算数量 多余的棋子会被砍掉
                                           // inheritPromiseArr.append({() in
                                                //return Promise<Double>(resolver: {(resolver) in
                                                    if innerIndex <= self.boardChessess[boardIndex].count {
                                                        self.appendNewNodeToBoard(curBoardSide: boardIndex, curAddChesses: newChesses, curInsertIndex: innerIndex)
                                                    } else {
                                                        self.appendNewNodeToBoard(curBoardSide: boardIndex, curAddChesses: newChesses, curInsertIndex: innerIndex)
                                                    }
                                               // })
                                            //})
                                            
                                        } else if case let curRattleRarity as Int = erasedChess.inheritFunc[EnumKeyName.baseRarity.rawValue] {
                                            erasedChess.abilityTrigger(abilityEnum: EnumAbilities.inheritAddBuff.rawValue.localized)
                                            if case let curRattleNum as Int = erasedChess.inheritFunc[EnumKeyName.summonNum.rawValue] {
                                                let randomChessStruct = randomDiffNumsFromArrs(outputNums: curRattleNum, inputArr: chessCollectionsLevel[curRattleRarity - 1])
                                                
                                                for index in 0 ..< randomChessStruct.count { //appendnewnode里会计算数量 多余的棋子会被砍掉
                                                    
                                                    if innerIndex <= self.boardChessess[innerIndex].count {
                                                        self.appendNewNodeToBoard(curBoardSide: boardIndex, curAddChesses: [baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: randomChessStruct[index])], curInsertIndex: innerIndex + index)
                                                    } else {
                                                        self.appendNewNodeToBoard(curBoardSide: boardIndex, curAddChesses: [baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: randomChessStruct[index])], curInsertIndex: innerIndex + index)
                                                    }
                                                    
                                                }
                                                
                                            }
                                        }
                                        //self.updateWholeBoardPosition()
                                    }
                                }
                                if oldBoard[boardIndex][innerIndex] !== curDragPoint{
                                    needDeleteChesses.append(oldBoard[boardIndex][innerIndex])
                                }
                            }
                        }
                    }
                    
                    recyclePromise(taskArr: inheritPromiseArr, curIndex: 0).done{ _ in
                        //创建队列组
                        let group = DispatchGroup()
                        //创建并发队列
                        let queue = DispatchQueue.global()
                        for i in 0 ..< needDeleteChesses.count {
                            queue.async(group: group, execute: {
                                needDeleteChesses[i].removeFromParentNode()
                            })
                        }
                        group.notify(queue: queue) {
                            DispatchQueue.main.async {
                                let updateTime = self.updateWholeBoardPosition()
                                if self.updatePromise != nil && isAlive {
                                    delay(updateTime, task: {
                                        self.updatePromise?.fulfill(0) //fufill的时间用不上 hardcode 0
                                        self.updatePromise = nil
                                        
                                    })
                                }
                                
                            }
                        }
                    }
            }
            }
    
    // Size of the level in meters
    var targetSize: CGSize = defaultSize
    
    private(set) var placed = false
    
    private var scene: SCNScene?
    private var boardNodeTemplate: SCNNode?
    private var boardNodeClone: SCNNode?
    private var stroageNodeTemplate: SCNNode?
    private var lock = NSLock()
    
    private(set) var lodScale: Float = 1.0
    
    func load() {
        // have to do this
        lock.lock(); defer { lock.unlock() }
        
        // only load once - can be called from preload on another thread, or regular load
        if scene != nil {
            return
        }
        
        guard let sceneUrl = Bundle.main.url(forResource: boardPath, withExtension: "scn") else {
            fatalError("Level \(boardPath) not found")
        }
        do {
            let scene = try SCNScene(url: sceneUrl, options: nil)
            
            // start with animations and physics paused until the board is placed
            // we don't want any animations or things falling over while ARSceneView
            // is driving SceneKit and the view.
            scene.isPaused = true
            self.scene = scene
            // this may not be the root, but lookup the identifier
            // will clone the tree done from this node
            boardNodeTemplate = scene.rootNode.childNode(withName: "playerBoard", recursively: true)
            
            scene.rootNode.rootID = boardRootName
            // walk down the scenegraph and update the childrens
            scene.rootNode.fixMaterials()
            //
            initSubNodes()
            
            
        } catch {
            fatalError("Could not load level \(sceneUrl): \(error.localizedDescription)")
        }
    }
    


    // Scale factor to assign to the level to make it appear 1 unit wide.
    var normalizedScale: Float {
        guard let levelNode = boardNodeTemplate else { return 1.0 }
        let levelSize = levelNode.horizontalSize.x
        guard levelSize > 0 else {
            fatalError("Level size is 0. This might indicate something is wrong with the assets")
        }
        return 1 / levelSize
    }
    
    
    
    
    
    
    override init() {
        //
        super.init()
    }

    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(name: String) {
        self.init()
        self.boardRootName = name
    }
    
    func reset() {
        placed = false
        boardNodeClone = nil
    }
    
    func abilityTextTrigger(textContent: String, textPos: SCNVector3,textType: String) {
        guard let boardNode = boardNodeTemplate else { return }
        let abilitiesTriggerTextNode = TextNode(textScale: SCNVector3(0.01, 0.01, 0.001))
        abilitiesTriggerTextNode.string = textContent
        abilitiesTriggerTextNode.position = textPos
        abilitiesTriggerTextNode.position.y = 0.1
        //        abilitiesTriggerTextNode.eulerAngles = SCNVector3(-60.degreesToRadius, 0 , 0)
        boardNode.addChildNode(abilitiesTriggerTextNode)
        abilitiesTriggerTextNode.runAction(SCNAction.sequence([
            SCNAction.fadeIn(duration: 0.1),
            SCNAction.wait(duration: 1),
            //            SCNAction.fadeOut(duration: 0.3),
            SCNAction.customAction(duration: 0, action: { _,_ in
                abilitiesTriggerTextNode.removeFromParentNode()
            })
        ]))
    }
    
    func placeBoard(on node: SCNNode, gameScene: SCNScene, boardScale: Float, multiSession: multiUserSession) {
        guard let scene = scene else { return }
        guard let boardNode = boardNodeTemplate else { return }
        // set the environment onto the SCNView
        gameScene.lightingEnvironment.contents = scene.lightingEnvironment.contents
        gameScene.lightingEnvironment.intensity = scene.lightingEnvironment.intensity
        
        // set the cloned nodes representing the active level
        node.addChildNode(boardNode)
        
        placed = true
        
        // the lod system doesn't honor the scaled camera,
        // so have to fix this manually in fixLevelsOfDetail with inverse scale
        // applied to the screenSpaceRadius
        lodScale = normalizedScale * boardScale
        
        //multipeer
        let anchor = ARAnchor(name: "playerBoard", transform: node.simdTransform)
        // Send the anchor info to peers, so they can place the same content.
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            else { fatalError("can't encode anchor") }
        multiSession.sendToAllPeers(data)
        
    }
    /*添加棋子到棋盘*/
       func appendNewNodeToBoard(curBoardSide:Int, curAddChesses: [baseChessNode], curInsertIndex: Int?) {
           for index in 0 ..< curAddChesses.count {
               let curAddChess = curAddChesses[index]
               if curAddChess.chessStatus != EnumsChessStage.owned.rawValue { //第一次购买的棋子才生效 战斗产生的衍生物是enemyside也会生效
                   var hasSummonAbility:[String : Int] = [:]

                   boardChessess[curBoardSide].forEach{ (curChess) in
                       if (curChess.abilities.contains(EnumAbilities.summonChessAddBuff.rawValue)) { //召唤一个棋子以后加buff 无论当前阶段
                           if hasSummonAbility[EnumAbilities.summonChessAddBuff.rawValue] != nil {
                               hasSummonAbility[EnumAbilities.summonChessAddBuff.rawValue]! += curChess.chessLevel
                           } else {
                               hasSummonAbility[EnumAbilities.summonChessAddBuff.rawValue] = curChess.chessLevel
                           }
                       }

                       if (curChess.abilities.contains(EnumAbilities.afterSummonChessAddShell.rawValue)) && curStage == EnumsGameStage.battleStage.rawValue { //召唤一个棋子以后加shell 只有战斗回合触发
                           if curAddChess.chessKind == EnumChessKind.plain.rawValue {
                               curChess.AddTempBuff(tempBuff: [EnumAbilities.shell.rawValue])
                           }
                       }


                       if curBoardSide == BoardSide.allySide.rawValue { //只有在友军才触发
                           if (curChess.abilities.contains(EnumAbilities.summonChessAddMountainBuff.rawValue)) {
                               if hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue] != nil {
                                   hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue]! += curChess.chessLevel
                               } else {
                                   hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue] = curChess.chessLevel
                               }
                           }

                           if (curChess.abilities.contains(EnumAbilities.summonChessAddSelfBuff.rawValue)) {
                               if case let curKindArr as [String] = curChess.rattleFunc[EnumKeyName.baseKind.rawValue] {
                                   if curKindArr.contains(curAddChess.chessKind) {
                                       let curBaseAtt = curChess.rattleFunc[EnumKeyName.baseAttack.rawValue] ?? 1
                                       let curBaseDef = curChess.rattleFunc[EnumKeyName.baseDef.rawValue] ?? 1
                                       curChess.AddBuff(AtkNumber: curBaseAtt as! Int * curChess.chessLevel, DefNumber: curBaseDef as! Int * curChess.chessLevel)
                                   }
                               }
                           }
                       }
                   }


                   if hasSummonAbility[EnumAbilities.summonChessAddBuff.rawValue] != nil && hasSummonAbility[EnumAbilities.summonChessAddBuff.rawValue]! > 0 { //召唤生物 给其加buff  暂时狮子专属 就给平原生物加
                       if curAddChess.chessKind == EnumChessKind.plain.rawValue {
                           if !curAddChess.temporaryBuff.contains(EnumAbilities.summonChessAddBuff.rawValue) {
                               curAddChess.AddTempBuff(tempBuff: [EnumAbilities.summonChessAddBuff.rawValue])
                               curAddChess.AddBuff(AtkNumber: hasSummonAbility[EnumAbilities.summonChessAddBuff.rawValue]! * 3, DefNumber: 0)
                           }
                       }
                   }

                   if curBoardSide == BoardSide.allySide.rawValue && curStage == EnumsGameStage.exchangeStage.rawValue {
                       curAddChess.chessStatus = EnumsChessStage.owned.rawValue //确保友方必定被拥有

                       if hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue] != nil && hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue]! > 0 {
                           boardChessess[BoardSide.allySide.rawValue].forEach{(curChess) in
                               if (curChess.chessKind == EnumChessKind.mountain.rawValue) {
                                   curChess.AddBuff(AtkNumber: hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue], DefNumber: hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue])
                               }

                           }
                       }

                       if curAddChess.abilities.contains(EnumAbilities.afterSummonAdjecentAddBuff.rawValue) {
                           if curAddChess.chessName == EnumChessName.baboon.rawValue { //狒狒专属
                               if let curIndex = curInsertIndex {
                                   let leftIndex = curIndex - 1
                                   let rightIndex = curIndex
                                   if leftIndex >= 0 && leftIndex < boardChessess[curBoardSide].count {
                                       boardChessess[curBoardSide][leftIndex].AddBuff(AtkNumber: curAddChess.chessLevel * 2, DefNumber: curAddChess.chessLevel * 2)
                                   }
                                   if rightIndex >= 0 && rightIndex < boardChessess[curBoardSide].count {
                                       boardChessess[curBoardSide][rightIndex].AddBilities(Abilities: [EnumAbilities.bait.rawValue])
                                   }
                               } else { //append
                                   boardChessess[curBoardSide].last?.AddBuff(AtkNumber: curAddChess.chessLevel * 2, DefNumber: curAddChess.chessLevel * 2)
                               }
                           }
                       }
                   }

               }

           }
           
          
           
           if let curIndex = curInsertIndex {
               if(boardChessess[curBoardSide].count < GlobalCommonNumber.chessNumber) {
                   boardChessess[curBoardSide].insert(contentsOf: curAddChesses, at: curIndex)
               }
           } else {
               if(boardChessess[curBoardSide].count < GlobalCommonNumber.chessNumber) {
                   boardChessess[curBoardSide].append(contentsOf: curAddChesses)
               }
           }
      
           
       }
    
    func updateWholeBoardPosition() -> Double { //update all chesses' position
           let totalTime = 0.50
         
           // chess positions adjust actions
           for index in 0 ..< boardChessess.count {
               let curBoardSide = boardChessess[index]
               let startIndex = (GlobalNumberSettings.chessNumber.rawValue - curBoardSide.count) / 2
               for innerIndex in 0 ..< curBoardSide.count {
                   let curRootNode = boardRootNode[index][innerIndex + startIndex]
                   let curChessNode = boardChessess[index][innerIndex]
                   let updateAction = SCNAction.move(to: SCNVector3(curRootNode.position.x, curRootNode.position.y + 0.01 , curRootNode.position.z), duration: totalTime)
                   curChessNode.runAction(updateAction)
               }
           }
           
          return totalTime
       }
    
    func initSubNodes() {
        guard let boardNode = boardNodeTemplate else { return}
           if let storageNodeTemp = boardNode.childNode(withName: "storageNode", recursively: true) {
               stroageNodeTemplate = storageNodeTemp
           }
       }
    
    func initBoardRootNode() { //初始化底座node。是必须的 游戏开始必须调用
        guard let boardNode = boardNodeTemplate else { return}
//        if let allyBoardTemp = boardNode.childNode(withName: "allyBoard", recursively: true) {
//            allyBoardNode = allyBoardTemp
//        }
        
        for index in 1 ... GlobalNumberSettings.chessNumber.rawValue {
            if let curNode = boardNode.childNode(withName: "e" + String(index), recursively: true) {
                //
                let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: curNode, options: [SCNPhysicsShape.Option.scale: SCNVector3(0.01, 0.01, 0.01)]))
                curNode.physicsBody = body
                curNode.physicsBody?.categoryBitMask = BitMaskCategoty.baseChessHolder.rawValue
                curNode.physicsBody?.contactTestBitMask = BitMaskCategoty.hand.rawValue
                //
                boardRootNode[0].append(curNode)
            }
        }
        
        for index in 1 ... GlobalNumberSettings.chessNumber.rawValue {
            if let curNode = boardNode.childNode(withName: "a" + String(index), recursively: true) {
                //
                let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: curNode, options: [SCNPhysicsShape.Option.scale: SCNVector3(0.01, 0.01, 0.01)]))
                curNode.physicsBody = body
                curNode.physicsBody?.categoryBitMask = BitMaskCategoty.baseChessHolder.rawValue
                curNode.physicsBody?.contactTestBitMask = BitMaskCategoty.hand.rawValue
                //
                boardRootNode[1].append(curNode)
            }
        }
        for index in 1 ..< GlobalCommonNumber.storageNumber {
            if let curNode = boardNode.childNode(withName: "s" + String(index), recursively: true) {
                storageRootNode.append(curNode)
            }
        }
    }
    //dealDamage practicle system
    
    public func dealDamageAction(startVector: SCNVector3, endVector: SCNVector3) -> Double{
        guard let boardNode = boardNodeTemplate else { return 0.00}
        let newTrackPoint = SCNNode(geometry: SCNSphere(radius: 0.003))
        newTrackPoint.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        if let explosion = SCNParticleSystem(named: "particals.scnassets/attackCol.scnp", inDirectory: nil) {
            //explosion.emissionDuration = CGFloat(1)
            explosion.emitterShape = SCNSphere(radius: 0.003)
            
            newTrackPoint.addParticleSystem(explosion)
           
        }
        newTrackPoint.position = startVector
        newTrackPoint.position.y = 0.1
        boardNode.addChildNode(newTrackPoint)
        let trackActionSequence = [
            SCNAction.move(to: endVector, duration: 1),
            SCNAction.customAction(duration: 0, action: { _,_ in
                newTrackPoint.removeFromParentNode()
            })
        ]
        newTrackPoint.runAction(SCNAction.sequence(trackActionSequence))
        return 1
    }
    
}
