//
//  ViewController.swift
//  AChess
//
//  Created by zhaoheng sun on 1/23/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import PromiseKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
   
    
    var setting = (controlMethod : 0, particalOn : 0)//0:  0 用tap的方式操作。1用手识别操作  这个数据应该存在数据库或缓存里作为全局变量
    
    //以下数据为实时记录数据 无需保存
    var rootNodeDefalutColor = [UIColor.red, UIColor.green]
    var isPlayerBoardinited = false
    var playerBoardNode = createPlayerBoard()
    var randomButtonTopNode: SCNNode = SCNNode()
    var upgradeButtonTopNode: SCNNode = SCNNode()
    var endButtonTopNode: SCNNode = SCNNode()
    var randomButtonNode: SCNNode = SCNNode()
    var upgradeButtonNode: SCNNode = SCNNode()
    var endButtonNode: SCNNode = SCNNode()
    var allyBoardNode : SCNNode = SCNNode()
    let totalUpdateTime:Double = 1 //刷新时间
    
    
    var handPoint = SCNNode() // use for mode1 with hand
    var referencePoint = SCNNode() // use for mode0 with touching on screen
    
    var curDragPoint: baseChessNode? = nil
    var curChoosePoint: baseChessNode? = nil
    var curDragPos:[Int] = [] //0:棋盘 1:index
    var curFocusPoint: SCNNode? = nil
    
    //以下数据需要保存
    var boardPool : [String : Int] = ["" : 0] //卡池
    var boardNode :[[baseChessNode]] = [[],[]] //chesses
        {
            didSet(oldBoard) {
  
                if (curStage == EnumsGameStage.exchangeStage.rawValue) {
                    var chessTimesDic:[[String : [Int]]] = [[:],[:],[:]] //棋子map 刷新问题
                    var newCombineChess: [baseChessNode] = []
                    var oldSubChessIndex: [Int] = []
                    for index in 0 ..< boardNode.count {
                        for innerIndex in 0 ..< boardNode[index].count {
                            
                            let curChessNode = boardNode[index][innerIndex]
                            
                            if (index == BoardSide.allySide.rawValue && curChessNode.chessLevel < 3) { //只有己方 echange stage才触发
                                if chessTimesDic[curChessNode.chessLevel][curChessNode.chessName] != nil {
                                    chessTimesDic[curChessNode.chessLevel][curChessNode.chessName]!.append(innerIndex)
                                    if chessTimesDic[curChessNode.chessLevel][curChessNode.chessName]!.count >= 3 { //合成
                                        var subChessNodes:[baseChessNode] = []
                                        chessTimesDic[curChessNode.chessLevel][curChessNode.chessName]?.forEach{(subIndex) in
                                            subChessNodes.append(boardNode[index][subIndex])
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
                        }
                    }
                    if oldSubChessIndex.count > 0 {//说明有棋子合成
                        //移除旧的棋子。todo!!!!! 写的方法可以优化
                        var tempIndex = -1
                        var newAllyBoard:[baseChessNode] = [] //新期盼
                        newAllyBoard = boardNode[BoardSide.allySide.rawValue].filter{(item) in
                            tempIndex += 1
                            return !oldSubChessIndex.contains(tempIndex)
                        }
                        
                        //置入合成棋子
                        newCombineChess.forEach{(newNode) in
                            if newAllyBoard.count < GlobalCommonNumber.chessNumber {
                                playerBoardNode.addChildNode(newNode)
                                newAllyBoard.append(newNode)//直接置入本方场内 后期可以修改为置入等待区域
                            }
                        }
                        //赋值更新
                        boardNode[BoardSide.allySide.rawValue] = newAllyBoard
                        if (curDragPoint != nil) {
                            curDragPoint!.removeFromParentNode()
                        }
                    }
  
                }
                for boardIndex in 0 ..< boardNode.count {
                    for innerIndex in 0 ..< boardNode[boardIndex].count {
                        if !oldBoard[boardIndex].contains(boardNode[boardIndex][innerIndex]) {
                            boardNode[boardIndex][innerIndex].position.y = 0.01
                            playerBoardNode.addChildNode(boardNode[boardIndex][innerIndex])
                        }
                    }
                }
                for boardIndex in 0 ..< oldBoard.count {
                    for innerIndex in 0 ..< oldBoard[boardIndex].count {
                        if !boardNode[boardIndex].contains(oldBoard[boardIndex][innerIndex]) {
                            oldBoard[boardIndex][innerIndex].removeFromParentNode()
                        }
                    }
                }
                DispatchQueue.main.async{
                    self.updateWholeBoardPosition() //dont delete
                }                   
            }
        }
    var boardRootNode :[[SCNNode]] = [[],[]] //chess holder
    var storageNode : [baseChessNode] = [] {
        didSet(oldBoard) {
            
                for innerIndex in 0 ..< oldBoard.count {
                    if !oldBoard[innerIndex].contains(storageNode[innerIndex]) {
                        storageNode[innerIndex].position.y = 0.01
                        playerBoardNode.addChildNode(storageNode[innerIndex])
                    }
                }
                updateStorageBoardPosition()  //dont delete
        }
    }
    var storageRootNode : [SCNNode] = []
   
    //var backupBoardNode:[[baseChessNode]] = [[],[]]
    var playerStatues: [(curCoin: Int,curLevel: Int,curBlood: Int,curChesses: [baseChessNode])] = [(curCoin: GlobalNumberSettings.roundBaseCoin.rawValue + 50, curLevel: 1, curBlood: 40, curChesses: []), (curCoin: GlobalNumberSettings.roundBaseCoin.rawValue, curLevel: 1, curBlood: 40, curChesses: [])] {
        didSet {
            moneyTextNode.string = String(playerStatues[curPlayerId].curCoin)
            levelTextNode.string = String(playerStatues[curPlayerId].curLevel)
            enemyBloodTextNode.string = String(playerStatues[curEnemyId].curBlood)
            playerBloodTextNode.string = String(playerStatues[curPlayerId].curBlood)
        }
    } //当前玩家状态数据 单人模式默认取id = 1
    var curPlayerId = 0
    var curEnemyId = 1
    var curRound = 0
    var curStage = EnumsGameStage.exchangeStage.rawValue
    //below are text nodes
     var moneyTextNode = TextNode(textScale: SCNVector3(0.1, 0.3, 1))
     var levelTextNode = TextNode(textScale: SCNVector3(0.1, 0.3, 1))
     var enemyBloodTextNode = TextNode(textScale: SCNVector3(0.1, 0.3, 1))
     var playerBloodTextNode = TextNode(textScale: SCNVector3(0.1, 0.3, 1))
    //gesutre reoginzer
    var longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action:  #selector(onLongPress))
    var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        initHandNode()
        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        //sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        //tap gesture added
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action:  #selector(onLongPress))
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tapGestureRecognizer.cancelsTouchesInView = false
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        if setting.controlMethod == 0 {
            initReferenceNode()
            //control with long press
            longPressGestureRecognizer.cancelsTouchesInView = false
            self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
            
            // MARK: pan gesture is unnecessary. it is included in longpress recognizer
//            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan))
//            panGestureRecognizer.maximumNumberOfTouches = 1
//            self.sceneView.addGestureRecognizer(panGestureRecognizer)
        }
        //only for test
        self.sceneView.debugOptions = [] //ARSCNDebugOptions.showPhysicsShapes
        // We want to receive the frames from the video
        sceneView.session.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        // Run the view's session
        sceneView.session.run(configuration)
        //set contact delegate
        
        //set up card pool
        
        for level in 0 ..< chessCollectionsLevel.count {
            let specialFacotr = (GlobalNumberSettings.maxLevel.rawValue - level + 2) * 3
            for index in 0 ..< chessCollectionsLevel[level].count {
                let curChess = chessCollectionsLevel[level][index]
                boardPool[curChess.name!] = specialFacotr
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
//    @objc func onPan(sender: UITapGestureRecognizer) {
//        guard let sceneView = sender.view as? ARSCNView else {return}
//        let touchLocation = sender.location(in: sceneView)
//        print("panLocation", touchLocation)
//    }
    @objc func onLongPress(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        if sender.state == .began
        {
            //longPress starts
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, options: [SCNHitTestOption.boundingBoxOnly: true, SCNHitTestOption.ignoreHiddenNodes: true])
            if !hitTestResult.isEmpty {
                let firstResult = hitTestResult.first!
                if let rootNode = findChessRootNode(firstResult.node) {
                    
                    curDragPoint = rootNode
                    
                    
                    rootNode.removeFromParentNode() //it is actually a chessNode not a root node
                    
                    if let rootNodePos = findChessPos(rootNode) {
                        curDragPos = [rootNodePos[0]] //当前只存棋盘不存index
                        if rootNodePos[0] < 2 {
                            boardNode[rootNodePos[0]].remove(at: rootNodePos[1])
                        } else {
                            storageNode.remove(at: rootNodePos[1])
                        }
                    }
                    
                    self.sceneView.scene.rootNode.addChildNode(curDragPoint!)
                    //updateWholeBoardPosition()
                    //curDragPoint?.geometry?.firstMaterial?.diffuse = UIColor.red
                }
                
                //                                   let positionOfPress = hitTestResult.first!.worldTransform.columns.3
                //                                   let curPressLocation = SCNVector3(positionOfPress.x, positionOfPress.y, positionOfPress.z)
                //                                   self.checkCollisionWithChess(curPressLocation)
            }
        }
        else if sender.state == .changed
        {
            if curDragPoint != nil {
                let touchLocation = sender.location(in: sceneView)
                let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
                if !hitTestResult.isEmpty {
                    let positionOfPress = hitTestResult.first!.worldTransform.columns.3
                    let curPressLocation = SCNVector3(positionOfPress.x, positionOfPress.y, positionOfPress.z)
                    curDragPoint?.position = SCNVector3(curPressLocation.x, curPressLocation.y + 0.05, curPressLocation.z)
                    referencePoint.position = SCNVector3(curPressLocation.x, curPressLocation.y + 0.01, curPressLocation.z)
                    referencePoint.isHidden = false
                    
                }
                let hitTestResult2 = sceneView.hitTest(touchLocation, options: [SCNHitTestOption.ignoreHiddenNodes: true, SCNHitTestOption.rootNode: playerBoardNode])
                if !hitTestResult2.isEmpty {
                    let curPressNode = hitTestResult2.first!.node
                    if curPressNode.name == EnumNodeName.saleStage.rawValue {
                        curPressNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    } else if curPressNode.name == EnumNodeName.storagePlace.rawValue {
                        curPressNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    } else if curPressNode.name == EnumNodeName.allyBoard.rawValue {
                        curPressNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                    } else if curPressNode.name == EnumNodeName.enemyBoard.rawValue {
                        curPressNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                    } else {
                       recoverBoardColor()
                    }
                }
            }
        } else if sender.state == .ended
        {
            recoverBoardColor() //放置动作结束 恢复board颜色
            //
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, options: [SCNHitTestOption.ignoreHiddenNodes: true, SCNHitTestOption.rootNode: playerBoardNode]) //用于检测触摸的node
            let hitTestResult2 = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent]) //用于检测触摸点的pos
            if !hitTestResult.isEmpty && curDragPoint != nil {
                let curPressNode = hitTestResult.first!.node
                //if curDragPoint?.name?.first == "a" { //抓的是已经购买的牌
                
                if let curPressParent = findChessRootNode(curPressNode) { //按到棋子上了
                    insertChessPos(insertChess: curDragPoint!, insertTo: curPressParent)
                } else { //按到空地或者棋盘上了
                    if let curRootNodePos = findRootPos(curPressNode) { //只有购买状态时候才能操作 所以无需判断当前阶段
                        var curSideIndex = curRootNodePos[0] //阵营编号
                        var curIndex = curRootNodePos[1] //落点编号
                        let curSide = boardNode[curSideIndex]
                        if curSideIndex == BoardSide.allySide.rawValue { //落点在本方 才会触发购买
                            if curDragPoint!.chessStatus == EnumsChessStage.forSale.rawValue { //not yet owned, first deducts the money
                                if buyChess(playerID: curPlayerId, chessPrice: curDragPoint!.chessPrice) == true { //buy success
                                    curDragPoint?.chessStatus = EnumsChessStage.owned.rawValue
                                   
                                        if curIndex < (GlobalNumberSettings.chessNumber.rawValue - curSide.count) / 2 {
                                            summonToAllyBoard(newNode: curDragPoint!, curBoardIndex: 0)
                                        } else {
                                            summonToAllyBoard(newNode: curDragPoint!, curBoardIndex: nil)
                                        }
               
                                } else { //购买失败 放回去
                                    if curDragPos[0] < 2 {
                                        appendNewNodeToBoard(curBoardSide: curDragPos[0], curChess: curDragPoint!)
                                    } else {
                                        if curDragPoint != nil { //storage暂时较少用到 不封装放置方法
                                            appendNewNodeToStorage(curChess: curDragPoint!)
                                        }
                                    }
                                }
                            }
                        }
                        if curDragPoint!.chessStatus == EnumsChessStage.owned.rawValue { //如果已经买过了，就移动回到ally side
                            curSideIndex = BoardSide.allySide.rawValue
                        }
                                               
                    } else if curPressNode.name == EnumNodeName.saleStage.rawValue && curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue{//放置到贩卖点
                        sellChess(playerID: curPlayerId, curChess: curDragPoint!, curBoardSide: curDragPos[0])
                    } else if curPressNode.name == EnumNodeName.storagePlace.rawValue { //放置到储藏区
                        if curDragPoint?.chessStatus == EnumsChessStage.forSale.rawValue { //未购买
                            if buyChess(playerID: curPlayerId, chessPrice: curDragPoint!.chessPrice) == true { //buy success
                                appendNewNodeToStorage(curChess: curDragPoint!)
                            } else { //钱不够 购买时买
                                if curDragPoint != nil {
                                    appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curChess: curDragPoint!)
                                }
                            }
                        } else if curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue { //已购买
                                if curDragPoint != nil {
                                    appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: curDragPoint!)
                                }
                        }
                    } else if curPressNode.name == EnumNodeName.allyBoard.rawValue { //结束点在allyboard
                        if !hitTestResult2.isEmpty {
                            if boardNode[BoardSide.allySide.rawValue].count < GlobalCommonNumber.chessNumber { //小于棋子上限数量
                                let positionOfPress = hitTestResult2.first!.worldTransform.columns.3
                                let curPressLocation = SCNVector3(positionOfPress.x, positionOfPress.y, positionOfPress.z)
                                if curDragPoint?.chessStatus == EnumsChessStage.forSale.rawValue { //未使用 forSale包含storage的状态
                                    if curDragPos[0] != 2 { //dragpoint不是储藏区拿出来的 所以需要购买一下
                                        if buyChess(playerID: curPlayerId, chessPrice: curDragPoint!.chessPrice) == true { //buy success
                                            //continue
                                        } else { //钱不够 购买时买
                                            appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curChess: curDragPoint!)
                                            return
                                            
                                        }
                                    }
                                    //储藏区来的不需要购买
                                    /*//具有特殊战吼需要选择指定s的棋子
                                     curDragPoint!.abilities.contains(EnumAbilities.instantChooseAnAbility.rawValue) ||
                                     curDragPoint!.abilities.contains(EnumAbilities.instantChooseAnAbilityForMountain.rawValue) ||
                                     curDragPoint!.abilities.contains(EnumAbilities.instantDestroyAllyGainBuff.rawValue)) &&
                                     */
                                    if curDragPoint!.abilities.contains(EnumAbilities.instantAddBuff.rawValue) &&
                                        boardNode[BoardSide.allySide.rawValue].count > 0
                                    { // if chess has INSTANT add buff TODO!!!!
                                        removeGestureRecoginzer()
                                        PlayerBoardTextShow(TextContent: EnumString.chooseAnChess.rawValue.localized)
                                        curDragPoint?.isHidden = true //隐藏当前的拖拽棋子 方便选择
                                        //
                                        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onChooseChessTap))
                                        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
                                        
                                        //根据种族判断需要激活变绿效果的棋子
                                      
                                            if case let curInstantKindArr as [String] = curDragPoint?.rattleFunc[EnumKeyName.baseKind.rawValue] {

                                                    boardNode[BoardSide.allySide.rawValue].forEach{(curChess)in
                                                        if curInstantKindArr.contains(curChess.chessKind) {
                                                            curChess.setActive()
                                                        }
                                                    }
                    
                                            } else {
                                                boardNode[BoardSide.allySide.rawValue].forEach{(curChess)in
                                                    curChess.setActive()
                                                }
                                            }
                                        
                                        
                                        
                                        
                                        
                                    } else if curDragPoint!.abilities.contains(EnumAbilities.instantAllGainAbilityForMountain.rawValue) &&
                                        boardNode[BoardSide.allySide.rawValue].count > 0
                                    {
                                        removeGestureRecoginzer()
                                        PlayerBoardTextShow(TextContent: EnumString.chooseAnOption.rawValue.localized)
                                        curDragPoint?.isHidden = true //隐藏当前的拖拽棋子 方便选择
                                        //备份当前棋子
                                        self.playerStatues[self.curPlayerId].curChesses = []
                                        self.boardNode[BoardSide.allySide.rawValue].forEach{(curChess) in
                                            self.playerStatues[self.curPlayerId].curChesses.append(curChess)
                                            curChess.removeFromParentNode()
                                        }
                                        //为我方放置3种类型能力的棋子
                                        let randomAbiArr = randomDiffNumsFromArrs(outputNums: 3, inputArr: EvolveAbilities)
                                        self.boardNode[BoardSide.allySide.rawValue] = []
                                        randomAbiArr.forEach{ (curAbi) in
                                            let newChess = baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: chessStruct(name: curAbi, desc: curAbi, atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1, chessKind: EnumChessKind.mountain.rawValue, abilities: [curAbi], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]))
                                            appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: newChess)
                                            
                                        }
                                        //updateWholeBoardPosition()
                                        //
                                        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onChooseOptionTap))
                                        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
                                        
                                        
                                    } else {//没有特殊的战吼之类的触发 直接放置入 allyboard
                                        if curDragPoint!.abilities.contains(EnumAbilities.instantSummonSth.rawValue) { //战吼召唤
                                            
                                            
                                            if case let curRattleChess as chessStruct = curDragPoint?.rattleFunc[EnumKeyName.summonChess.rawValue] {
                                                if case let curRattleNum as Int = curDragPoint?.rattleFunc[EnumKeyName.summonNum.rawValue] {
                                                    for index in 0 ..< curRattleNum { //appendnewnode里会计算数量 多余的棋子会被砍掉
                                                        appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: curRattleChess))
                                                    }
                                                }
                                            }
                                            
                                            //updateWholeBoardPosition()
                                        } else if curDragPoint!.abilities.contains(EnumAbilities.instantRandomAddBuff.rawValue) { //战吼添加随机buff
                                            
                                            
                                            if case let curRattleAtt as Int = curDragPoint?.rattleFunc[EnumKeyName.baseAttack.rawValue] {
                                                if case let curRattleDef as Int = curDragPoint?.rattleFunc[EnumKeyName.baseDef.rawValue] {
                                                    if case let curRattleNum as Int = curDragPoint?.rattleFunc[EnumKeyName.summonNum.rawValue] {
                                                        if case let curRattleKind as String = curDragPoint?.rattleFunc[EnumKeyName.baseKind.rawValue] {
                                                            var newKindsArr:[baseChessNode] = []
                                                            self.boardNode[BoardSide.allySide.rawValue].forEach{(curKindChess) in
                                                                if curKindChess.chessKind == curRattleKind {
                                                                    newKindsArr.append(curKindChess)
                                                                }
                                                            }
                                                            
                                                            let randomChesses = randomDiffNumsFromArrs(outputNums: curRattleNum, inputArr: newKindsArr)
                                                            randomChesses.forEach{(curRandomChess) in
                                                                curRandomChess.AddBuff(AtkNumber: curRattleAtt * curDragPoint!.chessLevel, DefNumber: curRattleDef * curDragPoint!.chessLevel)
                                                            }
                                                            
                                                            
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            
                                        }
                                        
                                        //将curdragpoint放进去
                                        let curInsertIndex = calInsertPos(curBoardSide: BoardSide.allySide.rawValue, positionOfBoard: curPressLocation)
                                        
                                        if curInsertIndex == -1 || curInsertIndex - (GlobalCommonNumber.chessNumber / 2) >= boardNode[BoardSide.allySide.rawValue].count {
                                            summonToAllyBoard(newNode: curDragPoint!, curBoardIndex: nil)
                                        } else {
                                            summonToAllyBoard(newNode: curDragPoint!, curBoardIndex: 0)
                                        }
                                        
                                        
                                        //updateWholeBoardPosition()
                                    }
                                        
                                    
                                } else if curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue { //已购买&&使用
                                        if curDragPoint != nil {
                                            let curInsertIndex = calInsertPos(curBoardSide: BoardSide.allySide.rawValue, positionOfBoard: curPressLocation)
                                            if curInsertIndex == -1 || curInsertIndex - (GlobalCommonNumber.chessNumber / 2) >= boardNode[BoardSide.allySide.rawValue].count {
                                               appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: curDragPoint!)
                                            } else {
                                                insertNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curBoardIndex: 0, curChess: curDragPoint!)
                                            }
                                        }
                                        //updateWholeBoardPosition()
                                }
                            } else {
                               recoverNodeToBoard(dragPos: curDragPos)
                            }
                        } else { // hit test is empty
                            recoverNodeToBoard(dragPos: curDragPos)
                        }
                    } else if curPressNode.name == EnumNodeName.enemyBoard.rawValue { //end point at enemy board
                        if curDragPoint?.chessStatus == EnumsChessStage.forSale.rawValue { //未购买
                            if curDragPoint != nil {
                                if !hitTestResult2.isEmpty {
                                let positionOfPress = hitTestResult2.first!.worldTransform.columns.3
                                let curPressLocation = SCNVector3(positionOfPress.x, positionOfPress.y, positionOfPress.z)
                                    let curInsertIndex = calInsertPos(curBoardSide: BoardSide.enemySide.rawValue, positionOfBoard: curPressLocation)
                                    if curInsertIndex == -1 || curInsertIndex - (GlobalCommonNumber.chessNumber / 2) >= boardNode[BoardSide.enemySide.rawValue].count {
                                       appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curChess: curDragPoint!)
                                    } else {
                                        insertNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curBoardIndex: 0, curChess: curDragPoint!)
                                    }
                                    }
                            }
                            //updateWholeBoardPosition()
                        } else if curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue { //已购买放回原位
                           if curDragPos[0] < 2 {
                                appendNewNodeToBoard(curBoardSide: curDragPos[0], curChess: curDragPoint!)
                            } else {
                                if curDragPoint != nil { //storage暂时较少用到 不封装放置方法
                                    appendNewNodeToStorage(curChess: curDragPoint!)
                                }
                            }
                            //updateWholeBoardPosition()
                            
                        }
                        
                    } else { //无需判断长度 因为之前的地方肯定有位置给它
                        var pointBoardIndex = 0
                        if curDragPos[0] < 2 {
                            appendNewNodeToBoard(curBoardSide: curDragPos[0], curChess: curDragPoint!)
                        } else {
                            if curDragPoint != nil { //storage暂时较少用到 不封装放置方法
                                appendNewNodeToStorage(curChess: curDragPoint!)
                            }
                        }
                    }
                    
                }
             
                
            }
            //
            if let saleStage = playerBoardNode.childNode(withName: EnumNodeName.saleStage.rawValue, recursively: true) {
                saleStage.geometry?.firstMaterial?.diffuse.contents = UIColor.black
            }
            referencePoint.isHidden = true
           
            //curDragPoint = nil
        }
    }
    @objc func onChooseOptionTap(sender: UITapGestureRecognizer) { //用于战吼等选择option的操作的tap
        guard let sceneView = sender.view as? ARSCNView else {return}
                    let touchLocation = sender.location(in: sceneView)
                    let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
                    if !hitTestResult.isEmpty && curDragPoint != nil {
                      
                            //self.addChessTest(hitTestResult: hitTestResult.first!)
                            guard let sceneView = sender.view as? ARSCNView else {return}
                            let touchLocation = sender.location(in: sceneView)
                            let hitTestResult = sceneView.hitTest(touchLocation, options: [SCNHitTestOption.boundingBoxOnly: true, SCNHitTestOption.ignoreHiddenNodes: true])
                        if !hitTestResult.isEmpty {
                            let curNode = hitTestResult.first?.node
                            if let curBaseChess = findChessRootNode(curNode!) {
                                
                                if curDragPoint!.abilities.contains(EnumAbilities.instantAllGainAbilityForMountain.rawValue) {
                                    self.playerStatues[self.curPlayerId].curChesses.forEach{(curChess) in
                                        curChess.AddBilities(Abilities: curBaseChess.abilities)
                                    }
                                } else if curDragPoint!.abilities.contains(EnumAbilities.instantChooseAnAbility.rawValue) {
                                    if curChoosePoint != nil {
                                        curChoosePoint?.AddBilities(Abilities: curBaseChess.abilities)
                                    }
                                }
                                //使用完毕修改棋子状态
                                summonToAllyBoard(newNode: curDragPoint!, curBoardIndex: nil)
                                
                            } else { //点击点不在
                                sellChess(playerID: curPlayerId, curChess: curDragPoint!, curBoardSide: curDragPos[0])
                                if curDragPos[0] == 0 { //新买的棋子
                                    appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curChess: curDragPoint!)
                                } else if curDragPos[0] == 2 { //储藏区的棋子
                                    appendNewNodeToStorage(curChess: curDragPoint!)
                                }
                                
                                
                            }
                            
                            emptyBoardSide(curBoardSide: BoardSide.allySide.rawValue) //清空棋盘
                            self.playerStatues[self.curPlayerId].curChesses.forEach{(curChess) in
                                appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: curChess)
                            }
                            //appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: curDragPoint!) //恢复拖拽的棋子到棋盘
                            //updateWholeBoardPosition()
                            ///以下为恢复操作
                            recoverGestureRecoginzer()
                            curDragPoint?.isHidden = false
                            
                            boardNode[BoardSide.allySide.rawValue].forEach{(curSubChess) in
                                curSubChess.cancelActive()
                            }
                            curDragPoint = nil
                            PlayerBoardTextOff()
                        }
                                    
                    }
        return
    }
    @objc func onChooseChessTap(sender: UITapGestureRecognizer) { //用于战吼等选择棋子的操作的tap
        guard let sceneView = sender.view as? ARSCNView else {return}
                    let touchLocation = sender.location(in: sceneView)
                    let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
                    if !hitTestResult.isEmpty && curDragPoint != nil {
                      
                            //self.addChessTest(hitTestResult: hitTestResult.first!)
                            guard let sceneView = sender.view as? ARSCNView else {return}
                            let touchLocation = sender.location(in: sceneView)
                            let hitTestResult = sceneView.hitTest(touchLocation, options: [SCNHitTestOption.boundingBoxOnly: true, SCNHitTestOption.ignoreHiddenNodes: true])
                        if !hitTestResult.isEmpty {
                            let curNode = hitTestResult.first?.node
                            if let curBaseChess = findChessRootNode(curNode!) {
                                
                                if curDragPoint!.abilities.contains(EnumAbilities.instantAddBuff.rawValue) {
                                    if case let curBaseAtt as Int = curDragPoint?.rattleFunc[EnumKeyName.baseAttack.rawValue] {
                                        if case let curBaseDef as Int = curDragPoint?.rattleFunc[EnumKeyName.baseDef.rawValue] {
                                            curBaseChess.AddBuff(AtkNumber: curDragPoint!.chessLevel * curBaseAtt , DefNumber: curDragPoint!.chessLevel * curBaseDef)
                                        }
                                    }
                                    
                                } else if curDragPoint!.abilities.contains(EnumAbilities.instantDestroyAllyGainBuff.rawValue) {
                                    removeNodeFromBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: curBaseChess)
                                }
                                else if curDragPoint!.abilities.contains(EnumAbilities.instantChooseAnAbility.rawValue) ||
                                    curDragPoint!.abilities.contains(EnumAbilities.instantChooseAnAbilityForMountain.rawValue)
                                {
                                    if curDragPoint!.abilities.contains(EnumAbilities.instantChooseAnAbilityForMountain.rawValue) &&
                                        curBaseChess.chessKind != EnumChessKind.mountain.rawValue
                                    { //不是特定种族的不做处理
                                        return
                                    }
                                    curChoosePoint = curBaseChess // 保存当前选择的需要进化的棋子
                                    self.playerStatues[self.curPlayerId].curChesses = [] //备份当前棋子
                                    self.boardNode[BoardSide.allySide.rawValue].forEach{(curChess) in
                                        self.playerStatues[self.curPlayerId].curChesses.append(curChess)
                                        curChess.removeFromParentNode()
                                    }
                                    let randomAbiArr = randomDiffNumsFromArrs(outputNums: 3, inputArr: EvolveAbilities)
                                    self.boardNode[BoardSide.allySide.rawValue] = [] //为我方放置3种类型能力的棋子
                                    randomAbiArr.forEach{ (curAbi) in
                                        let newChess = baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: chessStruct(name: curAbi, desc: curAbi, atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1, chessKind: EnumChessKind.mountain.rawValue, abilities: [curAbi], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]))
                                        appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: newChess)
                                        
                                    }
                                    //updateWholeBoardPosition()
                                    //修改点击事件为choose option事件
                                    removeGestureRecoginzer()
                                    tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onChooseOptionTap))
                                    self.sceneView.addGestureRecognizer(tapGestureRecognizer)
                                    //启用新的点击事件 选择还未结束 直接return
                                    return
                                }
                                //使用完毕修改棋子状态
                                summonToAllyBoard(newNode: curDragPoint!, curBoardIndex: nil)
                                //
                                let appendIndex = boardNode[BoardSide.allySide.rawValue].count - 1
                                //let updateTime = updateWholeBoardPosition()
                                if curDragPoint!.abilities.contains(EnumAbilities.instantDestroyAllyGainBuff.rawValue) {
                                    delay(totalUpdateTime){
                                        if self.boardNode[BoardSide.allySide.rawValue][appendIndex] != nil {
                                            self.boardNode[BoardSide.allySide.rawValue][appendIndex].AddBuff(AtkNumber: curBaseChess.atkNum, DefNumber: curBaseChess.defNum)
                                        }
                                    }
                                }
                            } else { //点击点不在
                                sellChess(playerID: curPlayerId, curChess: curDragPoint!, curBoardSide: curDragPos[0]) //dragpoint现在是找不到的
                                if curDragPos[0] == 0 { //新买的棋子
                                    appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curChess: curDragPoint!)
                                    updateWholeBoardPosition()
                                } else if curDragPos[0] == 2 { //储藏区的棋子
                                    appendNewNodeToStorage(curChess: curDragPoint!)
                                }
                                
                            }
                            ///以下为恢复操作
                            
                            recoverGestureRecoginzer()
                            curDragPoint?.isHidden = false
                            boardNode[BoardSide.allySide.rawValue].forEach{(curSubChess) in
                                curSubChess.cancelActive()
                            }
                            curDragPoint = nil
                            PlayerBoardTextOff()
                        }
                                    
                    }
        return
    }
    @objc func onTap(sender: UITapGestureRecognizer) {
            guard let sceneView = sender.view as? ARSCNView else {return}
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
            if !hitTestResult.isEmpty {
                if isPlayerBoardinited == false {
                   //self.addChessTest(hitTestResult: hitTestResult.first!)
                    self.initPlayerBoard(hitTestResult: hitTestResult.first!)
                    isPlayerBoardinited = true
                } else {
                    //self.addChessTest(hitTestResult: hitTestResult.first!)
                    guard let sceneView = sender.view as? ARSCNView else {return}
                    let touchLocation = sender.location(in: sceneView)
                    let hitTestResult = sceneView.hitTest(touchLocation, options: [SCNHitTestOption.boundingBoxOnly: true, SCNHitTestOption.ignoreHiddenNodes: true])
                    if !hitTestResult.isEmpty {
                       
                        if isNameButton(hitTestResult.first!.node, "randomButton") {
                            //点击以后randombutton下压
                        
                             randomButtonTopNode.runAction(SCNAction.sequence([
                                                             SCNAction.move(by: SCNVector3(0,-0.01,0), duration: 0.25),
                                                             SCNAction.move(by: SCNVector3(0,0.01,0), duration: 0.25)
                                                         ]))
//                            hitTestResult.first?.node.runAction(SCNAction.sequence([
//                                SCNAction.move(by: SCNVector3(1,0.5,1), duration: 0.5),
//                                SCNAction.move(by: SCNVector3(1,2,1), duration: 0.5)
//                            ]))
                            //
                            if playerStatues[curPlayerId].curCoin > 0 {
                                playerStatues[curPlayerId].curCoin -= 1
                                initBoardChess()
                            }
                        } else if isNameButton(hitTestResult.first!.node, "upgradeButton") {
                            upgradeButtonTopNode.runAction(SCNAction.sequence([
                                SCNAction.move(by: SCNVector3(0,-0.005,0), duration: 0.25),
                                SCNAction.move(by: SCNVector3(0,0.005,0), duration: 0.25)
                            ]))
                            upgradePlayerLevel(curPlayerId)
                        } else if isNameButton(hitTestResult.first!.node, "endButton"){
                            endButtonTopNode.runAction(SCNAction.sequence([
                                SCNAction.move(by: SCNVector3(0,-0.005,0), duration: 0.25),
                                SCNAction.move(by: SCNVector3(0,0.005,0), duration: 0.25)
                            ]))
                            switchGameStage()
                        }
                    }
                            
                }
            }
        }
    func findRootPos( _ rootNode: SCNNode ) -> [Int]? {
        var nodePos: [Int]? = nil
        for out in 0 ..< boardRootNode.count {
            for index in 0 ..< boardRootNode[out].count { //enemy those code can be combined
                              let curNode = boardRootNode[out][index]
                              if curNode == rootNode {
                                  nodePos = [out, index]
                               }
            }
        }
       return nodePos
    }
    func findChessPos( _ rootNode: SCNNode ) -> [Int]? {
          var nodePos: [Int]? = nil //第一位 2的话为storagenode
          for out in 0 ..< boardNode.count {
              for index in 0 ..< boardNode[out].count { //enemy those code can be combined
                                let curNode = boardNode[out][index]
                                if curNode == rootNode {
                                    nodePos = [out, index]
                                    break;
                                 }
              }
          }
        for index in 0 ..< storageNode.count {
            if storageNode[index] == rootNode {
                nodePos = [2, index]
            }
        }
         return nodePos
      }
    func insertChessPos(insertChess: baseChessNode, insertTo: baseChessNode) -> Bool{ //仅仅插入数组
        var inserToPos:[Int] = [] //0和1是boardnode上的 2是storagenode
        for index in 0 ..< boardNode.count {
            let curBoard = boardNode[index]
            for innerIndex in 0 ..< curBoard.count {
                let curNode = curBoard[innerIndex]
                if curNode == insertTo {
                    inserToPos = [index, innerIndex]
                    break;
                }
                
            }
        }
        for index in 0 ..< storageNode.count {
            let curNode = storageNode[index]
            if curNode == insertTo {
                inserToPos = [2, index]
                break;
            }
        }
        if inserToPos.count < 1 {
            return false
        }
        if inserToPos[0] < 2 {
            let curBoard = boardNode[inserToPos[0]]
            if curBoard.count > GlobalNumberSettings.chessNumber.rawValue {
                return false
            } else {
                //print("inserto", inserToPos[1])
                boardNode[inserToPos[0]].insert(insertChess, at: inserToPos[1])
            }
        } else {
            storageNode.insert(insertChess, at: inserToPos[1])
        }
       
        return true
    }
