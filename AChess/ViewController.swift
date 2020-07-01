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
import MultipeerConnectivity

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
   
    @IBOutlet weak var messageLabel: UILabel!
    
    var setting = (controlMethod : 0, particalOn : 0)//0:  0 用tap的方式操作。1用手识别操作  这个数据应该存在数据库或缓存里作为全局变量
    
    
    
    //以下数据为实时记录数据 无需保存
    var rootNodeDefalutColor = [UIColor.red, UIColor.green]
    var isPlayerBoardinited = false
    var isBoardInfoSent = false
    var playerBoardNode = createPlayerBoard() //棋盘节点
    var curPlaneNode:customPlaneNode? = nil
    let priceTagNode = TextNode(textScale: SCNVector3(0.3, 0.5, 0))
    var randomButtonTopNode: SCNNode = SCNNode()
    var upgradeButtonTopNode: SCNNode = SCNNode()
    var endButtonTopNode: SCNNode = SCNNode()
    var freezeButtonTopNode: SCNNode = SCNNode()
    var randomButtonNode: SCNNode = SCNNode()
    var upgradeButtonNode: SCNNode = SCNNode()
    var freezeButtonNode: SCNNode = SCNNode()
    var endButtonNode: SCNNode = SCNNode()
    var allyBoardNode : SCNNode = SCNNode()
    let totalUpdateTime:Double = 1 //刷新时间
    var curUpgradeCoin = 5 {
        didSet(oldV) {//升级费用
            print(curUpgradeCoin)
           priceTagNode.string = String(curUpgradeCoin)
        }
    }
    var isFreezed:Bool = false //是否冻结
    var isRandoming:Bool = false // 是否在随机
    var isWaiting:Bool = false //是否在等待所有玩家准备
    var updatePromise:Resolver<Double>? = nil
    var multipeerSession: multiUserSession! //多人session
  
    var handPoint = SCNNode() // use for mode1 with hand
    var referencePoint = SCNNode() // use for mode0 with touching on screen
    var tempTransParentNode = baseChessNode()
    
    var curDragPoint: baseChessNode? = nil
    var curChoosePoint: baseChessNode? = nil
    var curDragPos:[Int] = [] //0:棋盘 1:index
    var curFocusPoint: SCNNode? = nil
    
    //以下数据需要保存
    var boardPool : [String : Int] = ["" : 0] //卡池
    var freezedChessNodes: [baseChessNode] = []
    var gameConfigStr = settingStruct(isShareBoard: true, playerNumber: 2, isMaster: false)
    var curMasterID: MCPeerID? //如果是从机会获取到主机的id
    var currentSlaveId: [playerStruct] = []//如果是主机会获取到所有的从机id  index 0 是主机id
    
    var boardNode :[[baseChessNode]] = [[],[]] //chesses
        {
            didSet(oldBoard) {
  
                if (curStage == EnumsGameStage.exchangeStage.rawValue) {
                    //
                    playerStatues[0].curChesses = copyChessArr(curBoard: boardNode[BoardSide.allySide.rawValue])
                    //
                    var chessTimesDic:[[String : [Int]]] = [[:],[:],[:]] //棋子map 刷新问题
                    var chessKindMap:[String : Int] = [:]
                    var newCombineChess: [baseChessNode] = []
                    var oldSubChessIndex: [Int] = []
                    for index in 0 ..< boardNode.count {
                        for innerIndex in 0 ..< boardNode[index].count {
                            
                            let curChessNode = boardNode[index][innerIndex]
                            
                            if index == BoardSide.allySide.rawValue{
                                /*光环效果-只在交易阶段更新aura*/
                                if chessKindMap[curChessNode.chessKind] != nil {
                                    chessKindMap[curChessNode.chessKind]! += 1
                                } else {
                                    chessKindMap[curChessNode.chessKind] = 1
                                }
                            }
                                                     
                           
                            if (index == BoardSide.allySide.rawValue && curChessNode.chessLevel < 3) { //只有己方 echange stage才触发
                               
                        
                                 /*棋子合成*/
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
                     /*棋子合成end*/
                    
                    /*chess aura*/
                    var newAuraArr:[String] = []

                    if let mountainNum = chessKindMap[EnumChessKind.mountain.rawValue] {
                        if mountainNum >= 3 && mountainNum < 6 {
                            newAuraArr.append(EnumAuraName.mountainLevel1.rawValue)
                        } else if mountainNum >= 6 {
                            newAuraArr.append(EnumAuraName.mountainLevel2.rawValue)
                        }
                    }
                    if let oceanNum = chessKindMap[EnumChessKind.ocean.rawValue] {
                        if oceanNum >= 3 && oceanNum < 6 {
                            newAuraArr.append(EnumAuraName.oceanLevel1.rawValue)
                        } else if oceanNum >= 6 {
                            newAuraArr.append(EnumAuraName.oceanLevel2.rawValue)
                        }
                    }
                    if let plainNum = chessKindMap[EnumChessKind.plain.rawValue] {
                        if plainNum >= 3 && plainNum < 6 {
                            newAuraArr.append(EnumAuraName.plainLevel1.rawValue)
                        } else if plainNum >= 6 {
                            newAuraArr.append(EnumAuraName.plainLevel2.rawValue)
                        }
                    }
                    
                    //
                     playerStatues[curPlayerId].curAura = newAuraArr //清空光环
  
                }
                
                
                
                
                for boardIndex in 0 ..< boardNode.count {
                    for innerIndex in 0 ..< boardNode[boardIndex].count {
                        if !oldBoard[boardIndex].contains(boardNode[boardIndex][innerIndex]) {
                            let curNode = self.boardNode[boardIndex][innerIndex]
                            curNode.position.y = 0.01
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1 * Double((innerIndex))) {
                                if curNode != nil {
                                    self.playerBoardNode.addChildNode(curNode)
                                }
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
                        if !boardNode[boardIndex].contains(oldBoard[boardIndex][innerIndex]) {
                            if (curStage == EnumsGameStage.battleStage.rawValue) { //亡语生效
                                var isMaxLevel = false
                                /*AllInheritMax*/
                                for subIndex in 0 ..< boardNode[boardIndex].count {
                                    if boardNode[boardIndex][subIndex].abilities.contains(EnumAbilities.allInheritMax.rawValue) {
                                        isMaxLevel = true
                                        break
                                    }
                                }
                                /*End*/
                                
                                let erasedChess = oldBoard[boardIndex][innerIndex]
                                let oppoBoardSide = boardIndex == BoardSide.allySide.rawValue ? BoardSide.enemySide.rawValue : BoardSide.allySide.rawValue
                                let curStar = isMaxLevel ? GlobalCommonNumber.maxStars : erasedChess.chessLevel
                                self.boardNode[boardIndex].forEach{ (curBuffChess) in
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
                                    let curRandomArr = randomDiffNumsFromArrs(outputNums: addNum as! Int, inputArr: self.boardNode[boardIndex])
                                    curRandomArr.forEach{ (attChess) in
                                        //需要给attchess加buff
                                        attChess.AddBuff(AtkNumber: curStar * (erasedChess.inheritFunc[EnumKeyName.baseAttack.rawValue] as! Int), DefNumber: curStar * (erasedChess.inheritFunc[EnumKeyName.baseDef.rawValue] as! Int))
                                    }
                                }
                                
                                
                                if erasedChess.abilities.contains(EnumAbilities.inheritDamage.rawValue) {
                                    if case let curRattleDamage as Int = erasedChess.inheritFunc[EnumKeyName.baseDamage.rawValue] {
                                        if case let curRattleNum as Int = erasedChess.inheritFunc[EnumKeyName.summonNum.rawValue] {
                                            let damageChess = randomDiffNumsFromArrs(outputNums: curRattleNum, inputArr: self.boardNode[oppoBoardSide])
                                            abilityTextTrigger(textContent: EnumAbilityType.inherit.rawValue.localized, textPos: erasedChess.position, textType: EnumAbilityType.inherit.rawValue)
//                                            erasedChess.abilityTrigger(abilityEnum: EnumAbilities.inheritDamage.rawValue.localized)
                                            for vIndex in 0 ..< damageChess.count {
                                                let curChess = damageChess[vIndex] as! baseChessNode
                                                inheritPromiseArr.append({() in
                                                    return Promise<Double>(resolver: {(resolver) in
                                                        let damTime = self.dealDamageAction(startVector: erasedChess.position, endVector: curChess.position)
                                                        delay(damTime, task: {
                                                                isAlive = curChess.getDamage(damageNumber: curRattleDamage * curStar, chessBoard: &self.boardNode[oppoBoardSide])
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
                                                if innerIndex <= self.boardNode[boardIndex].count {
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
                                                
                                                if innerIndex <= self.boardNode[innerIndex].count {
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
                            needDeleteChesses.append(oldBoard[boardIndex][innerIndex])
                            //oldBoard[boardIndex][innerIndex].removeFromParentNode()
                        }
                    }
                }
                
                
                recyclePromise(taskArr: inheritPromiseArr, curIndex: 0).done{ _ in
                    DispatchQueue.main.async{
                        for i in 0 ..< needDeleteChesses.count {
                                needDeleteChesses[i].removeFromParentNode()
                        }
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
    var boardRootNode :[[SCNNode]] = [[],[]] //chess holder
    var storageNode : [baseChessNode] = [] {
        didSet(oldBoard) {
            
                for innerIndex in 0 ..< storageNode.count {
                    if !oldBoard.contains(storageNode[innerIndex]) {
                        storageNode[innerIndex].position.y = 0.01
                        playerBoardNode.addChildNode(storageNode[innerIndex])
                    }
                }
                updateStorageBoardPosition()  //dont delete
        }
    }
    var storageRootNode : [SCNNode] = []
   
    //var backupBoardNode:[[baseChessNode]] = [[],[]]
    var playerStatues: [playerStruct] = [playerStruct(playerName: "player1", curCoin: GlobalNumberSettings.roundBaseCoin.rawValue + 50, curLevel: 1, curBlood: 10, curChesses: [], curAura: [], isComputer: false, playerID: MCPeerID(displayName: "player1")), playerStruct(playerName: "player2", curCoin: 40, curLevel: 1, curBlood: 10, curChesses: [baseChessNode(statusNum: EnumsChessStage.enemySide.rawValue, chessInfo: chessCollectionsLevel[2][17]), baseChessNode(statusNum: EnumsChessStage.enemySide.rawValue, chessInfo: chessCollectionsLevel[2][17]), baseChessNode(statusNum: EnumsChessStage.enemySide.rawValue, chessInfo: chessCollectionsLevel[2][17])], curAura: [], isComputer: false,  playerID: MCPeerID(displayName: "player2"))] {
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
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation") //强制横屏
        messageLabel.text = String(gameConfigStr.isMaster)
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        initHandNode()
        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        //sceneView.scene = scene
        
        multipeerSession.changeHandler(newHandler: receivedData)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {

        
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false; //禁用向左滑动
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        //hide the transparent ndoe
        tempTransParentNode.isHidden = true
        //refresh cur user data
        if multipeerSession != nil {
            let curPlayerId = multipeerSession.getMyId()
            playerStatues[0].playerName = curPlayerId.displayName
            playerStatues[0].playerID = curPlayerId
        }
        
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
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true;
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override var shouldAutorotate: Bool { //禁用旋转屏幕
        return false
    }
    
    
    // MARK: - Multiuser shared session

    var mapProvider: MCPeerID?

    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        
        do {
            let decoder = JSONDecoder() //decode json: playerstruct
           
            if let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                
                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
            } else if let anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARPlaneAnchor.self, from: data) { //地板anchor
                // Add anchor to the session, ARSCNView delegate adds visible content.
                anchor.setValue("customPlane", forKey: "name")
                sceneView.session.add(anchor: anchor)
            }
            else if let anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) { //棋盘anchor
                isBoardInfoSent = true
                // Add anchor to the session, ARSCNView delegate adds visible content.
                anchor.setValue("playerBoard", forKey: "name")
                sceneView.session.add(anchor: anchor)
            } else  if let enemyPlayerStruct = try? decoder.decode(codblePlayerStruct.self, from: data){
                
          
                    if let decodeID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: enemyPlayerStruct.encodePlayerID!) {
                        if gameConfigStr.isMaster { //主机每次收到数据都默认更新一下玩家数据信息
                            var alivePlayer:[MCPeerID] = []
                            currentSlaveId[0].curBlood = playerStatues[0].curBlood //update master blood
                                for i in 0 ..< currentSlaveId.count {
                                    if currentSlaveId[i].playerID == decodeID {
                                        currentSlaveId[i].curBlood = enemyPlayerStruct.curBlood
                                    }
                                    if currentSlaveId[i].curBlood > 0 {
                                        if currentSlaveId[i].playerID != nil {
                                          alivePlayer.append(currentSlaveId[i].playerID!)
                                        }
                                    }
                                }
                            if alivePlayer.count == 1 {
                                //that player win the game
                                if alivePlayer[0] == multipeerSession.getMyId() {
                                    //master win the game
                                    winTheGame()
                                } else { //通知赢的玩家获胜了
                                    if let strData = encodeCodable(ori: EnumMessageCommand.winTheGame.rawValue) {
                                        let curId = findSimiInstance(arr: multipeerSession.connectedPeers, obj: alivePlayer[0])
                                        multipeerSession.sendToPeer(strData, [curId])
                                    }
                                }
                                return
                            }
                        }
                        
                        if enemyPlayerStruct.encodePlayerID != nil && enemyPlayerStruct.curChesses != nil && curStage != EnumsGameStage.battleStage.rawValue {
                            /*更新敌人数据*/
                            playerStatues[1].playerID = decodeID
                            var tempEnemybaseChess:[baseChessNode] = []
                            enemyPlayerStruct.curChesses!.forEach{(encodeChess) in
                                tempEnemybaseChess.append(baseChessNode(statusNum: EnumsChessStage.enemySide.rawValue, codeChessInfo: encodeChess))
                            }
                            if enemyPlayerStruct.isComputer {
                                feedEnemies()
                            } else {
                                playerStatues[1].curChesses = tempEnemybaseChess
                            }
                            /*end*/
                            //收到了对手的信息 把自己的信息也打包发给对手
                            if gameConfigStr.isMaster || enemyPlayerStruct.isComputer { //如果主机收到了就不用再发了 如果是电脑直接开打
                                switchGameStage() //收到对手阵容开始比赛
                            } else if peer == curMasterID { //从机 如果信息来自主机则发送给对手 是没有对手阵容的
                                let encodedData = encodeCodablePlayerStruct(playerID: multipeerSession.getMyId(), player: playerStatues[0])
                                let curId = findSimiInstance(arr: multipeerSession.connectedPeers, obj: decodeID)
                                multipeerSession.sendToPeer(encodedData, [curId])
                                if decodeID == curMasterID { //如果对手也是主机 那么是有阵容的
                                    switchGameStage()
                                }
                            } else { //从机 信息不是来自主机 则是有对手阵容的 则开始游戏
                                switchGameStage() //收到对手阵容开始比赛
                            }
                        }
                }
              
            }else if let strFlag = String(data: data, encoding: String.Encoding.utf8) {
                if strFlag == "readyBattle" && gameConfigStr.isMaster { //主机收到从机准备成功
                    if currentSlaveId != nil {
                        for i in 0 ..< currentSlaveId.count {
                            if currentSlaveId[i].playerID === peer {
                                currentSlaveId[i].playerStatus = true //准备完成
                                break
                            }
                        }
                       
                    }
                    if checkIfAllReady() {
                        masterArrangeBattles()
                    }
                } else if strFlag == EnumMessageCommand.switchGameStage.rawValue && !gameConfigStr.isMaster { //从机切换至战斗
                    //主机分配从机对手
                    switchGameStage()
                } else if strFlag == EnumMessageCommand.winTheGame.rawValue { //赢得比赛
                    winTheGame()
                }
            } else {
                print("unknown data recieved from \(peer)")
            }
         
        } catch {
            print("can't decode data recieved from \(peer)")
        }
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
                        if let curPressParent = findChessRootNode(curPressNode) { //按到棋子上了
                            if let curIndexArr = findChessPos(curPressParent) {
                                if let curTransPos = findChessPos(tempTransParentNode) { //找得到就不插入 直接改位置
                                    if curTransPos[0] != 2 {
                                        boardNode[curTransPos[0]].remove(at: curTransPos[1])
                                    } else {
                                        storageNode.remove(at: curTransPos[1])
                                    }
                                    
                                }
                                
                                if curIndexArr[0] == 2 { //storageNode
                                    if storageNode.count < GlobalCommonNumber.storageNumber {
                                        storageNode.insert(tempTransParentNode, at: curIndexArr[1])
                                    }
                                } else {
                                    if boardNode[curIndexArr[0]].count < GlobalCommonNumber.chessNumber {
                                        boardNode[curIndexArr[0]].insert(tempTransParentNode, at: curIndexArr[1])
                                    }
                                }
                                
                                
                            }
                            
                        } else {
                            recoverBoardColor()
                        }
                        
                    }
                }
            }
        } else if sender.state == .ended
        {
            let curTransPos = findChessPos(tempTransParentNode) //记录之前透明球体位置
            //
            recoverBoardColor() //放置动作结束 恢复board颜色
            referencePoint.isHidden = true
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
                                            appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: 0)
                                        } else {
                                            appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
                                        }
               
                                } else { //购买失败 放回去
                                    if curDragPos[0] < 2 {
                                        appendNewNodeToBoard(curBoardSide: curDragPos[0], curAddChesses: [curDragPoint!], curInsertIndex: nil)
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

                                    appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
                                
                            }
                        } else if curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue { //已购买

                                    appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
                                
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
                                             appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
                                            return
                                            
                                        }
                                    }
                                    //储藏区来的不需要购买
                                    /*//具有特殊战吼需要选择指定s的棋子
                                     curDragPoint!.abilities.contains(EnumAbilities.instantChooseAnAbilityForMountain.rawValue) ||
                                     curDragPoint!.abilities.contains(EnumAbilities.instantDestroyAllyGainBuff.rawValue)) &&
                                     */
                                    if curDragPoint!.abilities.contains(EnumAbilities.instantChooseAnAbility.rawValue) ||
                                        curDragPoint!.abilities.contains(EnumAbilities.chooseAKind.rawValue)
                                    { //自身进化
                                        removeGestureRecoginzer()
                                        PlayerBoardTextShow(TextContent: EnumString.chooseAnChess.rawValue.localized)
                                        curDragPoint?.isHidden = true //隐藏当前的拖拽棋子 方便选择
                                        self.playerStatues[self.curPlayerId].curChesses = [] //备份当前棋子
                                        self.boardNode[BoardSide.allySide.rawValue].forEach{(curChess) in
                                            self.playerStatues[self.curPlayerId].curChesses.append(curChess)
                                            curChess.removeFromParentNode()
                                        }
                                        self.boardNode[BoardSide.allySide.rawValue] = [] //为我方放置3种类型能力的棋子
                                        //
                                        var abilityOptionChesses:[baseChessNode] = []
                                        if curDragPoint!.abilities.contains(EnumAbilities.instantChooseAnAbility.rawValue) {
                                            let randomAbiArr = randomDiffNumsFromArrs(outputNums: 3, inputArr: EvolveAbilities)
                                            
                                            randomAbiArr.forEach{ (curAbi) in
                                                let newChess = baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: chessStruct(name: curAbi, desc: curAbi, atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1, chessKind: EnumChessKind.mountain.rawValue, abilities: [curAbi], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]))
                                                abilityOptionChesses.append(newChess)
                                            }
                                            
                                        } else if curDragPoint!.abilities.contains(EnumAbilities.chooseAKind.rawValue) {
                                            
                                            EvolveKind.forEach{ (curKind) in
                                                let newChess = baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: chessStruct(name: curKind, desc: curKind, atkNum: 1, defNum: 1, chessRarity: 1, chessLevel: 1, chessKind: curKind, abilities: [], temporaryBuff:[], rattleFunc: [:], inheritFunc: [:]))
                                                abilityOptionChesses.append(newChess)
                                            }
                                        }
                                         appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: abilityOptionChesses, curInsertIndex: nil)
                                        //
                                        curChoosePoint = curDragPoint
                                        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onChooseOptionTap))
                                        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
                                    } else if (
                                            curDragPoint!.abilities.contains(EnumAbilities.instantAddBuff.rawValue) ||
                                            curDragPoint!.abilities.contains(EnumAbilities.instantAddAbility.rawValue)
                                        ) && boardNode[BoardSide.allySide.rawValue].count > 0
                                    { // if chess has INSTANT add buff!!!!
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
                                             appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [newChess], curInsertIndex: nil)
                                            
                                        }
                                        //updateWholeBoardPosition()
                                        //
                                        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onChooseOptionTap))
                                        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
                                        
                                        
                                    } else {//没有特殊的战吼之类的触发 直接放置入 allyboard
                                        if curDragPoint!.abilities.contains(EnumAbilities.instantSummonSth.rawValue) { //战吼召唤
                                            var newAddChesses:[baseChessNode] = []
                                            
                                            if case let curRattleChess as [chessStruct] = curDragPoint?.rattleFunc[EnumKeyName.summonChess.rawValue] {
                                                for sIndex in 0 ..< curRattleChess.count { //appendnewnode里会计算数量 多余的棋子会被砍掉
                                                    newAddChesses.append(baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: curRattleChess[sIndex]))
                                                    //                                                        appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: curRattleChess[sIndex])], curInsertIndex: nil)
                                                }
                                                appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: newAddChesses, curInsertIndex: nil)
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
                                            
                                            
                                        } else if curDragPoint!.abilities.contains(EnumAbilities.instantReduceBuff.rawValue) {
                                            let curBaseAtt = curDragPoint!.rattleFunc[EnumKeyName.baseAttack.rawValue] ?? 1
                                            let curBaseDef = curDragPoint!.rattleFunc[EnumKeyName.baseDef.rawValue] ?? 1
                                            curDragPoint!.AddBuff(AtkNumber: (curBaseAtt as! Int) * boardNode[BoardSide.allySide.rawValue].count, DefNumber: (curBaseDef as! Int) * boardNode[BoardSide.allySide.rawValue].count)
                                            
                                        }
                                        var curInsertIndex:Int? = nil
                                        //将curdragpoint放进去  计算当前落点相对于的距离
                                        if curTransPos != nil && curTransPos![0] == BoardSide.allySide.rawValue {
                                            curInsertIndex = curTransPos![1]
                                        } else {
                                            let curInsertIndex = calInsertPos(curBoardSide: BoardSide.allySide.rawValue, positionOfBoard: curPressLocation)
                                            
                                        }

                                        if curInsertIndex == nil || curInsertIndex! < 0 || curInsertIndex! >= boardNode[BoardSide.allySide.rawValue].count {
                                            appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
                                        } else {
                                            appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: curInsertIndex)
                                        }                                     
                                        
//                                        if curInsertIndex == -1 || curInsertIndex - (GlobalCommonNumber.chessNumber / 2) >= boardNode[BoardSide.allySide.rawValue].count {
//                                              appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
//                                        } else {
//                                            appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: 0)
//                                        }
                                        
                                        
                                        //updateWholeBoardPosition()
                                    }
                                        
                                    
                                } else if curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue { //已购买&&使用
                                        if curDragPoint != nil {
                                            let curInsertIndex = calInsertPos(curBoardSide: BoardSide.allySide.rawValue, positionOfBoard: curPressLocation)
                                            if curInsertIndex == -1 || curInsertIndex - (GlobalCommonNumber.chessNumber / 2) >= boardNode[BoardSide.allySide.rawValue].count {
                                                appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
                                            } else {
                                                appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: 0)
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
                                        appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
                                    } else {
                                        appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: 0)
                                    }
                                    }
                            }
                            //updateWholeBoardPosition()
                        } else if curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue { //已购买放回原位
                           if curDragPos[0] < 2 {
                                appendNewNodeToBoard(curBoardSide: curDragPos[0], curAddChesses: [curDragPoint!], curInsertIndex: nil)
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
                            appendNewNodeToBoard(curBoardSide: curDragPos[0], curAddChesses: [curDragPoint!], curInsertIndex: nil)
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
                                    curChoosePoint?.AddBilities(Abilities: curBaseChess.abilities)
                                } else if curDragPoint!.abilities.contains(EnumAbilities.chooseAKind.rawValue) {
                                    curChoosePoint?.chessKind = curBaseChess.chessKind
                                }
                                
                            } else { //点击点不在
                                sellChess(playerID: curPlayerId, curChess: curDragPoint!, curBoardSide: curDragPos[0])
                                if curDragPos[0] == 0 { //新买的棋子
                                    appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
                                } else if curDragPos[0] == 2 { //储藏区的棋子
                                    appendNewNodeToStorage(curChess: curDragPoint!)
                                }
                                
                                
                            }
                            
                            emptyBoardSide(curBoardSide: BoardSide.allySide.rawValue) //清空棋盘
                            appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: self.playerStatues[self.curPlayerId].curChesses, curInsertIndex: nil)
                            
      
                            ///以下为恢复操作
                            //回复拖拽的棋子到棋盘
                            appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
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
                                    if !curBaseChess.isActive {
                                        return
                                    }
                                    if case let curBaseAtt as Int = curDragPoint?.rattleFunc[EnumKeyName.baseAttack.rawValue] {
                                        if case let curBaseDef as Int = curDragPoint?.rattleFunc[EnumKeyName.baseDef.rawValue] {
                                            curBaseChess.AddBuff(AtkNumber: curDragPoint!.chessLevel * curBaseAtt , DefNumber: curDragPoint!.chessLevel * curBaseDef)
                                        }
                                    }
                                    
                                } else if curDragPoint!.abilities.contains(EnumAbilities.instantAddAbility.rawValue) {
                                    if !curBaseChess.isActive {
                                        return
                                    }
                                    if case let curBaseAbility as String = curDragPoint?.rattleFunc[EnumKeyName.abilityKind.rawValue] {
                                        curBaseChess.AddBilities(Abilities: [curBaseAbility])
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
                                        appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [newChess], curInsertIndex: nil)
                                        
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
                                appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
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
                                    appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
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
                    if gameConfigStr.isMaster {
                        curPlaneNode?.removeFromParentNode()
                        self.initPlayerBoardAndSend(hitTestResult: hitTestResult.first!)
                    } else {
                        if isBoardInfoSent { //如果数据接收到过 则从机可以自由放置
                           self.initPlayerBoardAndSend(hitTestResult: hitTestResult.first!)
                        }
                    }
                } else {
                    //self.addChessTest(hitTestResult: hitTestResult.first!)
                    guard let sceneView = sender.view as? ARSCNView else {return}
                    let touchLocation = sender.location(in: sceneView)
                    let hitTestResult = sceneView.hitTest(touchLocation, options: [SCNHitTestOption.boundingBoxOnly: true, SCNHitTestOption.ignoreHiddenNodes: true])
                    if !hitTestResult.isEmpty {
                        
                        if isNameButton(hitTestResult.first!.node, "randomButton") && !isRandoming {
                            //点击以后randombutton下压
                            isRandoming = true
                            self.randomButtonTopNode.runAction(SCNAction.sequence([
                                SCNAction.move(by: SCNVector3(0,-0.01,0), duration: 0.25),
                                SCNAction.customAction(duration: 0, action: { _,_ in
                                    DispatchQueue.main.async() {
                                        if self.playerStatues[self.curPlayerId].curCoin > 0 && !self.isFreezed {
                                            self.playerStatues[self.curPlayerId].curCoin -= 1
                                            self.initBoardChess(initStage: EnumsGameStage.exchangeStage.rawValue)
                                        }
                                    }
                                    
                                }),
                                SCNAction.move(by: SCNVector3(0,0.01,0), duration: 0.25),
                                SCNAction.customAction(duration: 0, action: { _,_ in
                                    self.isRandoming = false
                                })
                            ]))
                            
                        } else if isNameButton(hitTestResult.first!.node, "upgradeButton") {
                            upgradeButtonTopNode.runAction(SCNAction.sequence([
                                SCNAction.move(by: SCNVector3(0,-0.005,0), duration: 0.25),
                                SCNAction.move(by: SCNVector3(0,0.005,0), duration: 0.25)
                            ]))
                            upgradePlayerLevel(curPlayerId)
                        } else if isNameButton(hitTestResult.first!.node, "endButton") && !isWaiting {
                            //TODO
                            //                            endButtonTopNode.runAction(SCNAction.sequence([
                            //                                SCNAction.move(by: SCNVector3(0,-0.005,0), duration: 0.25)
                            //                            ]))
                            //                            endButtonNode.geometry?.firstMaterial?.diffuse.contents = UIColor.gray //灰显图标
                            //                            isWaiting = true
                            //TODO
                            if(gameConfigStr.isMaster) {
                                for i in 0 ..< currentSlaveId.count {
                                    if currentSlaveId[i].playerID === multipeerSession.getMyId() {
                                        currentSlaveId[i].playerStatus = true //准备完成
                                        break
                                    }
                                }
                                if checkIfAllReady() {
                                    masterArrangeBattles()
                                }
                            } else {
                                if let desId = curMasterID {
                                    let readyStr = "readyBattle"
                                    guard let data = readyStr.data(using: String.Encoding.utf8)
                                        else { fatalError("can't encode anchor") }
                                    multipeerSession.sendToPeer(data, [desId])
                                }
                                
                            }
                            
                        } else if isNameButton(hitTestResult.first!.node, "freezeButton") {
                            if isFreezed {
                                freezeButtonTopNode.runAction(SCNAction.sequence([
                                    SCNAction.move(by: SCNVector3(0,0.005,0), duration: 0.25)
                                ]))
                            } else {
                                freezeButtonTopNode.runAction(SCNAction.sequence([
                                    SCNAction.move(by: SCNVector3(0,-0.005,0), duration: 0.25)
                                ]))
                            }
                            isFreezed = !isFreezed
                        }
                    }
                            
                }
            }
        }
    func masterArrangeBattles() {
        /*主机通知从机切换游戏阶段*/
        if gameConfigStr.isMaster { //主机分配对手信息
            if currentSlaveId != nil {
                if let arrangedArr = randomSplit(arr: currentSlaveId) {
                    arrangedArr.forEach{ twoArr in
                        for i in 0 ..< twoArr.count {
                            var curPlayer = twoArr[i]
                            if curPlayer.playerID == multipeerSession.getMyId()
                            { //如果是主机则继续
                                continue
                            }
                            var oppoPlayer = i == 0 ? twoArr[1] : twoArr[0]
                            if !curPlayer.isComputer { //不是电脑
                                //序列化对手的信息
                                if oppoPlayer.playerID == multipeerSession.getMyId() { //如果是主机就把真实数据发出去 这样二次收到就不用再发了
                                    oppoPlayer.curChesses = playerStatues[0].curChesses
                                }
                                let encodedData = encodeCodablePlayerStruct(playerID: oppoPlayer.playerID!, player: oppoPlayer)
                                let curId = findSimiInstance(arr: multipeerSession.connectedPeers, obj: curPlayer.playerID!)
                                currentSlaveId[i].setPlayerStatus(curStatus: false)
                                multipeerSession.sendToPeer(encodedData, [curId])
                                break
                            } else { //如果是电脑
                               if oppoPlayer.playerID == multipeerSession.getMyId() { //是电脑对手的话 主机直接开打
                                   feedEnemies()
                                   switchGameStage()
                                }
                                if oppoPlayer.isComputer && gameConfigStr.isMaster { //两台都是电脑
                                    let winSide = Int.randomIntNumber(lower: 0, upper: 2)
                                    let winDam = Int.randomIntNumber(lower: 1, upper: 10)
                                    //模拟两方对战结果
                                    
                                    for i in 0 ..< currentSlaveId.count {
                                        if currentSlaveId[i].playerID == twoArr[winSide].playerID {
                                            currentSlaveId[i].curBlood -= winDam
                                        }
                                    }
                                    
                                }
                            }
                        }
                        
                    }
                }


                for i in 0 ..< currentSlaveId.count {//清空玩家准备状态
                    currentSlaveId[i].setPlayerStatus(curStatus: false)
                }
            }
        }
    }
    
    func checkIfAllReady() -> Bool { //检查是否所有人都准备完毕
        if currentSlaveId != nil {
            for i in 0 ..< currentSlaveId.count {
                if !currentSlaveId[i].isComputer && !currentSlaveId[i].playerStatus { //不是电脑 且没准备
                    return false
                }
            }
        }
        return true
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
    /*找到传入的棋子的棋盘和相对index*/
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
    /*插入棋子到指定棋子位置*/
    func insertChessPos(insertChess: baseChessNode, insertTo: baseChessNode) -> Bool{ //仅仅插入数组
        if var inserToPos:[Int] = findChessPos(insertTo) {
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
        return false
    }
    /*购买棋子*/
    func buyChess(playerID: Int, chessPrice: Int) -> Bool{
        let curPlayerMoney = playerStatues[playerID].curCoin
        if curPlayerMoney >= chessPrice {
            playerStatues[playerID].curCoin -= chessPrice
            return true
        }
        return false
    }
    /*出售棋子*/
    func sellChess(playerID: Int, curChess: baseChessNode, curBoardSide: Int) {
        if curChess.abilities.contains(EnumAbilities.customSellValue.rawValue) {
            if case let curValue as Int = curChess.rattleFunc[EnumKeyName.customValue.rawValue]{
                playerStatues[playerID].curCoin += curValue
            } else {
                playerStatues[playerID].curCoin += 1
            }
        } else {
            playerStatues[playerID].curCoin += 1
        }
        curChess.removeFromParentNode()
        
    }

    
    /*****add chess func********/
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
    func initChessWithPos(pos: SCNVector3,sta: Int, chessNode: baseChessNode) -> baseChessNode{
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
     /****end********/
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
//    func insertNewNodeToBoard(curBoardSide:Int,curBoardIndex: Int, curChess: baseChessNode) {
//        if(boardNode[curBoardSide].count < GlobalCommonNumber.chessNumber) {
//            boardNode[curBoardSide].insert(curChess, at: curBoardIndex)
//        }
//    }
    func appendNewNodeToStorage(curChess: baseChessNode) {
        if storageNode.count < GlobalCommonNumber.storageNumber {
            storageNode.append(curChess)
        }
    }
    /*召唤到盟友棋盘*/
//    func summonToAllyBoard(newNode: baseChessNode, curBoardIndex: Int?) {
//
//        //updateWholeBoardPosition()
//    }
    
    /*添加棋子到棋盘*/
    func appendNewNodeToBoard(curBoardSide:Int, curAddChesses: [baseChessNode], curInsertIndex: Int?) {
        for index in 0 ..< curAddChesses.count {
            let curAddChess = curAddChesses[index]
            
            if curAddChess.chessStatus != EnumsChessStage.owned.rawValue { //第一次购买的棋子才生效 战斗产生的衍生物是enemyside也会生效
                var hasSummonAbility:[String : Int] = [:]
                
                boardNode[curBoardSide].forEach{ (curChess) in
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
                        boardNode[BoardSide.allySide.rawValue].forEach{(curChess) in
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
                                if leftIndex >= 0 && leftIndex < boardNode[curBoardSide].count {
                                    boardNode[curBoardSide][leftIndex].AddBuff(AtkNumber: curAddChess.chessLevel * 2, DefNumber: curAddChess.chessLevel * 2)
                                }
                                if rightIndex >= 0 && rightIndex < boardNode[curBoardSide].count {
                                    boardNode[curBoardSide][rightIndex].AddBilities(Abilities: [EnumAbilities.bait.rawValue])
                                }
                            } else { //append
                                boardNode[curBoardSide].last?.AddBuff(AtkNumber: curAddChess.chessLevel * 2, DefNumber: curAddChess.chessLevel * 2)
                            }
                        }
                    }
                }
                
            }
            
        }
        
       
        
        if let curIndex = curInsertIndex {
            if(boardNode[curBoardSide].count < GlobalCommonNumber.chessNumber) {
                boardNode[curBoardSide].insert(contentsOf: curAddChesses, at: curIndex)
            }
        } else {
            if(boardNode[curBoardSide].count < GlobalCommonNumber.chessNumber) {
                boardNode[curBoardSide].append(contentsOf: curAddChesses)
            }
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
            appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curAddChesses: [curDragPoint!], curInsertIndex: nil)
        } else if dragPos[0] == 2{
            if curDragPoint != nil { //storage暂时较少用到 不封装放置方法
                storageNode.append(curDragPoint!)
            }
        }
    }
    func recoverBoardColor() {
        
        if let transPos = findChessPos(tempTransParentNode) {
            if transPos[0] != 2 {
                boardNode[transPos[0]].remove(at: transPos[1])
            } else {
                storageNode.remove(at: transPos[1])
            }
        }
        
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
    func returnExactPos(boardSide:Int, chessIndex: Int) -> SCNVector3?{ //计算所在棋盘位置的坐标 不包括storagenode
        if (boardSide > boardRootNode.count || chessIndex > boardRootNode[boardSide].count) {
            return nil
        }
        let startIndex = (GlobalNumberSettings.chessNumber.rawValue - boardNode[boardSide].count) / 2
        let curRootNode = boardRootNode[boardSide][chessIndex + startIndex]
        return SCNVector3(curRootNode.position.x, curRootNode.position.y + 0.01 , curRootNode.position.z)
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
            //var attackerActions: [SCNAction] = []
            var actionPromiseArr:[() -> (Promise<Double>)] = []
            
            
            if attackResult[0] == 0 || attackResult[1] == 0{ //触发亡语
                actionPromiseArr.append({() in
                    return Promise<Double>(resolver: {(resolver) in
                        self.updatePromise = resolver
                    })
                })
            }
            
            /*进行计算移除被干掉的棋子*/
            if attackResult[0] == 0 { //attacker eliminated
                self.boardNode[attackBoardIndex].remove(at: attackIndex)
            }
            if attackResult[1] == 0 { //victim elinminated
                self.boardNode[victimBoardIndex].remove(at: victimIndex)
            }
            
           
            
            /*非亡语结算*/
            for curSide in 0 ... 1 { //0为攻击者 1为防守方
                let curBoardSide = curSide == 0 ? attackBoardIndex : victimBoardIndex
                let curChessPoint = curSide == 0 ? attacker : victim
                let oppositeSide = curSide == 0 ? victimBoardIndex : attackBoardIndex
                let curChessIndex = curSide == 0 ? attackIndex : victimIndex
                //
                if curSide == 0 && attackResult[curSide] != 0 { //仅攻击方生效
                    if attacker.abilities.contains(EnumAbilities.afterAttackAoe.rawValue) {
                        let curBaseDam = attacker.rattleFunc[EnumKeyName.baseDamage.rawValue] ?? 1
                        actionPromiseArr.append({() in
                            return self.aoeDamagePromise(practicleName: "particals.scnassets/lightning.scnp", boardSide: victimBoardIndex, damageNum: curBaseDam as! Int * attacker.chessLevel)
                        })
                    }
                    
                    if curChessPoint.abilities.contains(EnumAbilities.liveInGroup.rawValue) && self.boardNode[curBoardSide].count < GlobalCommonNumber.chessNumber { // <7
                        let randomNumber = Int.randomIntNumber(lower: 0, upper: 10) //0-9
                        //if randomNumber < 2 * victim.chessLevel { //20% 40% 60% attacker
                        let copyChess = baseChessNode(statusNum: EnumsChessStage.owned.rawValue, chessInfo: chessStruct(
                            name: attacker.chessName, desc: "", atkNum: attacker.atkNum!, defNum: attacker.defNum!, chessRarity: attacker.chessRarity, chessLevel: attacker.chessLevel, chessKind: attacker.chessKind, abilities: [], temporaryBuff: [], rattleFunc: [:], inheritFunc: [:]
                        ))
                        if let curAttIndex = self.boardNode[curBoardSide].index(of: attacker) {
                            actionPromiseArr.append({() in
                                return Promise<Double>(resolver: {(resolver) in
                                    self.appendNewNodeToBoard(curBoardSide: curBoardSide, curAddChesses: [copyChess], curInsertIndex: curAttIndex + 1)
                                    delay(self.totalUpdateTime, task: {
                                        resolver.fulfill(self.totalUpdateTime)
                                    })
                                })
                            })
                            
                        }
                    }
                }
            }
            
           
            
            // resolve promise
            recyclePromise(taskArr: actionPromiseArr, curIndex: 0).done({ _ in 
                resolver.fulfill(attackResult)
            }).catch({ err in
                print("updateInherit", err)
            })
            
            //attacker.runAction(SCNAction.sequence(attackerActions))
            
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
            return self.addnewchess()
        }.then { (res: (Bool)) in
            // 如果攻击动作完成了
            return self.addnewchess()
        }.done{ (res) in
            self.addnewchess()
        }.catch { (err)  in
            print("aRoundTaskAsyncTempError")
        }
    }
    
    func aRoundTaskAsyncTemp(_ attSide: Int, _ resolver: Resolver<Any>, _ changeRound: Bool?) {

        var curIndex = findIndexOfFirstAttack(curBoard: self.boardNode[attSide])
        
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
            
            let attacker = self.boardNode[attSide][curIndex] //攻击者
            
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
               
                var shouldChange = changeRound  //是否强制下回合不更新indexs
                if res[0] != 0 && attacker.abilities.contains(EnumAbilities.rapid.rawValue) && shouldChange != true {
                    //index不动
                    attacker.abilityTrigger(abilityEnum: EnumAbilities.rapid.rawValue)
                    nextSide = attSide //维持攻击棋盘index
                    shouldChange = true
                } else {
                    if res[0] == 0{ //attacker eliminated
                        //index不动
                    }
                }
                
                if self.boardNode[attSide].count > 0 && self.boardNode[nextSide].count > 0 {
                    self.aRoundTaskAsyncTemp(nextSide, resolver, shouldChange)
                } else {
                    resolver.fulfill("success")
                }
                
                
            }.catch { (err)  in
                // self.loginProto(loginInfo: loginInfo)和self.loginDeal(res: res) 包装的两个promise执行了resolver.reject(),就会执行此代码段
                print("aRoundTaskAsyncTempError", err)
            }
        } else if boardNode[attSide].count > 0 && boardNode[nextSide].count > 0 { //还有棋子 但是index到底了
            self.boardNode[attSide].forEach{ curC in
                curC.recoverAttackTimes() //恢复攻击频率
            }
            self.aRoundTaskAsyncTemp(attSide, resolver, nil)//从头开始
        } else {
            resolver.fulfill("success")
        }
        
    }

 
    
    
    func dealWithDamage() -> Promise<Bool>{ //伤害清算
        return Promise<Bool>( resolver: { (resolver) in
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
            if gameConfigStr.isMaster { //如果是主机
                for i in 0 ..< currentSlaveId.count {
                    if currentSlaveId[i].curBlood > 0 && currentSlaveId[i].playerID != multipeerSession.getMyId() {
                        break
                    }
                    if i == currentSlaveId.count - 1
                    {
                       winTheGame()
                    }
                }
            } else { //如果是从机 发送给主机
                guard let idData = try? NSKeyedArchiver.archivedData(withRootObject: multipeerSession.getMyId(), requiringSecureCoding: true)
                else { fatalError("can't encode!") }
                let tempStatus = codblePlayerStruct(playerName: playerStatues[0].playerName, curCoin: playerStatues[0].curCoin, curLevel: playerStatues[0].curLevel, curBlood: playerStatues[0].curBlood, curChesses: [], curAura: [], isComputer: playerStatues[0].isComputer, encodePlayerID: idData)
                 let encoder = JSONEncoder()
                guard let encodedData = try? encoder.encode(tempStatus)
                else { fatalError("can't encode player struct!") }
                if let curId = findSimiInstance(arr: multipeerSession.connectedPeers, obj: curMasterID) {
                   multipeerSession.sendToPeer(encodedData, [curId])
                }
            }
            
            if (playerStatues[curPlayerId].curBlood <= 0) {
             resolver.fulfill(false)
            } else {
             resolver.fulfill(true)
            }
        }
        )
    }
    func beginRounds() -> Promise<Any>{ //当前默认是敌人方进行攻击 后续调整
       // while boardNode[0].count > 0 && boardNode[1].count > 0 {
        return Promise<Any>(resolver: { (resolver) in
           var beginIndex = [0, 0]
           var randomSide = Int.randomIntNumber(lower: 0, upper: 2)
           aRoundTaskAsyncTemp(randomSide, resolver, nil)
            })
//            var beginIndex = 0
//            aRoundTask(&beginIndex)
       // }
    }
    
    @IBAction func resetPlayboard(_ sender: Any) { //清除底座
        isPlayerBoardinited = false
        playerBoardNode.removeFromParentNode()
    
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
                    //let curBoard = self.boardNode[BoardSide.allySide.rawValue]
                    let curChess = self.boardNode[BoardSide.allySide.rawValue][index]
                    if curChess.abilities.contains(EnumAbilities.endRoundAddBuff.rawValue) {
                        if case let curEndKindMap as [String : Int] = curChess.rattleFunc[EnumKeyName.baseKind.rawValue] {
                            
                            let curEndAtt = curChess.rattleFunc[EnumKeyName.baseAttack.rawValue] ?? 1
                            let curEndDef = curChess.rattleFunc[EnumKeyName.baseDef.rawValue] ?? 1
                            
                            var curChessesKindMap:[String : [Int]] = [:]
                            
                            for innerIndex in 0 ..< self.boardNode[BoardSide.allySide.rawValue].count {
                                let curInnerChess = self.boardNode[BoardSide.allySide.rawValue][innerIndex]
                                if innerIndex != index {
                                    if curChessesKindMap[curInnerChess.chessKind] == nil {
                                        curChessesKindMap[curInnerChess.chessKind] = [innerIndex]
                                    } else {
                                        curChessesKindMap[curInnerChess.chessKind]?.append(innerIndex)
                                    }
//                                    curInnerChess.AddBuff(AtkNumber: 1, DefNumber: 1) //当前hard code +1 /+1
                                }
                            }
                            
                            
                            
                            for (curChessKind, curKindNum) in curEndKindMap {
                                let randomIndex = randomDiffNumsFromArrs(outputNums: curKindNum, inputArr: curChessesKindMap[curChessKind] ?? [])
                                randomIndex.forEach{(curRandomIndex) in
                                    self.boardNode[BoardSide.allySide.rawValue][curRandomIndex].AddBuff(AtkNumber: curEndAtt as? Int, DefNumber: curEndDef as? Int)
                                }
                            }
                            
                            
                            
                            
                        } else {
                            if case let isSelf as Bool = curChess.rattleFunc[EnumKeyName.isSelf.rawValue]{ //直接对自身作用
                                let curEndAtt = curChess.rattleFunc[EnumKeyName.baseAttack.rawValue] ?? 1
                                let curEndDef = curChess.rattleFunc[EnumKeyName.baseDef.rawValue] ?? 1
                                
                                curChess.AddBuff(AtkNumber: curEndAtt as? Int, DefNumber: curEndDef as? Int)
                            }
                        }
                        curChess.abilityTrigger(abilityEnum: EnumAbilities.endRoundAddBuff.rawValue.localized)
                    }
                }
                //
                //let actionTime = self.updateWholeBoardPosition()
                totalTime += self.totalUpdateTime
                //
                //copy the backup data
                self.playerStatues[self.curPlayerId].curChesses = []
                self.boardNode[BoardSide.allySide.rawValue].forEach{(curChess) in
                    self.playerStatues[self.curPlayerId].curChesses.append(curChess.copyable())
                }
                if self.isFreezed {
                    self.freezedChessNodes = []
                    self.boardNode[BoardSide.enemySide.rawValue].forEach{(curChess) in
                        self.freezedChessNodes.append(curChess.copyable())
                    }
                }
                //playerStatues[curPlayerId].curChesses = boardNode[1]
                delay(0.5 + totalTime) { //初始化大屏幕和棋盘棋子
                    self.initBoardChess(initStage: EnumsGameStage.battleStage.rawValue)
                    self.curStage = EnumsGameStage.battleStage.rawValue
                    self.initDisplay()
                    delay(self.totalUpdateTime) { //初始化光环
                        self.initAura().done{ (delaytime) in
                            self.initEnemyAura().done{(eTime) in
                                self.initBeforeBattle().done{ (beforeBattleTime) in
                                    /*开始战斗*/
                                    self.beginRounds().done { (v1) in
                                        self.dealWithDamage().done { (isAlive) in
                                            //if case let isAlive = res as! Bool {
                                                if isAlive {
                                                    self.switchGameStage()
                                                } else {
                                                    //棋盘爆炸
                                                    let removeSequence : [SCNAction] = [SCNAction.fadeOut(duration: 0.5), SCNAction.removeFromParentNode()]
                                                    addExplosion(self.playerBoardNode)
                                                    self.playerBoardNode.runAction(SCNAction.sequence(removeSequence))
                                                    let endtextNode = TextNode(textScale: SCNVector3(0.1,0.1,0.01))
                                                    endtextNode.position = self.playerBoardNode.position
                                                    endtextNode.position.y -= 0.1
                                                    endtextNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                                                    endtextNode.string = "waste".localized
                                                    self.sceneView.scene.rootNode.addChildNode(endtextNode)
                                                    let rotateAction = SCNAction.rotateBy(x: 0, y: 10, z: 0, duration: 5)
                                                    endtextNode.runAction(SCNAction.repeatForever(rotateAction))
                                                }
                                           // }
                                            
                                        } //伤害清算
                                    }
                                }
                            }
                        }
                        
                    }
                   
                }
            }
        } else if curStage == EnumsGameStage.battleStage.rawValue { //战斗转交易
            curUpgradeCoin -= 1 //升级费用减1
            //恢复结束按钮
            isWaiting = false
            endButtonTopNode.geometry?.firstMaterial?.diffuse.contents = UIColor.black
            endButtonTopNode.runAction(SCNAction.sequence([
                SCNAction.move(by: SCNVector3(0,0.005,0), duration: 0)
            ]))
            let delayTime = PlayerBoardTextAppear(TextContent: "ExchangeStage".localized) //弹出切换回合提示
            delay(delayTime){
                let lastChesses = copyChessArr(curBoard: self.playerStatues[self.curPlayerId].curChesses) //拷贝上轮阵容 防止切换模式清空
                self.recoverButtons()
                self.curStage = EnumsGameStage.exchangeStage.rawValue
                self.boardNode[1].forEach{(curChess) in
                    curChess.removeFromParentNode()
                }
                self.boardNode[1] = []
                lastChesses.forEach{(curChess) in
                    self.boardNode[1].append(curChess.copyable())
                }
                
                self.initDisplay()
                
                if !self.isFreezed {
                   self.initBoardChess(initStage: EnumsGameStage.exchangeStage.rawValue)
                } else {
                    self.boardNode[0] = []
                    self.freezedChessNodes.forEach{(curChess) in
                        self.boardNode[0].append(curChess.copyable())
                    }
                }
                
               
            }
        }
        //here update every players info, if there'll be multiplayers mode, you should get other players info, and then update to the playerStatues array
        //now we only update current player
        
    }
    func upgradePlayerLevel(_ playerID: Int) -> Bool{
        let playerInfo = playerStatues[playerID]
        if playerInfo.curCoin - curUpgradeCoin > 0 && playerInfo.curLevel < GlobalNumberSettings.maxLevel.rawValue {
            playerStatues[playerID].curCoin -= curUpgradeCoin
            playerStatues[playerID].curLevel += 1
            if playerStatues[playerID].curLevel >= GlobalNumberSettings.maxLevel.rawValue {
                priceTagNode.isHidden = true
            } else {
               curUpgradeCoin = 5 + (playerStatues[playerID].curLevel - 1) * 2
            }
        } else {
            return false
        }
        return true
    }
    func feedEnemies() {
        var tempArr:[baseChessNode] = []
        dummyAICrew[curRound].forEach{ curStr in
            tempArr.append(baseChessNode(statusNum: EnumsChessStage.enemySide.rawValue, chessInfo: curStr))
        }
        playerStatues[1].curChesses = tempArr
    }
    func getRandomChessStructFromPool(_ curLevel : Int) -> chessStruct { //不可能出现所有都小于等于0的情况 出现了就直接用现有的
        var randomLevel = Int.randomIntNumber(lower: 1, upper: curLevel + 1)
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
    func initBoardChess(initStage: Int) {
//        boardNode[0].forEach{(boardNode) in
//            boardNode.removeFromParentNode()
//        }
        boardNode[0] = []
        let curPlayerLevel = playerStatues[curPlayerId].curLevel
        
        switch initStage {
        case EnumsGameStage.exchangeStage.rawValue:
            let curSaleNumber = 3//playerStatues[curPlayerId].curLevel + 2
            let curStartIndex = (GlobalNumberSettings.chessNumber.rawValue - curSaleNumber) / 2
            var tempArr:[baseChessNode] = []
            for index in 0 ..< curSaleNumber  {
                let curNode = boardRootNode[0][index + curStartIndex]        
                let randomStruct =  getRandomChessStructFromPool(curPlayerLevel)
                //let tempChess = initChessWithPos(pos: curNode.position, sta: EnumsChessStage.forSale.rawValue, info: randomStruct)
                let tempChess = baseChessNode(statusNum: EnumsChessStage.forSale.rawValue, chessInfo: randomStruct)
                tempChess.position = curNode.position
                tempArr.append(tempChess)
            }
            appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curAddChesses: tempArr, curInsertIndex: nil)
            return
        case EnumsGameStage.battleStage.rawValue:
            var enemies:[baseChessNode] = []
            playerStatues[1].curChesses.forEach{(curChess) in
                enemies.append(curChess.copyable())
            }
             if enemies.count > GlobalNumberSettings.chessNumber.rawValue {
                return
             }
             //let curStartIndex = (GlobalNumberSettings.chessNumber.rawValue - enemies.count) / 2
            appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curAddChesses: enemies, curInsertIndex: nil)
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
 
    
    //recyle run promise
    func recyclePromise(taskArr: [() -> (Promise<Double>)], curIndex: Int) -> Promise<Double>{
       return Promise<Double>(resolver: { (res) in
        let timeDelay:Double = 1
        if(curIndex < taskArr.count) {
            let curTask = taskArr[curIndex]
            curTask().done({ _ in
                print("task done", curIndex)
                if(curIndex + 1 < taskArr.count) {
                    self.recyclePromise(taskArr: taskArr, curIndex: curIndex + 1).done({ _ in
                        res.fulfill(timeDelay)
                    })
                } else {
                    res.fulfill(timeDelay)
                }
            }).catch({ err in
                print("recyclePromise", err)
            })
        } else {
             res.fulfill(timeDelay)
        }
      })
    }
    
    
    
    //damage frame promise
    func aoeDamagePromise(practicleName: String, boardSide: Int, damageNum: Int) -> Promise<Double>{
        return Promise<Double>(resolver: { (res) in
             let aoeActionTime = self.eelDamageAction(practicleName: practicleName, boardSide: boardSide)
            delay(aoeActionTime, task: {
                self.boardNode[boardSide].forEach{ (curChess) in
                    curChess.getDamage(damageNumber: damageNum, chessBoard: &self.boardNode[boardSide])
                }
                delay(1, task: {
                     print("aoe done!!!")
                    res.fulfill(aoeActionTime + 1)
                   
                })
            })
            })
    }
    
    
    //BeforeBattle action
    func beforeBattleAction(startBoardIndex: Int) -> Promise<Double>{
        return Promise<Double>(resolver: { (resole) in
            var actionTime:Double = 0
            var hasStealAura = false //是否有偷取光环的手段
            let curBoard = boardNode[startBoardIndex]
            let oppoBoardIndex = startBoardIndex == BoardSide.enemySide.rawValue ? BoardSide.allySide.rawValue : BoardSide.enemySide.rawValue
            var chessKindMap:[String : Int] = [:]
            var beforeActionSequence:[SCNAction] = []
            var funcArr:[() -> (Promise<Double>)] = []
              for innerIndex in 0 ..< curBoard.count {
                  let curChess = curBoard[innerIndex]
                  if curChess.abilities.contains(EnumAbilities.beforeAttackAoe.rawValue) { //如果有攻击前群体aoe
                      let curBaseDamage = curChess.rattleFunc[EnumKeyName.baseDamage.rawValue] ?? 1
                    funcArr.append({() in
                         return self.aoeDamagePromise(practicleName: "particals.scnassets/lightning.scnp", boardSide: oppoBoardIndex, damageNum: curBaseDamage as! Int * curChess.chessLevel)
                        })
                     
            
                  }
                  if curChess.abilities.contains(EnumAbilities.stealAura.rawValue) { //偷取光环
                    //curChess.abilityTrigger(abilityEnum: EnumAbilities.stealAura.rawValue.localized)
                    hasStealAura = true
                   }
                  //ocean aura map
                  if chessKindMap[curChess.chessKind] != nil {
                      chessKindMap[curChess.chessKind]! += 1
                  } else {
                      chessKindMap[curChess.chessKind] = 1
                  }
              }
             //如果有偷取光环的话
            var oppoChessKindMap:[String : Int] = [:]
            if (hasStealAura) {
                for innerIndex in 0 ..< boardNode[oppoBoardIndex].count {
                      let curChess = boardNode[oppoBoardIndex][innerIndex]
                      //ocean aura map
                      if oppoChessKindMap[curChess.chessKind] != nil {
                          oppoChessKindMap[curChess.chessKind]! += 1
                      } else {
                          oppoChessKindMap[curChess.chessKind] = 1
                      }
                  }
            }
            //calculate chess kind map
              if let oceanNum = chessKindMap[EnumChessKind.ocean.rawValue] {
                  let oppoOceanNum = oppoChessKindMap[EnumChessKind.ocean.rawValue] ?? 0
                  if oceanNum >= 3 && oceanNum < 6 { //oceanlevel1
                    if oppoOceanNum >= 6 { //如果偷取的光环效果更好就用偷取的
                        funcArr.append({() in
                            return self.aoeDamagePromise(practicleName: "particals.scnassets/oceanaura.scnp", boardSide: oppoBoardIndex, damageNum: 4)
                        })
                    } else { //oceanlevel1
                        funcArr.append({() in
                            return self.aoeDamagePromise(practicleName: "particals.scnassets/oceanaura.scnp", boardSide: oppoBoardIndex, damageNum: 1)
                        })
                    }
                  } else if oceanNum >= 6 { //oceanlevel2
                    funcArr.append({() in
                        return self.aoeDamagePromise(practicleName: "particals.scnassets/oceanaura.scnp", boardSide: oppoBoardIndex, damageNum: 4)
                    })
                        
                  }
              } else {
                let oppoOceanNum = oppoChessKindMap[EnumChessKind.ocean.rawValue] ?? 0
                if oppoOceanNum >= 6 { //oceanlevel1
                  funcArr.append({() in
                      return self.aoeDamagePromise(practicleName: "particals.scnassets/oceanaura.scnp", boardSide: oppoBoardIndex, damageNum: 1)
                  })
                } else if oppoOceanNum >= 3 { //oceanlevel2
                  funcArr.append({() in
                      return self.aoeDamagePromise(practicleName: "particals.scnassets/oceanaura.scnp", boardSide: oppoBoardIndex, damageNum: 4)
                  })
                      
                }
              }
           
              
            
            recyclePromise(taskArr: funcArr, curIndex: 0).done({ _ in
                resole.fulfill(actionTime)
            })
//             when(fulfilled: funcArr).done({ _ in
//                resole.fulfill(actionTime)
//                 }).catch({ err in
//                     print(err)
//                 })


        })
    }
    
    
    
    func initBeforeBattle() -> Promise<Double> {
        return Promise<Double>(resolver: { (resole) in
            
            let startBoardIndex = Int.randomIntNumber(lower: 0, upper: 2)
            let oppoBoardIndex = startBoardIndex == BoardSide.enemySide.rawValue ? BoardSide.allySide.rawValue : BoardSide.enemySide.rawValue
            let extraTimePromise = beforeBattleAction(startBoardIndex: startBoardIndex)
            
            extraTimePromise.done({ actionTime in
                self.beforeBattleAction(startBoardIndex: oppoBoardIndex).done({ secondActionTime in
                    resole.fulfill(actionTime + secondActionTime)
                })
                }).catch({ err in
                    print("ininitBeforeBattle", err)
                })
        })

    }
    
    func calculateAura(curChessBoard: [baseChessNode]) -> [String]{ //计算传入棋盘有没有光环
        var chessKindMap:[String : Int] = [:]
        var curAuraArr:[String] = []
        curChessBoard.forEach({ curChess in
            if chessKindMap[curChess.chessKind] != nil {
                chessKindMap[curChess.chessKind]! += 1
            } else {
                chessKindMap[curChess.chessKind] = 1
            }
        })
        if let mountainNum = chessKindMap[EnumChessKind.mountain.rawValue]{
            if mountainNum >= 6{
                curAuraArr.append(EnumAuraName.mountainLevel2.rawValue)
            } else if mountainNum >= 3 {
                curAuraArr.append(EnumAuraName.mountainLevel1.rawValue)
            }
        }
        if let oceanNum = chessKindMap[EnumChessKind.ocean.rawValue]{
            if oceanNum >= 6{
                curAuraArr.append(EnumAuraName.oceanLevel2.rawValue)
            } else if oceanNum >= 3 {
                curAuraArr.append(EnumAuraName.oceanLevel1.rawValue)
            }
        }
        if let plainNum = chessKindMap[EnumChessKind.plain.rawValue]{
            if plainNum >= 6{
                curAuraArr.append(EnumAuraName.plainLevel2.rawValue)
            } else if plainNum >= 3 {
                curAuraArr.append(EnumAuraName.plainLevel1.rawValue)
            }
        }
        return curAuraArr
    }
    
    
    
    func initEnemyAura() -> Promise<Double>{
        return Promise<Double>(resolver: {(resolver) in
            var actionTime:Double = 0
            
            var enemyAura = calculateAura(curChessBoard: boardNode[BoardSide.enemySide.rawValue])
            playerStatues[curEnemyId].curAura = enemyAura //赋值光环
            
            var hasStealAura = false
            
            boardNode[BoardSide.enemySide.rawValue].forEach{ (curChess) in
                if curChess.abilities.contains(EnumAbilities.stealAura.rawValue) { //有偷aura技能
                    curChess.abilityTrigger(abilityEnum: EnumAbilities.stealAura.rawValue)
                    hasStealAura = true
                }
            }
            
            
            
            var oppoAura:[String] = []
            
            if hasStealAura {
                oppoAura = calculateAura(curChessBoard: boardNode[BoardSide.allySide.rawValue]) //重新计算 不然会把偷的也算进去
            }
            
            /*mountainaura*/
            if enemyAura.contains(EnumAuraName.mountainLevel1.rawValue) {
                actionTime += 0.5
                if oppoAura.contains(EnumAuraName.mountainLevel2.rawValue) {
                    boardNode[BoardSide.enemySide.rawValue].forEach{ (curChess) in
                        curChess.AddBuff(AtkNumber: 6 * curChess.chessLevel, DefNumber: 6 * curChess.chessLevel)
                    }
                } else {
                    boardNode[BoardSide.enemySide.rawValue].forEach{ (curChess) in
                        curChess.AddBuff(AtkNumber: 2 * curChess.chessLevel, DefNumber: 2 * curChess.chessLevel)
                    }
                }
            } else if enemyAura.contains(EnumAuraName.mountainLevel2.rawValue) {
                actionTime += 0.5
                boardNode[BoardSide.enemySide.rawValue].forEach{ (curChess) in
                    curChess.AddBuff(AtkNumber: 6 * curChess.chessLevel, DefNumber: 6 * curChess.chessLevel)
                }
            } else {
                if oppoAura.contains(EnumAuraName.mountainLevel1.rawValue) {
                    boardNode[BoardSide.enemySide.rawValue].forEach{ (curChess) in
                        curChess.AddBuff(AtkNumber: 2 * curChess.chessLevel, DefNumber: 2 * curChess.chessLevel)
                    }
                } else if oppoAura.contains(EnumAuraName.mountainLevel2.rawValue) {
                    boardNode[BoardSide.enemySide.rawValue].forEach{ (curChess) in
                        curChess.AddBuff(AtkNumber: 6 * curChess.chessLevel, DefNumber: 6 * curChess.chessLevel)
                    }
                }
            }
            
            
            
            /*plain aura*/
            if enemyAura.contains(EnumAuraName.plainLevel1.rawValue) {
                actionTime += 0.5
                if oppoAura.contains(EnumAuraName.plainLevel2.rawValue) {
                    boardNode[BoardSide.enemySide.rawValue].forEach{ (curChess) in
                            curChess.AddTempBuff(tempBuff: [EnumAbilities.shell.rawValue])
                    }
                } else {
                    boardNode[BoardSide.enemySide.rawValue].forEach{ (curChess) in
                        if curChess.chessKind == EnumChessKind.plain.rawValue {
                            curChess.AddTempBuff(tempBuff: [EnumAbilities.shell.rawValue])
                        }
                    }
                }
            } else if enemyAura.contains(EnumAuraName.plainLevel2.rawValue) {
                actionTime += 0.5
                boardNode[BoardSide.enemySide.rawValue].forEach{ (curChess) in
                        curChess.AddTempBuff(tempBuff: [EnumAbilities.shell.rawValue])
                }
            } else {
                if oppoAura.contains(EnumAuraName.plainLevel1.rawValue) {
                    boardNode[BoardSide.enemySide.rawValue].forEach{ (curChess) in
                       if curChess.chessKind == EnumChessKind.plain.rawValue {
                            curChess.AddTempBuff(tempBuff: [EnumAbilities.shell.rawValue])
                        }
                    }
                } else if oppoAura.contains(EnumAuraName.plainLevel2.rawValue) {
                    boardNode[BoardSide.enemySide.rawValue].forEach{ (curChess) in
                            curChess.AddTempBuff(tempBuff: [EnumAbilities.shell.rawValue])
                    }
                }
            }
            
            /*ocean aura*/
            if enemyAura.contains(EnumAuraName.oceanLevel1.rawValue) { //mountain1 所有棋子获得 +2 * chesslevel / +2 * chesslevel
                if oppoAura.contains(EnumAuraName.oceanLevel2.rawValue) {
                    if let i = enemyAura.firstIndex(of: EnumAuraName.oceanLevel1.rawValue) {
                        playerStatues[curEnemyId].curAura[i] = EnumAuraName.oceanLevel2.rawValue
                    }
                }
            } else if !enemyAura.contains(EnumAuraName.oceanLevel2.rawValue){ //既没有1也没有2
                if oppoAura.contains(EnumAuraName.oceanLevel1.rawValue) {
                    playerStatues[curEnemyId].curAura.append(EnumAuraName.oceanLevel1.rawValue)
                } else if oppoAura.contains(EnumAuraName.oceanLevel2.rawValue) {
                    playerStatues[curEnemyId].curAura.append(EnumAuraName.oceanLevel2.rawValue)
                }
            }
            delay(actionTime, task: {
                resolver.fulfill(actionTime)
            })
            
        })
    }
    
    
    /*初始化光环*/
    func initAura() -> Promise<Double>{
        
        return Promise<Double>(resolver: { (resolver) in
            var actionTime:Double = 0.5
            let curPlayerAura = playerStatues[curPlayerId].curAura //本方aura
            var hasStealAura = false
            
            boardNode[BoardSide.allySide.rawValue].forEach{ (curChess) in
                if curChess.abilities.contains(EnumAbilities.stealAura.rawValue) { //有偷aura技能
                    curChess.abilityTrigger(abilityEnum: EnumAbilities.stealAura.rawValue)
                   hasStealAura = true
                }
            }
            
            var curEnemyAura:[String] = []
            if hasStealAura {
                curEnemyAura = calculateAura(curChessBoard: boardNode[BoardSide.enemySide.rawValue])
            }
            
            
            /*mountain aura*/
            if curPlayerAura.contains(EnumAuraName.mountainLevel1.rawValue) { //mountain1 所有棋子获得 +2 * chesslevel / +2 * chesslevel
                actionTime += 0.5
                if curEnemyAura.contains(EnumAuraName.mountainLevel2.rawValue) {
                    boardNode[BoardSide.allySide.rawValue].forEach{ (curChess) in
                        curChess.AddBuff(AtkNumber: 6 * curChess.chessLevel, DefNumber: 6 * curChess.chessLevel)
                    }
                } else {
                    boardNode[BoardSide.allySide.rawValue].forEach{ (curChess) in
                        curChess.AddBuff(AtkNumber: 2 * curChess.chessLevel, DefNumber: 2 * curChess.chessLevel)
                    }
                }
            } else if curPlayerAura.contains(EnumAuraName.mountainLevel2.rawValue) { //mountain1 所有棋子获得 +4 * chesslevel / +4 * chesslevel
                actionTime += 0.5
                boardNode[BoardSide.allySide.rawValue].forEach{ (curChess) in
                    curChess.AddBuff(AtkNumber: 6 * curChess.chessLevel, DefNumber: 6 * curChess.chessLevel)
                }
            } else { //如果没有aura 看一下有没有偷到对面的aura
                if curEnemyAura.contains(EnumAuraName.mountainLevel1.rawValue) {
                    actionTime += 0.5
                    boardNode[BoardSide.allySide.rawValue].forEach{ (curChess) in
                        curChess.AddBuff(AtkNumber: 2 * curChess.chessLevel, DefNumber: 2 * curChess.chessLevel)
                    }
                } else if curEnemyAura.contains(EnumAuraName.mountainLevel2.rawValue) {
                    actionTime += 0.5
                    boardNode[BoardSide.allySide.rawValue].forEach{ (curChess) in
                        curChess.AddBuff(AtkNumber: 6 * curChess.chessLevel, DefNumber: 6 * curChess.chessLevel)
                    }
                }
            }
            /*plain aura*/
            if curPlayerAura.contains(EnumAuraName.plainLevel1.rawValue) { //mountain1 所有棋子获得 +2 * chesslevel / +2 * chesslevel
                actionTime += 0.5
                if curEnemyAura.contains(EnumAuraName.plainLevel2.rawValue) {
                    boardNode[BoardSide.allySide.rawValue].forEach{ (curChess) in
                        curChess.AddTempBuff(tempBuff: [EnumAbilities.shell.rawValue])
                    }
                } else {
                    boardNode[BoardSide.allySide.rawValue].forEach{ (curChess) in
                        if curChess.chessKind == EnumChessKind.plain.rawValue {
                          curChess.AddTempBuff(tempBuff: [EnumAbilities.shell.rawValue])
                        }
                    }
                }
            } else if curPlayerAura.contains(EnumAuraName.plainLevel2.rawValue) { //mountain1 所有棋子获得 +4 * chesslevel / +4 * chesslevel
                actionTime += 0.5
                boardNode[BoardSide.allySide.rawValue].forEach{ (curChess) in
                   curChess.AddTempBuff(tempBuff: [EnumAbilities.shell.rawValue])
                }
            } else {//如果没有aura 看一下有没有偷到对面的aura
                if curEnemyAura.contains(EnumAuraName.plainLevel1.rawValue) {
                    actionTime += 0.5
                    boardNode[BoardSide.allySide.rawValue].forEach{ (curChess) in
                       if curChess.chessKind == EnumChessKind.plain.rawValue {
                          curChess.AddTempBuff(tempBuff: [EnumAbilities.shell.rawValue])
                        }
                    }
                } else if curEnemyAura.contains(EnumAuraName.plainLevel2.rawValue) {
                    actionTime += 0.5
                    boardNode[BoardSide.allySide.rawValue].forEach{ (curChess) in
                        curChess.AddTempBuff(tempBuff: [EnumAbilities.shell.rawValue])
                    }
                }
            }
            
            
            if curPlayerAura.contains(EnumAuraName.oceanLevel1.rawValue) { //mountain1 所有棋子获得 +2 * chesslevel / +2 * chesslevel
                actionTime += 0.5
                if curEnemyAura.contains(EnumAuraName.oceanLevel2.rawValue) {
                    if let i = curPlayerAura.firstIndex(of: EnumAuraName.oceanLevel1.rawValue) {
                        playerStatues[curPlayerId].curAura[i] = EnumAuraName.oceanLevel2.rawValue
                    }
                }
            } else if !curPlayerAura.contains(EnumAuraName.oceanLevel2.rawValue){ //既没有1也没有2
                if curEnemyAura.contains(EnumAuraName.oceanLevel1.rawValue) {
                    playerStatues[curPlayerId].curAura.append(EnumAuraName.oceanLevel1.rawValue)
                } else if curEnemyAura.contains(EnumAuraName.oceanLevel2.rawValue) {
                    playerStatues[curPlayerId].curAura.append(EnumAuraName.oceanLevel2.rawValue)
                }
            }

            
            delay(actionTime, task: {
                resolver.fulfill(actionTime)
            })
            
        })
        
    }
    
    
    /*初始化大屏幕*/
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
    //
    public func abilityTextTrigger(textContent: String, textPos: SCNVector3,textType: String) {
        let abilitiesTriggerTextNode = TextNode(textScale: SCNVector3(0.01, 0.01, 0.001))
        abilitiesTriggerTextNode.string = textContent
        abilitiesTriggerTextNode.position = textPos
        abilitiesTriggerTextNode.position.y = 0.1
//        abilitiesTriggerTextNode.eulerAngles = SCNVector3(-60.degreesToRadius, 0 , 0)
        playerBoardNode.addChildNode(abilitiesTriggerTextNode)
        abilitiesTriggerTextNode.runAction(SCNAction.sequence([
            SCNAction.fadeIn(duration: 0.1),
            SCNAction.wait(duration: 1),
//            SCNAction.fadeOut(duration: 0.3),
            SCNAction.customAction(duration: 0, action: { _,_ in
                abilitiesTriggerTextNode.removeFromParentNode()
            })
        ]))
    }
    //attakall practicle system 暂时电鳗专属
    public func eelDamageAction(practicleName: String, boardSide: Int)  -> Double{
        var totalTime:Double = 0
        if boardNode[boardSide].count > 0 {
            
        let newTrackPoint = SCNNode(geometry: SCNSphere(radius: 0.003))
        newTrackPoint.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        if let explosion = SCNParticleSystem(named: practicleName, inDirectory: nil) {
            //explosion.emissionDuration = CGFloat(1)
            explosion.emitterShape = SCNSphere(radius: 0.003)
            
            newTrackPoint.addParticleSystem(explosion)
           
        }
        newTrackPoint.position = boardNode[boardSide][0].position
        newTrackPoint.position.y = 0.5
        playerBoardNode.addChildNode(newTrackPoint)
        let trackActionSequence = [
            SCNAction.move(to: boardNode[boardSide][boardNode[boardSide].count - 1].position, duration: 1),
            SCNAction.customAction(duration: 0, action: { _,_ in
                newTrackPoint.removeFromParentNode()
            })
        ]
        totalTime += 1
        newTrackPoint.runAction(SCNAction.sequence(trackActionSequence))
        }
        return totalTime
    }
    
    
    //dealDamage practicle system
    
    public func dealDamageAction(startVector: SCNVector3, endVector: SCNVector3) -> Double{
        let newTrackPoint = SCNNode(geometry: SCNSphere(radius: 0.003))
        newTrackPoint.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        if let explosion = SCNParticleSystem(named: "particals.scnassets/attackCol.scnp", inDirectory: nil) {
            //explosion.emissionDuration = CGFloat(1)
            explosion.emitterShape = SCNSphere(radius: 0.003)
            
            newTrackPoint.addParticleSystem(explosion)
           
        }
        newTrackPoint.position = startVector
        newTrackPoint.position.y = 0.1
        playerBoardNode.addChildNode(newTrackPoint)
        let trackActionSequence = [
            SCNAction.move(to: endVector, duration: 1),
            SCNAction.customAction(duration: 0, action: { _,_ in
                newTrackPoint.removeFromParentNode()
            })
        ]
        newTrackPoint.runAction(SCNAction.sequence(trackActionSequence))
        return 1
    }
    
    
    
    
    //chessnode actions

    public func attack(attackBoardIndex: Int , attackIndex: Int, victimBoardIndex: Int, victimIndex: Int) -> Promise<[Double]> {
        return Promise<[Double]>(resolver: { (resolver) in
            let attackBoard = self.boardNode[attackBoardIndex]
            let victimBoard = self.boardNode[victimBoardIndex]
            let attacker = attackBoard[attackIndex]
            let victim = victimBoard[victimIndex]
            let atkStartPos = attacker.position
            var attackAtt = attacker.atkNum!
            var defAtt = victim.atkNum!
            var attackSequence: [SCNAction] = [] //攻击动作action sequence
            let leftIndex = victimIndex - 1
            let rightIndex = victimIndex + 1
            var adjacentChesses:[baseChessNode] = []
            if leftIndex >= 0 && leftIndex < victimBoard.count {
                adjacentChesses.append(self.boardNode[victimBoardIndex][leftIndex])
            }
            if rightIndex >= 0 && rightIndex < victimBoard.count {
                adjacentChesses.append(self.boardNode[victimBoardIndex][rightIndex])
                
            }
            
            //找不到就按默认返回
            if let vicIndexArr = findChessPos(victim) {
                if let vicVec = returnExactPos(boardSide: victimBoardIndex, chessIndex: vicIndexArr[1]) { //如果找的到就按新的路线返回
                  attackSequence = [attackAction(atkStartPos, vicVec)]
                } else {
                    attackSequence = [attackAction(atkStartPos, victim.position)]
                }
                
            } else {
                 attackSequence = [attackAction(atkStartPos, victim.position)]
            }
            
            
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
            if victim.abilities.contains(EnumAbilities.lessBloodEliminated.rawValue) {
                if attacker.defNum! < victim.defNum! {
                    attackSequence.append(SCNAction.customAction(duration: 0.5, action: { _,_ in
                        victim.abilityTrigger(abilityEnum: EnumAbilities.lessBloodEliminated.rawValue.localized)
                    }))
                    defAtt = attacker.defNum! + 1
                }
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
            
            //bloodChangeAction([attacker, victim], [attRstBlood, vicRstBlood])
            var damageNums = [victim.atkNum!, attackAtt]
            var changeNodes = [attacker, victim]
            var changeNums = [attRstBlood, vicRstBlood]
            //溅射攻击
            if attacker.abilities.contains(EnumAbilities.sputtering.rawValue) {
                
                var adjCHP:[Int] = []
                var adjDam:[Int] = []
                adjacentChesses.forEach{(curC) in
                    if curC.temporaryBuff.contains(EnumAbilities.shell.rawValue) { //如果被攻击者有shell
                        adjCHP.append(curC.defNum!)
                        adjDam.append(0)
                    } else {
                        adjCHP.append(curC.defNum! - attacker.atkNum!) //溅射伤害不继承剧毒
                        adjDam.append(attacker.atkNum!)
                    }
                }
                changeNodes += adjacentChesses
                changeNums += adjCHP
                damageNums += adjDam
            }
            attackSequence += [
                damageAppearAction(changeNodes, damageNums),   //伤害弹出动画
                bloodChangeAction(changeNodes, changeNums)
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
                if let backPos = findChessPos(attacker) {
                    if let backVec = returnExactPos(boardSide: backPos[0], chessIndex: backPos[1]) { //如果找的到就按新的路线返回
                      attackSequence += [backToAction(backVec, attacker, attackBoardIndex)]
                    } else {
                       attackSequence += [backToAction(atkStartPos, attacker, attackBoardIndex)] //找不到就按照默认返回
                    }
                    
                } else {
                    attackSequence += [backToAction(atkStartPos, attacker, attackBoardIndex)] //找不到就按照默认返回
                }
            
            }
            //计算动作用时 calculate the total time of all the actions
            attackSequence.forEach { (action) in
                totalTime += action.duration
            }
            actionResult.append(totalTime)

            
            //resolve promise
            attacker.attackOnce() //进行一次攻击频率
            delay(SCNAction.sequence(attackSequence).duration , task: {

                resolver.fulfill(actionResult)
            })
            attacker.runAction(SCNAction.sequence(attackSequence))
            
            
            
            
        })
    }
    func recoverButtons() {
        randomButtonNode.runAction(SCNAction.fadeIn(duration: 1))
        upgradeButtonNode.runAction(SCNAction.fadeIn(duration: 1))
        endButtonNode.runAction(SCNAction.fadeIn(duration: 1))
        freezeButtonNode.runAction(SCNAction.fadeIn(duration: 1))
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
        freezeButtonNode.runAction(SCNAction.fadeOut(duration: 1))
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
        if let freezeButtonTopTemp = playerBoardNode.childNode(withName: "freezeButtonTop", recursively: true) {
            freezeButtonTopNode = freezeButtonTopTemp
        }
 
        if let randomButtonTemp = playerBoardNode.childNode(withName: "randomButton", recursively: true) {
            randomButtonNode = randomButtonTemp
        }
        if let upgradeButtonTemp = playerBoardNode.childNode(withName: "upgradeButton", recursively: true) {
            upgradeButtonNode = upgradeButtonTemp
            if let upgradePriceNode = upgradeButtonTemp.childNode(withName: "upgradePriceNode", recursively: true) {
                priceTagNode.position = SCNVector3(-0.1,-0.5,0)
                priceTagNode.string = String(curUpgradeCoin)
                upgradePriceNode.addChildNode(priceTagNode)
            }
        }
        if let endButtonTemp = playerBoardNode.childNode(withName: "endButton", recursively: true) {
            endButtonNode = endButtonTemp
        }
        if let freezeButtonTemp = playerBoardNode.childNode(withName: "freezeButton", recursively: true) {
            freezeButtonNode = freezeButtonTemp
        }
    }
    
    func recoverChess(side: Int){ //用户恢复数据上没删除 只是removenode的棋子
        boardNode[side].forEach{curC in
            playerBoardNode.addChildNode(curC)
        }
    }
    
    
    func initGameTest() {
        initBoardRootNode()
        initBoardChess(initStage: curStage)
        recoverChess(side: BoardSide.allySide.rawValue)
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
    func winTheGame() {
        PlayerBoardTextAppear(TextContent: "win".localized)
        disableButtons() //禁止buttons点击和手势事件
    }
    
    //master ohone init the playerboard and send to peers
    func initPlayerBoardAndSend(hitTestResult: ARHitTestResult) {
        if  isPlayerBoardinited {
            return
        } else {
            isPlayerBoardinited = true
        }
        
        playerBoardNode = createPlayerBoard()
        //playerBoardNode.eulerAngles = SCNVector3(45.degreesToRadius, 0, 0)
        //playGroundNode.geometry?.firstMaterial?.isDoubleSided = true
        //playGroundNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        let hitTransform = hitTestResult.worldTransform
        let positionOFPlane = hitTransform.columns.3
        let xP = positionOFPlane.x
        let yP = positionOFPlane.y
        let zP = positionOFPlane.z
        playerBoardNode.position = SCNVector3(xP,yP,zP)
        playerBoardNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: playerBoardNode))
        //playGroundNode.physicsBody?.categoryBitMask = BitMaskCategoty.playGround.rawValue
        //playGroundNode.physicsBody?.contactTestBitMask = BitMaskCategoty.baseCard.rawValue
        self.sceneView.scene.rootNode.addChildNode(playerBoardNode)
        
        if (gameConfigStr.isMaster && !isBoardInfoSent) { //如果是主机发送
            isBoardInfoSent = true
            let anchor = ARAnchor(name: "playerBoard", transform: hitTransform)
            // Send the anchor info to peers, so they can place the same content.
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                else { fatalError("can't encode anchor") }
            self.multipeerSession.sendToAllPeers(data)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            self.initGameTest()
        })
        }
    //just add the player board node
    func initPlayerBoard(playerBoardPosition: SCNVector3) {
        if  isPlayerBoardinited {
            return
        } else {
            isPlayerBoardinited = true
        }
        playerBoardNode = createPlayerBoard()
        //playerBoardNode.eulerAngles = SCNVector3(45.degreesToRadius, 0, 0)
        //playGroundNode.geometry?.firstMaterial?.isDoubleSided = true
        //playGroundNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
//        let positionOFPlane = hitTestResult.worldTransform.columns.3
//        let xP = positionOFPlane.x
//        let yP = positionOFPlane.y
//        let zP = positionOFPlane.z
        playerBoardNode.position = playerBoardPosition
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
        
        
        if let _ = anchor as? ARPlaneAnchor {
           curPlaneNode = customPlaneNode()
           return curPlaneNode
        } else if let anchorName = anchor.name, anchorName.hasPrefix("playerBoard") {
           return playerBoardNode
        } else { return nil }

        // We return a special type of SCNNode for ARPlaneAnchors
       
    }

    public func renderer(_: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        
        
        if (gameConfigStr.isMaster) { //主机
            if isPlayerBoardinited {
                return
            }
            
            guard let planeAnchor = anchor as? ARPlaneAnchor,
                let planeNode = node as? customPlaneNode else {
                    return
            }
            if planeNode.position.y > 0 {
                return
            }
            planeNode.update(from: planeAnchor)
            // Send the anchor info to peers, so they can place the same content.
//            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: planeAnchor, requiringSecureCoding: true)
//                else { fatalError("can't encode anchor") }
//            print("datasent", multipeerSession.connectedPeers)
            //self.multipeerSession.sendToAllPeers(data)
            
        } else { //从机
            if let anchorName = anchor.name, anchorName.hasPrefix("playerBoard") {
                self.initPlayerBoard(playerBoardPosition: node.position)
                node.removeFromParentNode()
            }
//            else if let anchorName = anchor.name, anchorName.hasPrefix("customPlane") {
//                guard let planeAnchor = anchor as? ARPlaneAnchor,
//                    let planeNode = node as? customPlaneNode else {
//                        return
//                }
//               planeNode.update(from: planeAnchor)
//            }
        }
       
    }

    public func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if (gameConfigStr.isMaster) { //主机
            if isPlayerBoardinited {
                return
            }
            guard let planeAnchor = anchor as? ARPlaneAnchor,
                let planeNode = node as? customPlaneNode else {
                    return
            }
            if planeNode.position.y > 0 {
                return
            }
            planeNode.update(from: planeAnchor)
             //Send the anchor info to peers, so they can place the same content.
//            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: planeAnchor, requiringSecureCoding: true)
//                else { fatalError("can't encode anchor") }
//            print("datasent", multipeerSession.connectedPeers)
            //self.multipeerSession.sendToAllPeers(data)
        } else {//从机
        }
        
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