//    func swapChessPos( _ firstChess: baseChessNode, _ secondChess: baseChessNode ) {
//        var firstPos: [Int] = []
//        var secondPos: [Int] = []
//
//        for index in 0 ..< boardNode[0].count { //enemy those code can be combined
//            let curNode = boardNode[0][index]
//            if curNode == firstChess {
//                firstPos = [0, index]
//            }
//            if curNode == secondChess {
//               secondPos = [0, index]
//            }
//        }
//        for index in 0 ..< boardNode[1].count { //ally
//            let curNode = boardNode[1][index]
//            if curNode == firstChess {
//                firstPos = [1, index]
//            }
//            if curNode == secondChess {
//                secondPos = [1, index]
//            }
//        }
//        if firstPos.count > 0 && secondPos.count > 0 {
//            let temp1 = boardNode[firstPos[0]][firstPos[1]]
//                   let temp2 = boardNode[secondPos[0]][secondPos[1]]
//                  // print(temp)
//                   boardNode[firstPos[0]].remove(at: firstPos[1])
//                   boardNode[firstPos[0]].insert(temp2, at: firstPos[1])
//                   boardNode[secondPos[0]].remove(at: secondPos[1])
//                  //print(temp)
//                   boardNode[secondPos[0]].insert(temp1 , at: secondPos[1])
//                   if curDragPoint != nil {
//                       playerBoardNode.addChildNode(curDragPoint!)
//                   }
//
//                   updateWholeBoardPosition()
//
//        }
//
//    }
    func buyChess(playerID: Int, chessPrice: Int) -> Bool{
        let curPlayerMoney = playerStatues[playerID].curCoin
        if curPlayerMoney >= chessPrice {
            playerStatues[playerID].curCoin -= chessPrice
            return true
        }
        return false
    }
    func sellChess(playerID: Int, curChess: baseChessNode, curBoardSide: Int) {
        playerStatues[playerID].curCoin += curChess.chessPrice
        curChess.removeFromParentNode()
        
    }
    func checkCollisionWithChess(_ pressLocation: SCNVector3) {
//        let node = SCNNode()
//        node.coll
    }
    //test func remember to delete
    func initChessWithPos(pos: SCNVector3,sta: Int, info: chessStruct) -> baseChessNode{
        let chessNode = baseChessNode(statusNum: EnumsChessStage.forSale.rawValue, chessInfo: info)

        let xP = pos.x
        let yP = pos.y
        let zP = pos.z
        ///////
        // We create a Physically Based Rendering material
        let reflectiveMaterial = SCNMaterial()
        reflectiveMaterial.lightingModel = .physicallyBased
        // We want our ball to look metallic
        reflectiveMaterial.metalness.contents = 1.0
        // And shiny
        reflectiveMaterial.roughness.contents = 0.0
        chessNode.geometry?.firstMaterial = reflectiveMaterial

        let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: SCNCylinder(radius: 0.01, height: 0.01), options: nil))
        //body.mass = 5
        //body.isAffectedByGravity = true
        chessNode.physicsBody = body
        
        chessNode.physicsBody?.categoryBitMask = BitMaskCategoty.baseChess.rawValue
        chessNode.physicsBody?.contactTestBitMask = BitMaskCategoty.hand.rawValue
        
        chessNode.position = SCNVector3(xP,yP,zP)
        return chessNode
    }
    func addChessTest(hitTestResult: ARHitTestResult) {
        
        let positionOFPlane = hitTestResult.worldTransform.columns.3
        let xP = positionOFPlane.x
        let yP = positionOFPlane.y
        let zP = positionOFPlane.z
        let chessNode = initChessWithPos(pos: SCNVector3(xP, yP + 0.01, zP), sta: EnumsChessStage.forSale.rawValue, info: chessCollectionsLevel[0][0])
        //chessNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        
         self.sceneView.scene.rootNode.addChildNode(chessNode)
//        if let sideNode = chessNode.childNode(withName: "side", recursively: true) {
//            sideNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
//        }
                       
    }
    func calInsertPos(curBoardSide:Int, positionOfBoard: SCNVector3) -> Int{ //return 插入的index 如果是在最后一个棋子后面 就返回-1
        let curX = positionOfBoard.x - playerBoardNode.position.x
        
        var insertIndex = -1
        for index in 0 ..< boardRootNode[curBoardSide].count {
                if curX < boardRootNode[curBoardSide][index].position.x {
                    insertIndex = index
                    break
                }
        }
        return insertIndex
    }
    func insertNewNodeToBoard(curBoardSide:Int,curBoardIndex: Int, curChess: baseChessNode) {
        if(boardNode[curBoardSide].count < GlobalCommonNumber.chessNumber) {
            boardNode[curBoardSide].insert(curChess, at: curBoardIndex)
        }
    }
    func appendNewNodeToStorage(curChess: baseChessNode) {
        if storageNode.count < GlobalCommonNumber.storageNumber {
            storageNode.append(curChess)
        }
    }
    func summonToAllyBoard(newNode: baseChessNode, curBoardIndex: Int?) {
        newNode.chessStatus = EnumsChessStage.owned.rawValue
        //if newNode.abilities.contains(EnumAbilities.bait.rawValue) {
            var hasSummonAbility:[String : Int] = [:]
                   boardNode[BoardSide.allySide.rawValue].forEach{(curChess) in
                       if (curChess.abilities.contains(EnumAbilities.summonChessAddMountainBuff.rawValue)) {
                           if hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue] != nil {
                               hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue]! += curChess.chessLevel
                           } else {
                               hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue] = curChess.chessLevel
                           }
                       }
                   }
                   if hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue] != nil && hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue]! > 0 {
                       boardNode[BoardSide.allySide.rawValue].forEach{(curChess) in
                           if (curChess.chessKind == EnumChessKind.mountain.rawValue) {
                               curChess.AddBuff(AtkNumber: hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue], DefNumber: hasSummonAbility[EnumAbilities.summonChessAddMountainBuff.rawValue])
                           }
                           
                       }
                   }
        //}
        if let curIndex = curBoardIndex {
            insertNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue,curBoardIndex: curIndex, curChess: newNode)
        } else {
            appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: newNode)
        }
        //updateWholeBoardPosition()
    }
    func appendNewNodeToBoard(curBoardSide:Int, curChess: baseChessNode) {
        if(boardNode[curBoardSide].count < GlobalCommonNumber.chessNumber) {
            boardNode[curBoardSide].append(curChess)
        }
    }
    func appendNewNodeToBoardVisible(curBoardSide:Int, curChess: baseChessNode, isHidden: Bool) {
           if(boardNode[curBoardSide].count < GlobalCommonNumber.chessNumber) {
               boardNode[curBoardSide].append(curChess)
           }
       }
    func appendNewNodeToBoard(curBoard: inout [baseChessNode], curChess: baseChessNode) {
       if(curBoard.count < GlobalCommonNumber.chessNumber) {
            curBoard.append(curChess)
        }
    }
    //删除棋子
    func removeNodeFromBoard(curBoardSide:Int, curChess: baseChessNode) {
        if curBoardSide < BoardSide.storageSide.rawValue {
            for index in 0 ..< boardNode[curBoardSide].count {
                if boardNode[curBoardSide][index] == curChess {
                    boardNode[curBoardSide].remove(at: index)
                    break
                }
            }
        } else if curBoardSide == BoardSide.storageSide.rawValue {
            for index in 0 ..< storageNode.count {
                if storageNode[index] == curChess {
                    storageNode.remove(at: index)
                    break
                }
            }
        }
    }

    
    func emptyBoardSide(curBoardSide: Int) {
        boardNode[curBoardSide] = []
    }
    func recoverNodeToBoard(dragPos: [Int]) {
        if dragPos[0] == 0 {
            appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curChess: curDragPoint!)
        } else if dragPos[0] == 2{
            if curDragPoint != nil { //storage暂时较少用到 不封装放置方法
                storageNode.append(curDragPoint!)
            }
        }
    }
    func recoverBoardColor() {
        if let saleStage = playerBoardNode.childNode(withName: EnumNodeName.saleStage.rawValue, recursively: true) {
            saleStage.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        }
        if let storagePlace = playerBoardNode.childNode(withName: EnumNodeName.storagePlace.rawValue, recursively: true) {
            storagePlace.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        }
        if let allyBoard = playerBoardNode.childNode(withName: EnumNodeName.allyBoard.rawValue, recursively: true) {
            allyBoard.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        }
        if let enemyBoard = playerBoardNode.childNode(withName: EnumNodeName.enemyBoard.rawValue, recursively: true) {
            enemyBoard.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        }
    }
    func generateUpgradeChess( _ subChessNodes : [baseChessNode]) -> baseChessNode{//用于合成高等级棋子 保留3个棋子的所有特效  待完善 todo
        //之后可以增加一些判断是否超过2级
        return baseChessNode(statusNum: EnumsChessStage.owned.rawValue , chessInfo: chessStruct(name: subChessNodes[0].chessName, desc: subChessNodes[0].chessDesc, atkNum: subChessNodes[0].atkNum! * 2, defNum: subChessNodes[0].defNum! * 2, chessRarity: subChessNodes[0].chessRarity, chessLevel: subChessNodes[0].chessLevel + 1,chessKind: subChessNodes[0].chessKind, abilities: subChessNodes[0].abilities, temporaryBuff:[], rattleFunc: subChessNodes[0].rattleFunc, inheritFunc: subChessNodes[0].inheritFunc))
    }
    func updateStorageBoardPosition() -> Double{
        let totalTime = 0.5
        for index in 0 ..< storageNode.count {
            let curStorageChess = storageNode[index]
            let curRootNode = storageRootNode[index]
            let updateAction = SCNAction.move(to: SCNVector3(curRootNode.position.x, curRootNode.position.y + 0.01 , curRootNode.position.z), duration: totalTime)
                curStorageChess.runAction(updateAction)
        }
        return totalTime
    }
    func updateWholeBoardPosition() -> Double { //update all chesses' position
        let totalTime = 0.50
      
        // chess positions adjust actions
        for index in 0 ..< boardNode.count {
            let curBoardSide = boardNode[index]
            let startIndex = (GlobalNumberSettings.chessNumber.rawValue - curBoardSide.count) / 2
            for innerIndex in 0 ..< curBoardSide.count {
                let curRootNode = boardRootNode[index][innerIndex + startIndex]
                let curChessNode = boardNode[index][innerIndex]
              
                let updateAction = SCNAction.move(to: SCNVector3(curRootNode.position.x, curRootNode.position.y + 0.01 , curRootNode.position.z), duration: totalTime)
                curChessNode.runAction(updateAction)
            }
        }
        
        recoverRootNodeColor()
       return totalTime
    }
    func updateChessBoardPosition( _ attackResult: [Double] ) -> Double { //attack动作进行中调用的更新棋子位置的方法
        var totalTime = 0.50
        for typeIndex in 0 ..< 2 { // 0: 1:  2号位是动作时间
            if attackResult[typeIndex] == 0 {
                totalTime = updateWholeBoardPosition()
            }
        }
        return totalTime
    }
    func recoverRootNodeColor() {
        for innerIndex in 0 ..< self.boardRootNode.count {
            let curNodes = self.boardRootNode[innerIndex]
            curNodes.forEach{(curNode) in
                    curNode.geometry?.firstMaterial?.diffuse.contents = self.rootNodeDefalutColor[innerIndex]
                
            }
        }
    }
    
    /*below is Attack part*/
    
    func updateInherit(attackResult: ([Double]), attackBoardIndex: Int , attackIndex: Int, victimBoardIndex: Int, victimIndex: Int) -> Promise<[Double]> {
        return Promise(resolver: { (resolver) in
            var attackBoard = self.boardNode[attackBoardIndex]
            var victimBoard = self.boardNode[victimBoardIndex]
            let attacker = attackBoard[attackIndex]
            let victim = victimBoard[victimIndex]
            var attackerActions: [SCNAction] = []
            /*进行亡语或群居结算*/
            for curSide in 0 ... 1 { //0为攻击者 1为防守方
                let curBoardSide = curSide == 0 ? attackBoardIndex : victimBoardIndex
                let curChessPoint = curSide == 0 ? attacker : victim
                let oppositeSide = curSide == 0 ? victimBoardIndex : attackBoardIndex
                //
                if curSide == 0 && attackResult[curSide] != 0 {

                    if curChessPoint.abilities.contains(EnumAbilities.liveInGroup.rawValue) && self.boardNode[curBoardSide].count < GlobalCommonNumber.chessNumber { // <7
                        let randomNumber = Int.randomIntNumber(lower: 0, upper: 10) //0-9
                        //if randomNumber < 2 * victim.chessLevel { //20% 40% 60%
                            let copyChess = attacker.copyable()
                            attacker.abilities = [] //empty ability,in case it keep adding
                            if let curAttIndex = self.boardNode[curBoardSide].index(of: attacker) {
                                self.summonToAllyBoard(newNode: copyChess, curBoardIndex: curAttIndex + 1)
                            }
                            //
                        //}
                    }
                }
                if attackResult[curSide] == 0 { //如果当前棋子被消灭了 则触发亡语
                    if curChessPoint.abilities.contains(EnumAbilities.inheritAddBuff.rawValue) { //有传承加buff结算一下
                        let curRandomArr = randomDiffNumsFromArrs(outputNums:  curChessPoint.inheritFunc[EnumKeyName.summonNum.rawValue] as! Int, inputArr: self.boardNode[curBoardSide])
                        curRandomArr.forEach{ (attChess) in
                            //需要给attchess加buff
                            attChess.AddBuff(AtkNumber: curChessPoint.chessLevel * (curChessPoint.inheritFunc[EnumKeyName.baseAttack.rawValue] as! Int), DefNumber: curChessPoint.chessLevel * (curChessPoint.inheritFunc[EnumKeyName.baseDef.rawValue] as! Int))
                        }
                    }


                    if curChessPoint.abilities.contains(EnumAbilities.inheritDamage.rawValue) {
                        if case let curRattleDamage as Int = curChessPoint.inheritFunc[EnumKeyName.baseDamage.rawValue] {
                            if case let curRattleNum as Int = curChessPoint.inheritFunc[EnumKeyName.summonNum.rawValue] {
                                let damageChess = randomDiffNumsFromArrs(outputNums: curRattleNum, inputArr: self.boardNode[oppositeSide])

                                curChessPoint.abilityTrigger(abilityEnum: EnumAbilities.inheritAddBuff.rawValue.localized)
                                for vIndex in 0 ..< damageChess.count { //appendnewnode里会计算数量 多余的棋子会被砍掉
                                    let curChess = damageChess[vIndex] as! baseChessNode
                                    let result = curChess.getDamage(damageNumber: curRattleDamage)

                                    if result != 0 { //有动画
                                        self.removeNodeFromBoard(curBoardSide: oppositeSide, curChess: curChess)
                                        //inheritTime += result
                                    }

                                }
                                //self.updateWholeBoardPosition()


                            }
                        }
                    }
                    if curChessPoint.abilities.contains(EnumAbilities.inheritSummonSth.rawValue) {
                        if case let curRattleChess as [chessStruct] = curChessPoint.inheritFunc[EnumKeyName.summonChess.rawValue] {

                            curChessPoint.abilityTrigger(abilityEnum: EnumAbilities.inheritAddBuff.rawValue.localized)
                            for index in 0 ..< curRattleChess.count { //appendnewnode里会计算数量 多余的棋子会被砍掉
                                attackerActions += [
                                    SCNAction.customAction(duration: 0.5, action: { _,_ in
                                        self.appendNewNodeToBoard(curBoardSide: curBoardSide, curChess: baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: curRattleChess[index]))
                                    })
                                ]
                            }

                        } else if case let curRattleRarity as Int = curChessPoint.inheritFunc[EnumKeyName.baseRarity.rawValue] {
                            curChessPoint.abilityTrigger(abilityEnum: EnumAbilities.inheritAddBuff.rawValue.localized)
                            if case let curRattleNum as Int = curChessPoint.inheritFunc[EnumKeyName.summonNum.rawValue] {
                                let randomChessStruct = randomDiffNumsFromArrs(outputNums: curRattleNum, inputArr: chessCollectionsLevel[curRattleRarity - 1])
                                randomChessStruct.forEach{ (curChessStruct) in
                                    attackerActions += [
                                        SCNAction.customAction(duration: 0.5, action: { _,_ in
                                            self.appendNewNodeToBoard(curBoardSide: curBoardSide, curChess: baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: curChessStruct))
                                        })
                                    ]
                                   
                                }


                            }
                        }
                         //self.updateWholeBoardPosition()
                    }
                }

            }
            attackerActions += [
                SCNAction.customAction(duration: 0.5, action: { _,_ in
                    resolver.fulfill(attackResult)
                })
            ]
            attacker.runAction(SCNAction.sequence(attackerActions))
            
        })
    }
    
    func addnewchess() -> Promise<Bool>{
        return Promise(resolver: { (resolver) in
            boardNode[0].append(baseChessNode())
            resolver.fulfill(true)
        })
    }
    func aRoundTaskAsyncTest(_ beginIndex: inout [Int],_ attSide: Int, _ resolver: Resolver<Any>) {
        firstly {
            // 首先会调用此位置的代码
            return self.addnewchess()
        }.then { (res: (Bool)) in
            // 如果攻击动作完成了
            return self.addnewchess()
        }.done{ (res) in
            self.addnewchess()
        }.catch { (err)  in
            // self.loginProto(loginInfo: loginInfo)和self.loginDeal(res: res) 包装的两个promise执行了resolver.reject(),就会执行此代码段
            print("aRoundTaskAsyncTempError")
        }
    }
    
    func aRoundTaskAsyncTemp(_ beginIndex: inout [Int],_ attSide: Int, _ resolver: Resolver<Any>) {
        var beginIndexCopy = beginIndex
        var curIndex = beginIndex[attSide] //拷贝的
        var nextSide = attSide == BoardSide.enemySide.rawValue ? BoardSide.allySide.rawValue : BoardSide.enemySide.rawValue
        //统计当前有嘲讽的地方随从
        var baitIndex: [Int] = []
        for index in 0 ..< self.boardNode[nextSide].count {
            if self.boardNode[nextSide][index].abilities.contains(EnumAbilities.bait.rawValue) {
                baitIndex.append(index)
            }
        }
        //
        if (curIndex < boardNode[attSide].count && boardNode[nextSide].count > 0) { //当前游标小于进攻方数量
            var randomIndex = Int.randomIntNumber(lower: 0, upper: self.boardNode[nextSide].count)
            
            let attacker = self.boardNode[attSide][curIndex]
            
            if baitIndex.count > 0 && !attacker.abilities.contains(EnumAbilities.ignoreBait.rawValue) { //如果有嘲讽敌人且没有己方无视嘲讽技能 随机挑一个进行攻击
                randomIndex = baitIndex[Int.randomIntNumber(lower: 0, upper: baitIndex.count)]
            }
            
            let victim = self.boardNode[nextSide][randomIndex]
            firstly {
                // 首先会调用此位置的代码
                return self.attack(attackBoardIndex: attSide, attackIndex: curIndex, victimBoardIndex: nextSide, victimIndex: randomIndex)
            }.then { (res: ([Double])) in
                // 如果攻击动作完成了
                return self.updateInherit(attackResult: res, attackBoardIndex: attSide, attackIndex: curIndex, victimBoardIndex: nextSide, victimIndex: randomIndex)
            }.done{ (res) in
                if res[0] == 0 { //attacker eliminated
                    //index不动
                } else {
                    beginIndexCopy[attSide] += 1
                }
                if self.boardNode[attSide].count > 0 && self.boardNode[nextSide].count > 0 {
                    self.aRoundTaskAsyncTemp(&beginIndexCopy, nextSide, resolver)
                } else {
                    resolver.fulfill("success")
                }
            }.catch { (err)  in
                // self.loginProto(loginInfo: loginInfo)和self.loginDeal(res: res) 包装的两个promise执行了resolver.reject(),就会执行此代码段
                print("aRoundTaskAsyncTempError", err)
            }
        } else if boardNode[attSide].count > 0 && boardNode[nextSide].count > 0 {
            var nextRoundIndex = [0, 0]
            self.aRoundTaskAsyncTemp(&nextRoundIndex,nextSide, resolver)//从头开始
        } else {
            resolver.fulfill("success")
        }
        
    }

 
    
    
    func dealWithDamage() -> Promise<Any>{ //伤害清算
        return Promise<Any>( resolver: { (resolver) in
            if boardNode[0].count > 0 || boardNode[1].count > 0 { //平局的话就不处理了 do nth if its a draw+
                let curPlayer = playerStatues[curPlayerId]
                var winner = 1  //you win
                if boardNode[0].count > 0 {
                    winner = 0 //enemy win
                }
                var curDamage = 0
                boardNode[winner].forEach{(restChess) in
                    curDamage += restChess.chessRarity
                }
                if winner == 1 { // you win
                    playerStatues[curEnemyId].curBlood -= curDamage
                    playerStatues[curPlayerId].curCoin += (curDamage + GlobalNumberSettings.roundBaseCoin.rawValue)
                } else { // enemy win
                    playerStatues[curPlayerId].curBlood -= curDamage
                    playerStatues[curEnemyId].curCoin += (curDamage + GlobalNumberSettings.roundBaseCoin.rawValue)
                }
            }
            
            resolver.fulfill("success")
        }
        )
    }
    func beginRounds() -> Promise<Any>{ //当前默认是敌人方进行攻击 后续调整
       // while boardNode[0].count > 0 && boardNode[1].count > 0 {
        return Promise<Any>(resolver: { (resolver) in
           var beginIndex = [0, 0]
           var randomSide = Int.randomIntNumber(lower: 0, upper: 2)
           aRoundTaskAsyncTemp(&beginIndex,randomSide, resolver)
            })
//            var beginIndex = 0
//            aRoundTask(&beginIndex)
       // }
    }
    func initBoardRootNode() { //初始化底座node。是必须的 游戏开始必须调用
        if let allyBoardTemp = playerBoardNode.childNode(withName: "allyBoard", recursively: true) {
            allyBoardNode = allyBoardTemp
        }
        
        for index in 1 ... GlobalNumberSettings.chessNumber.rawValue {
            if let curNode = playerBoardNode.childNode(withName: "e" + String(index), recursively: true) {
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
            if let curNode = playerBoardNode.childNode(withName: "a" + String(index), recursively: true) {
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
            if let curNode = playerBoardNode.childNode(withName: "s" + String(index), recursively: true) {
                storageRootNode.append(curNode)
            }
        }
    }
    func switchGameStage() {
        if curStage == EnumsGameStage.exchangeStage.rawValue {  //交易转战斗
            disableButtons() //禁止buttons点击和手势事件
            let delayTime = PlayerBoardTextAppear(TextContent: "BattleStage".localized) //弹出切换回合提示
            delay(delayTime) {
                var totalTime = 0.00
                //处理abilities beforeround事件
                for index in 0 ..< self.boardNode[BoardSide.allySide.rawValue].count {
                    let curBoard = self.boardNode[BoardSide.allySide.rawValue]
                    let curChess = self.boardNode[BoardSide.allySide.rawValue][index]
                    if curChess.abilities.contains(EnumAbilities.endRoundAddBuffForGreen.rawValue) {
                        for innerIndex in 0 ..< self.boardNode[BoardSide.allySide.rawValue].count {
                            let curChess = self.boardNode[BoardSide.allySide.rawValue][innerIndex]
                            if innerIndex != index && (
                                curChess.chessKind == EnumChessKind.frost.rawValue ||
                                curChess.chessKind == EnumChessKind.plain.rawValue ||
                                curChess.chessKind == EnumChessKind.mountain.rawValue
                                ) {
                                curChess.AddBuff(AtkNumber: 1, DefNumber: 1) //当前hard code +1 /+1
                            }
                        }
//                        let copyChess = curChess.copyable()
//                        curChess.abilities = [] //empty ability,in case it keep adding
//                        self.boardNode[1].append(copyChess)
//                        self.playerBoardNode.addChildNode(copyChess)
                        curChess.abilityTrigger(abilityEnum: EnumAbilities.endRoundAddBuffForGreen.rawValue.localized)
                    }
                }
                //
                //let actionTime = self.updateWholeBoardPosition()
                totalTime += self.totalUpdateTime
                //
                self.curStage = EnumsGameStage.battleStage.rawValue
                //copy the backup data
                self.playerStatues[self.curPlayerId].curChesses = []
                self.boardNode[BoardSide.allySide.rawValue].forEach{(curChess) in
                    self.playerStatues[self.curPlayerId].curChesses.append(curChess.copyable())
                }
                //playerStatues[curPlayerId].curChesses = boardNode[1]
                delay(0.5 + totalTime) {
                    self.initDisplay()
                    self.initBoardChess()
                    self.beginRounds().done { (v1) in
                       self.dealWithDamage().done { (v2) in
                          self.switchGameStage()
                        } //伤害清算
                    }
                }
            }
        } else if curStage == EnumsGameStage.battleStage.rawValue { //战斗转交易
            let delayTime = PlayerBoardTextAppear(TextContent: "ExchangeStage".localized) //弹出切换回合提示
            delay(delayTime){
                self.recoverButtons()
                self.curStage = EnumsGameStage.exchangeStage.rawValue
                self.boardNode[1].forEach{(curChess) in
                    curChess.removeFromParentNode()
                }
                self.boardNode[1] = []
                self.playerStatues[self.curPlayerId].curChesses.forEach{(curChess) in
                    self.boardNode[1].append(curChess.copyable())
                }
                
                self.initDisplay()
                self.initBoardChess()
            }
        }
        //here update every players info, if there'll be multiplayers mode, you should get other players info, and then update to the playerStatues array
        //now we only update current player
        
    }
    func upgradePlayerLevel(_ playerID: Int) -> Bool{
        let playerInfo = playerStatues[playerID]
        if playerInfo.curCoin > 0 && playerInfo.curLevel < GlobalNumberSettings.maxLevel.rawValue {
            playerStatues[playerID].curCoin -= 1
            playerStatues[playerID].curLevel += 1
        } else {
            return false
        }
        return true
    }
    func feedEnemies() -> [chessStruct] {
        return dummyAICrew[curRound]
    }
    func getRandomChessStructFromPool(_ curLevel : Int) -> chessStruct { //不可能出现所有都小于等于0的情况 出现了就直接用现有的
        var randomLevel = 5//Int.randomIntNumber(lower: 1, upper: curLevel + 1)
        var randomNum =  Int.randomIntNumber(lower: 0, upper: chessCollectionsLevel[randomLevel - 1].count)
        var curChessInfo =  chessCollectionsLevel[randomLevel - 1][randomNum]
        var randomTime = 1
        while boardPool[curChessInfo.name!]! <= 0 && randomTime < 10 {
            randomLevel = Int.randomIntNumber(lower: 1, upper: curLevel + 1)
            randomNum = Int.randomIntNumber(lower: 0, upper: chessCollectionsLevel[randomLevel - 1].count)
            curChessInfo = chessCollectionsLevel[randomLevel - 1][randomNum]
            randomTime += 1
        }
        return curChessInfo
    }
    func initBoardChess() {
        boardNode[0].forEach{(boardNode) in
            boardNode.removeFromParentNode()
        }
        boardNode[0] = []
        let curPlayerLevel = playerStatues[curPlayerId].curLevel
        
        switch curStage {
        case EnumsGameStage.exchangeStage.rawValue:
            let curSaleNumber = 3//playerStatues[curPlayerId].curLevel + 2
            let curStartIndex = (GlobalNumberSettings.chessNumber.rawValue - curSaleNumber) / 2
            for index in 0 ..< curSaleNumber  {
                let curNode = boardRootNode[0][index + curStartIndex]
                
                let randomStruct =  getRandomChessStructFromPool(curPlayerLevel)
                let tempChess = initChessWithPos(pos: curNode.position, sta: EnumsChessStage.forSale.rawValue, info: randomStruct )
       
                boardNode[0].append(tempChess)

            }
//            for index in 0 ..< boardNode[1].count  {
//                if let curNode = playerBoardNode.childNode(withName: "a" + String(index + 1), recursively: true) {
//                    playerBoardNode.addChildNode(boardNode[1][index])
//                    //updateWholeBoardPosition()
//                }
//            }
            return
        case EnumsGameStage.battleStage.rawValue:
             let enemies = feedEnemies()
             if enemies.count > GlobalNumberSettings.chessNumber.rawValue {
                return
             }
             let curStartIndex = (GlobalNumberSettings.chessNumber.rawValue - enemies.count) / 2
             
             for index in 0 ..< enemies.count {
                    let curNode = boardRootNode[0][index + curStartIndex]
                    let tempChess = initChessWithPos(pos: curNode.position, sta: EnumsChessStage.enemySide.rawValue, info:  enemies[index])
                    boardNode[0].append(tempChess)
             }

        default:
            return
        }
    }
    func switchDisPlayText() {
        let curPlayer = playerStatues[curPlayerId]
        switch curStage {
        case EnumsGameStage.exchangeStage.rawValue:
            if let battleStageDisplay = playerBoardNode.childNode(withName: "battleStage", recursively: true) {
                battleStageDisplay.isHidden = true
            }
            if let saleStageDisplay = playerBoardNode.childNode(withName: EnumNodeName.saleStage.rawValue, recursively: true) {
                saleStageDisplay.isHidden = false
                
                levelTextNode.string = String(curPlayer.curLevel)
                moneyTextNode.string = String(curPlayer.curCoin)
            }
            return
        case EnumsGameStage.battleStage.rawValue:
            if let saleStageDisplay = playerBoardNode.childNode(withName: EnumNodeName.saleStage.rawValue, recursively: true) {
                saleStageDisplay.isHidden = true
            }
            if let battleStageDisplay = playerBoardNode.childNode(withName: "battleStage", recursively: true) {
                battleStageDisplay.isHidden = false
                
                enemyBloodTextNode.string = String(playerStatues[curEnemyId].curBlood)
                playerBloodTextNode.string = String(curPlayer.curBlood)
                
            }
            return
        default:
            return
        }
    }
    func initDisplay() {
       let curPlayer = playerStatues[curPlayerId]
        switch curStage {
        case EnumsGameStage.exchangeStage.rawValue:
            if let battleStageDisplay = playerBoardNode.childNode(withName: "battleStage", recursively: true) {
                battleStageDisplay.isHidden = true
            }
            if let saleStageDisplay = playerBoardNode.childNode(withName: EnumNodeName.saleStage.rawValue, recursively: true) {
                saleStageDisplay.isHidden = false
                
                levelTextNode.position = SCNVector3(-0.1, -0.5, 0.1)
                saleStageDisplay.addChildNode(levelTextNode)
                levelTextNode.string = String(curPlayer.curLevel)
                moneyTextNode.position = SCNVector3(-0.4, -0.5, 0.1)
                saleStageDisplay.addChildNode(moneyTextNode)
                moneyTextNode.string = String(curPlayer.curCoin)
            }
            return
        case EnumsGameStage.battleStage.rawValue:
            if let saleStageDisplay = playerBoardNode.childNode(withName: EnumNodeName.saleStage.rawValue, recursively: true) {
                saleStageDisplay.isHidden = true
            }
            if let battleStageDisplay = playerBoardNode.childNode(withName: "battleStage", recursively: true) {
                battleStageDisplay.isHidden = false
                
                enemyBloodTextNode.position = SCNVector3(-0.3, -0.5, 0.1)
                battleStageDisplay.addChildNode(enemyBloodTextNode)
                enemyBloodTextNode.string = String(playerStatues[curEnemyId].curBlood)
                playerBloodTextNode.position = SCNVector3(0.3, -0.5, 0.1)
                battleStageDisplay.addChildNode(playerBloodTextNode)
                playerBloodTextNode.string = String(curPlayer.curBlood)
                
            }
            return
        default:
            return
        }
    }
    //chessnode actions

    public func attack(attackBoardIndex: Int , attackIndex: Int, victimBoardIndex: Int, victimIndex: Int) -> Promise<[Double]> {
        return Promise<[Double]>(resolver: { (resolve) in
            var attackBoard = self.boardNode[attackBoardIndex]
            var victimBoard = self.boardNode[victimBoardIndex]
            let attacker = attackBoard[attackIndex]
            let victim = victimBoard[victimIndex]
            let atkStartPos = attacker.position
            var attackAtt = attacker.atkNum!
            var defAtt = victim.atkNum!
            var attackSequence: [SCNAction] = [] //攻击动作action sequence
            attackSequence = [attackAction(atkStartPos, victim.position)]
            if attacker.abilities.contains(EnumAbilities.furious.rawValue) { //如果有furious的话 有概率暴击
                let randomNumber = Int.randomIntNumber(lower: 1, upper: 5 - attacker.chessLevel)
                if randomNumber == 1 {
                    attackAtt *= 2
                    attacker.abilityTrigger(abilityEnum: EnumAbilities.furious.rawValue.localized)
                }
            }
            if attacker.abilities.contains(EnumAbilities.fly.rawValue) { //如果有飞行的话 victim的伤害为0
                defAtt = 0
                attackSequence.append(SCNAction.customAction(duration: 0.5, action: { _,_ in
                    attacker.abilityTrigger(abilityEnum: EnumAbilities.fly.rawValue.localized)
                }))
            }
            /*剧毒*/
            if attacker.abilities.contains(EnumAbilities.poison.rawValue) { //如果att有poison的话 直接秒杀
                attackSequence.append(SCNAction.customAction(duration: 0.5, action: { _,_ in
                    attacker.abilityTrigger(abilityEnum: EnumAbilities.poison.rawValue.localized)
                }))
                attackAtt = victim.defNum! + 1
                //}
            }
            if victim.abilities.contains(EnumAbilities.poison.rawValue) { //如果vic有poison的话 直接秒杀
                attackSequence.append(SCNAction.customAction(duration: 0.5, action: { _,_ in
                    victim.abilityTrigger(abilityEnum: EnumAbilities.poison.rawValue.localized)
                }))
                defAtt = attacker.defNum! + 1
            }
            /*闪避 敏锐*/
            if victim.abilities.contains(EnumAbilities.acute.rawValue) { //如果vic有闪避的话 有概率躲闪攻击
                
                let randomNumber = Int.randomIntNumber(lower: 0, upper: 10) //0-9
                if randomNumber < 2 * victim.chessLevel { //20% 40% 60%
                    attackSequence.append(SCNAction.customAction(duration: 0.5, action: { _,_ in
                        victim.abilityTrigger(abilityEnum: (EnumAbilities.acute.rawValue + "Short").localized)
                    }))
                    attackAtt = 0
                }
            }
            
            
            
            //shell比剧毒完结算 优先级更高
            if attacker.temporaryBuff.contains(EnumAbilities.shell.rawValue) { //如果攻击者有shell
                defAtt = 0
                attackSequence.append(SCNAction.customAction(duration: 0.5, action: { _,_ in
                    attacker.toggleShell(status: false) //抵消伤害 shell 消失
                }))
            }
            
            if victim.temporaryBuff.contains(EnumAbilities.shell.rawValue) { //如果被攻击者有shell
                attackAtt = 0
                attackSequence.append(SCNAction.customAction(duration: 0.5, action: { _,_ in
                    victim.toggleShell(status: false) //抵消伤害 shell 消失
                }))
            }
            
            
            //blood calculate
            var attRstBlood = attacker.defNum! - defAtt
            var vicRstBlood = victim.defNum! - attackAtt
            var actionResult = [1.00, 1.00] //1 represents alive, 0 represents the opposite
            
            var totalTime = 0.00
            
            //
            
            
            attackSequence += [
                damageAppearAction([attacker, victim], [victim.atkNum! , attackAtt]),   //伤害弹出动画
                bloodChangeAction([attacker, victim], [attRstBlood, vicRstBlood])
            ]
            //尖刺
            if victim.abilities.contains(EnumAbilities.spine.rawValue) {
                //blood calculate
                let spineDam = victim.chessLevel
                attRstBlood = attRstBlood - spineDam
                
                attackSequence += [
                    SCNAction.customAction(duration: 0.5, action: {_,_ in
                        victim.abilityTrigger(abilityEnum: EnumAbilities.spine.rawValue.localized)
                    }),
                    damageAppearAction([attacker], [spineDam]),   //伤害弹出动画
                    bloodChangeAction([attacker], [attRstBlood])
                ]
            }
            //alive test 计算是否还存在
            actionResult[0] = attRstBlood > 0 ? 1 : 0
            actionResult[1] = vicRstBlood > 0 ? 1 : 0
            //计算完以后结算是否返回动作
            if attRstBlood > 0 {
                     attackSequence += [backToAction(atkStartPos, attacker)]
            }
            //计算动作用时 calculate the total time of all the actions
            attackSequence.forEach { (action) in
                totalTime += action.duration
            }
            actionResult.append(totalTime)
            //
            attackSequence += [
                SCNAction.customAction(duration: 0.5, action: {_,_ in
                    /*进行攻击结束后的结算*/
//                    if actionResult[0] == 0 { //attacker eliminated
//                        attackBoard.remove(at: attackIndex)
//                    }
//                    if actionResult[1] == 0 { //victim elinminated
//                        victimBoard.remove(at: victimIndex)
//                    }
                    resolve.fulfill(actionResult)
                }),
            ]
            attacker.runAction(SCNAction.sequence(attackSequence))
        })
    }
    func recoverButtons() {
        randomButtonNode.runAction(SCNAction.fadeIn(duration: 1))
        upgradeButtonNode.runAction(SCNAction.fadeIn(duration: 1))
        endButtonNode.runAction(SCNAction.fadeIn(duration: 1))
        //
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action:  #selector(onLongPress))
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        longPressGestureRecognizer.cancelsTouchesInView = false
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    func disableButtons() {
        randomButtonNode.runAction(SCNAction.fadeOut(duration: 1))
        upgradeButtonNode.runAction(SCNAction.fadeOut(duration: 1))
        endButtonNode.runAction(SCNAction.fadeOut(duration: 1))
        removeGestureRecoginzer()
        
    }
    func recoverGestureRecoginzer() {
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action:  #selector(onLongPress))
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        longPressGestureRecognizer.cancelsTouchesInView = false
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    func removeGestureRecoginzer() {
        self.sceneView.removeGestureRecognizer(longPressGestureRecognizer)
        self.sceneView.removeGestureRecognizer(tapGestureRecognizer)
    }
    
    func initButtons() {
        if let randomButtonTopTemp = playerBoardNode.childNode(withName: "randomButtonTop", recursively: true) {
            randomButtonTopNode = randomButtonTopTemp
        }
        if let upgradeButtonTopTemp = playerBoardNode.childNode(withName: "upgradeButtonTop", recursively: true) {
            upgradeButtonTopNode = upgradeButtonTopTemp
        }
        if let endButtonTopTemp = playerBoardNode.childNode(withName: "endButtonTop", recursively: true) {
            endButtonTopNode = endButtonTopTemp
        }
        if let randomButtonTemp = playerBoardNode.childNode(withName: "randomButton", recursively: true) {
            randomButtonNode = randomButtonTemp
        }
        if let upgradeButtonTemp = playerBoardNode.childNode(withName: "upgradeButton", recursively: true) {
            upgradeButtonNode = upgradeButtonTemp
        }
        if let endButtonTemp = playerBoardNode.childNode(withName: "endButton", recursively: true) {
            endButtonNode = endButtonTemp
        }
    }
    func initGameTest() {
        initBoardRootNode()
        initBoardChess()
        initDisplay()
        initButtons()
//        for index in 1 ..< 7 {
//            if let curNode = playerBoardNode.childNode(withName: "e" + String(index), recursively: true) {
//                let tempChess = initChessWithPos(pos: curNode.position)
//                tempChess.name = "chessE" + String(index)
//                tempChess.position.y += 0.01
//
//                playerBoardNode.addChildNode(tempChess)
//
//                boardNode[0].append(tempChess)
//            }
//        }
//        for index in 1 ..< 7 {
//            if let curNode = playerBoardNode.childNode(withName: "a" + String(index), recursively: true) {
//                let tempChess = initChessWithPos(pos: curNode.position)
//                tempChess.name = "chessA" + String(index)
//                tempChess.position.y += 0.01
//
//                playerBoardNode.addChildNode(tempChess)
//
//                boardNode[1].append(tempChess)
//            }
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
//           //let attackResult = attack(self.boardNode[0][0], self.boardNode[1][1])
//            self.beginRounds()
//
////            let startPos = self.boardNode[0][0].position
////            let attackSequence = SCNAction.sequence([attackAction(startPos, self.boardNode[1][1].position),backToAction(startPos)])
////            self.boardNode[0][0].runAction(attackSequence)
//
//        })
           
       }
    func PlayerBoardTextShow(TextContent: String) -> Double{
           let t1 = 0.1
           if let boardTextTemp = playerBoardNode.childNode(withName: "boardTextNode", recursively: true) {
               boardTextTemp.parent!.isHidden = false //先显示text parent
           //if let parentBound = playerBoardNode.childNode(withName: "middleLine", recursively: true) {
               let tempTextGeo: SCNText = boardTextTemp.geometry as! SCNText
               tempTextGeo.string = TextContent
               let (min, max) = boardTextTemp.parent!.boundingBox
               let dx = min.x + 0.5 * (max.x - min.x)
               let dy = min.y + 0.5 * (max.y - min.y)
               let dz = min.z + 0.5 * (max.z - min.z)
               boardTextTemp.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
              
               boardTextTemp.runAction(SCNAction.sequence([
                   SCNAction.fadeIn(duration: t1)
               ]))
               }
           return t1
       }
    func PlayerBoardTextOff(){
        if let boardTextTemp = playerBoardNode.childNode(withName: "boardTextNode", recursively: true) {
                    boardTextTemp.parent!.isHidden = true
             
            }
    }
    /////////////////end////////
    func PlayerBoardTextAppear(TextContent: String) -> Double{
        let t1 = 0.1
        let t2 = 0.7
        let t3 = 0.3
        if let boardTextTemp = playerBoardNode.childNode(withName: "boardTextNode", recursively: true) {
            boardTextTemp.parent!.isHidden = false //先显示text parent
        //if let parentBound = playerBoardNode.childNode(withName: "middleLine", recursively: true) {
            let tempTextGeo: SCNText = boardTextTemp.geometry as! SCNText
            tempTextGeo.string = TextContent
            
            
            let (min, max) = boardTextTemp.parent!.boundingBox
            let dx = min.x + 0.5 * (max.x - min.x)
            let dy = min.y + 0.5 * (max.y - min.y)
            let dz = min.z + 0.5 * (max.z - min.z)
            boardTextTemp.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
           
            boardTextTemp.runAction(SCNAction.sequence([
                SCNAction.fadeIn(duration: t1),
                SCNAction.wait(duration: t2),
                SCNAction.fadeOut(duration: t3),
                SCNAction.customAction(duration: 0, action: { _,_ in
                    boardTextTemp.parent!.isHidden = true
                })
            ]))
            }
           
        //}
        
        return t1 + t2 + t3
    }
    func initPlayerBoard(hitTestResult: ARHitTestResult) {
        playerBoardNode = createPlayerBoard()
        //playerBoardNode.eulerAngles = SCNVector3(45.degreesToRadius, 0, 0)
        //playGroundNode.geometry?.firstMaterial?.isDoubleSided = true
        //playGroundNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        let positionOFPlane = hitTestResult.worldTransform.columns.3
        let xP = positionOFPlane.x
        let yP = positionOFPlane.y
        let zP = positionOFPlane.z
        playerBoardNode.position = SCNVector3(xP,yP,zP)
        playerBoardNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: playerBoardNode))
        //playGroundNode.physicsBody?.categoryBitMask = BitMaskCategoty.playGround.rawValue
        //playGroundNode.physicsBody?.contactTestBitMask = BitMaskCategoty.baseCard.rawValue
        self.sceneView.scene.rootNode.addChildNode(playerBoardNode)
       
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                                       self.initGameTest()
        })
       
    }
    func initHandNode() {
        let newNode = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 0.005))
        newNode.name = ContactCategory.hand.rawValue
         //newNode.simdTransform = hitTestResult.worldTransform
         newNode.position.x = 0
         newNode.position.y = 0
         newNode.position.z = 0
         newNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
         //hands physics body
        let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: SCNCylinder(radius: 0.05, height: 0.005), options: [SCNPhysicsShape.Option.keepAsCompound : true]))
          newNode.physicsBody = body

          newNode.physicsBody?.categoryBitMask = BitMaskCategoty.hand.rawValue
          newNode.physicsBody?.contactTestBitMask = BitMaskCategoty.baseChess.rawValue
          
         newNode.isHidden = true
         handPoint = newNode
         self.sceneView.scene.rootNode.addChildNode(handPoint)
    }
    func initReferenceNode() {
        let newNode = SCNNode(geometry: SCNSphere(radius: 0.01))
       
         //newNode.simdTransform = hitTestResult.worldTransform
         newNode.position.x = 0
         newNode.position.y = 0
         newNode.position.z = 0
         newNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
         //hands physics body
        let body = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: newNode, options: [SCNPhysicsShape.Option.scale: SCNVector3(0.22, 0.22, 0.22)]))
        //body.angularVelocityFactor = SCNVector3(1.0,0.0,1.0)
        body.isAffectedByGravity = false
        newNode.physicsBody = body

          newNode.physicsBody?.categoryBitMask = BitMaskCategoty.hand.rawValue
          newNode.physicsBody?.contactTestBitMask = BitMaskCategoty.baseChessHolder.rawValue
        newNode.physicsBody?.collisionBitMask = BitMaskCategoty.baseChessHolder.rawValue
          
         newNode.isHidden = true
         referencePoint = newNode
         self.sceneView.scene.rootNode.addChildNode(referencePoint)
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
         let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategoty.baseChessHolder.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategoty.hand.rawValue
            {
            
               for index in 0 ..< boardRootNode.count {
                let curBoard = boardRootNode[index]

                    curBoard.forEach{(boardNode) in
                        if boardNode.name != nodeA.name {
//                            if boardNode.name == "a3" {
//                                print("findNode1: ", boardNode.name)
//                            }
                           //nodeA.runAction(SCNAction.scale(to: 0.1, duration: 1))
                            //nodeA.geometry?.firstMaterial?.diffuse.contents = rootNodeDefalutColor[index]
                        } else {
                           // print("findNode2: ", boardNode.name)
                           // let newMat =
                             //nodeA.runAction(SCNAction.scale(to: 0.12, duration: 1))
                            //let curColor = rootNodeDefalutColor[index]
                             nodeA.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                                for innerIndex in 0 ..< self.boardRootNode.count {
                                    let curNodes = self.boardRootNode[innerIndex]
                                    curNodes.forEach{(curNode) in
                                        if curNode.name != boardNode.name {
                                            curNode.geometry?.firstMaterial?.diffuse.contents = self.rootNodeDefalutColor[innerIndex]
                                        }
                                        
                                    }
                                }
                            })
                            
                        }
                    }
                }
            }
//            else if nodeA.physicsBody?.categoryBitMask == BitMaskCategoty.saleScreen.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategoty.hand.rawValue {
//                if let saleScreen = playerBoardNode.childNode(withName: "saleStage", recursively: true) {
//                     saleScreen.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
//                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
//                        saleScreen.geometry?.firstMaterial?.diffuse.contents = UIColor.black
//                     })
//                }
//            }
    }
    // MARK: - ARSCNViewDelegate

    public func renderer(_: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let _ = anchor as? ARPlaneAnchor else { return nil }

        // We return a special type of SCNNode for ARPlaneAnchors
       return customPlaneNode()
    }

    public func renderer(_: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node as? customPlaneNode else {
            return
        }
        planeNode.update(from: planeAnchor)
    }

    public func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node as? customPlaneNode else {
            return
        }
        if planeNode.position.y > 0 {
            return
        }
        planeNode.update(from: planeAnchor)
    }
}



//func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
//    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
//}
func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}
func averageVector(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + (right.x - left.x) / 2, right.y, right.z)
}
