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
     var allyBoardNode : SCNNode = SCNNode()
    
    
    var handPoint = SCNNode() // use for mode1 with hand
    var referencePoint = SCNNode() // use for mode0 with touching on screen
    
    var curDragPoint: baseChessNode? = nil
    var curFocusPoint: SCNNode? = nil
    
    //以下数据需要保存
    var boardPool : [String : Int] = ["" : 0] //卡池
    var boardNode :[[baseChessNode]] = [[],[]] //chesses
    var boardRootNode :[[SCNNode]] = [[],[]] //chess holder
    var storageNode : [baseChessNode] = []
    var storageRootNode : [SCNNode] = []
   
    //var backupBoardNode:[[baseChessNode]] = [[],[]]
    var playerStatues: [(curCoin: Int,curLevel: Int,curBlood: Int,curChesses: [baseChessNode])] = [(curCoin: GlobalNumberSettings.roundBaseCoin.rawValue + 10, curLevel: 1, curBlood: 40, curChesses: []), (curCoin: GlobalNumberSettings.roundBaseCoin.rawValue, curLevel: 1, curBlood: 40, curChesses: [])] {
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
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tapGestureRecognizer.cancelsTouchesInView = false
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        if setting.controlMethod == 0 {
            initReferenceNode()
            //control with long press
            let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action:  #selector(onLongPress))
            longPressGestureRecognizer.cancelsTouchesInView = false
            self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
            // MARK: pan gesture is unnecessary. it is included in longpress recognizer
//            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan))
//            panGestureRecognizer.maximumNumberOfTouches = 1
//            self.sceneView.addGestureRecognizer(panGestureRecognizer)
        }
        //only for test
        self.sceneView.debugOptions = [ARSCNDebugOptions.showPhysicsShapes]
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
                        if rootNodePos[0] < 2 {
                            boardNode[rootNodePos[0]].remove(at: rootNodePos[1])
                        } else {
                            storageNode.remove(at: rootNodePos[1])
                        }
                    }
                    
                    self.sceneView.scene.rootNode.addChildNode(curDragPoint!)
                    updateWholeBoardPosition()
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
                }
            }
        } else if sender.state == .ended
        {
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, options: [SCNHitTestOption.ignoreHiddenNodes: true, SCNHitTestOption.rootNode: playerBoardNode]) //用于检测触摸的node
            let hitTestResult2 = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent]) //用于检测触摸点的pos
            if !hitTestResult.isEmpty && curDragPoint != nil {
                let curPressNode = hitTestResult.first!.node
                //if curDragPoint?.name?.first == "a" { //抓的是已经购买的牌
                
                if let curPressParent = findChessRootNode(curPressNode) { //按到棋子上了
                    //if curPressParent.name?.first == "a" {
                    //print("onchess")
                    inserChessPos(insertChess: curDragPoint!, insertTo: curPressParent)
                    if curDragPoint != nil {
                        curDragPoint?.position.y = 0.01
                        playerBoardNode.addChildNode(curDragPoint!)
                    }
                    updateWholeBoardPosition()
                    updateStorageBoardPosition()
                    //}
                } else { //按到空地或者底座上了
                    if let curRootNodePos = findRootPos(curPressNode) { //只有购买状态时候才能操作 所以无需判断当前阶段
                        var curSideIndex = curRootNodePos[0] //阵营编号
                        var curIndex = curRootNodePos[1] //落点编号
                        let curSide = boardNode[curSideIndex]
                        if curSideIndex == BoardSide.allySide.rawValue { //落点在本方 才会触发购买
                            if curDragPoint!.chessStatus == EnumsChessStage.forSale.rawValue { //not yet owned, first deducts the money
                                if buyChess(playerID: curPlayerId, chessPrice: curDragPoint!.chessPrice) == true { //buy success
                                    curDragPoint?.chessStatus = EnumsChessStage.owned.rawValue
                                } else {
                                    if curIndex < (GlobalNumberSettings.chessNumber.rawValue - curSide.count) / 2 {
                                        boardNode[curSideIndex].insert(curDragPoint!, at: 0)
                                    } else {
                                        boardNode[curSideIndex].append(curDragPoint!)
                                    }
                                    if curDragPoint != nil {
                                        curDragPoint?.position.y = 0.01
                                        playerBoardNode.addChildNode(curDragPoint!)
                                    }
                                    referencePoint.isHidden = true
                                    //
                                    curDragPoint = nil
                                    updateWholeBoardPosition()
                                    return
                                }
                            }
                        }
                        if curDragPoint!.chessStatus == EnumsChessStage.owned.rawValue { //如果已经买过了，就移动回到ally side
                            curSideIndex = BoardSide.allySide.rawValue
                        }
                        //                            else if curDragPoint?.chessStatus == EnumsChessStage.forSale.rawValue {
                        //                                pointBoardIndex = 0
                        //                            }
                        if curDragPoint != nil {
                            if curIndex < (GlobalNumberSettings.chessNumber.rawValue - curSide.count) / 2 {
                                boardNode[curSideIndex].insert(curDragPoint!, at: 0)
                            } else {
                                boardNode[curSideIndex].append(curDragPoint!)
                            }
                            curDragPoint?.position.y = 0.01
                            playerBoardNode.addChildNode(curDragPoint!)
                        }
                        updateWholeBoardPosition()
                    } else if curPressNode.name == EnumNodeName.saleStage.rawValue && curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue{
                        sellChess(playerID: curPlayerId, curChess: curDragPoint!)
                    } else if curPressNode.name == EnumNodeName.storagePlace.rawValue { //放置到储藏区
                        if curDragPoint?.chessStatus == EnumsChessStage.forSale.rawValue { //未购买
                            if buyChess(playerID: curPlayerId, chessPrice: curDragPoint!.chessPrice) == true { //buy success
                                curDragPoint?.chessStatus = EnumsChessStage.owned.rawValue
                                if curDragPoint != nil { //storage暂时较少用到 不封装放置方法
                                    storageNode.append(curDragPoint!)
                                    curDragPoint?.position.y = 0.01
                                    playerBoardNode.addChildNode(curDragPoint!)
                                }
                            } else { //钱不够 购买时买
                                if curDragPoint != nil {
                                    appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curChess: curDragPoint!)
                                }
                            }
                            updateStorageBoardPosition()
                        } else if curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue { //已购买
                            
                            if storageNode.count < GlobalCommonNumber.storageNumber { //enough space to place 还可以放
                                if curDragPoint != nil { //storage暂时较少用到 不封装放置方法
                                    storageNode.append(curDragPoint!)
                                    curDragPoint?.position.y = 0.01
                                    playerBoardNode.addChildNode(curDragPoint!)
                                }
                                updateStorageBoardPosition()
                            } else {
                                if curDragPoint != nil {
                                    appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: curDragPoint!)
                                }
                                updateWholeBoardPosition()
                            }
                            
                        }
                    } else if curPressNode.name == EnumNodeName.allyBoard.rawValue { //结束点在allyboard
                        if !hitTestResult2.isEmpty {
                            let positionOfPress = hitTestResult2.first!.worldTransform.columns.3
                            let curPressLocation = SCNVector3(positionOfPress.x, positionOfPress.y, positionOfPress.z)
                            
                            if curDragPoint?.chessStatus == EnumsChessStage.forSale.rawValue { //未购买
                                if buyChess(playerID: curPlayerId, chessPrice: curDragPoint!.chessPrice) == true { //buy success
                                    curDragPoint?.chessStatus = EnumsChessStage.owned.rawValue
                                    if curDragPoint != nil {
                                        let curInsertIndex = calInsertPos(curBoardSide: BoardSide.allySide.rawValue, positionOfBoard: curPressLocation)
                                        if curInsertIndex == -1 || curInsertIndex - (GlobalCommonNumber.chessNumber / 2) >= boardNode[BoardSide.allySide.rawValue].count {
                                           appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: curDragPoint!)
                                        } else {
                                            insertNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curBoardIndex: 0, curChess: curDragPoint!)
                                        }
                                        
                                    }
                                } else { //钱不够 购买时买
                                    if curDragPoint != nil {
                                        appendNewNodeToBoard(curBoardSide: BoardSide.enemySide.rawValue, curChess: curDragPoint!)
                                    }
                                }
                                updateWholeBoardPosition()
                            } else if curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue { //已购买
                                if boardNode[BoardSide.allySide.rawValue].count < GlobalCommonNumber.chessNumber { //enough space to place 还可以放
                                    if curDragPoint != nil {
                                        appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: curDragPoint!)
                                    }
                                    updateWholeBoardPosition()
                                } else {//友方棋盘位置不够 放回storage 默认不存在都不够的情况
                                    if curDragPoint != nil { //storage暂时较少用到 不封装放置方法
                                        storageNode.append(curDragPoint!)
                                        curDragPoint?.position.y = 0.01
                                        playerBoardNode.addChildNode(curDragPoint!)
                                        updateStorageBoardPosition()
                                    }
                                }
                                
                            }
                        } else {
                            // 没有触摸点的情况 暂时不做处理 因为没有遇到过。之后可以想办法把棋子移动回去
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
                            updateWholeBoardPosition()
                        } else if curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue { //已购买
                            if boardNode[BoardSide.enemySide.rawValue].count < GlobalCommonNumber.chessNumber { //enough space to place 还可以放
                                if curDragPoint != nil {
                                    appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: curDragPoint!)
                                }
                                updateWholeBoardPosition()
                            } else {//友方棋盘位置不够 放回storage
                                if curDragPoint != nil { //storage暂时较少用到 不封装放置方法
                                    storageNode.append(curDragPoint!)
                                    curDragPoint?.position.y = 0.01
                                    playerBoardNode.addChildNode(curDragPoint!)
                                    updateStorageBoardPosition()
                                }
                            }
                            
                        }
                        
                    } else { //无需判断长度 因为之前的地方肯定有位置给它
                        var pointBoardIndex = 0
                        if curDragPoint?.chessStatus == EnumsChessStage.owned.rawValue {
                            pointBoardIndex = 1
                        }
                        if curDragPoint != nil {
                            curDragPoint?.position.y = 0.01
                            playerBoardNode.addChildNode(curDragPoint!)
                        }
                        boardNode[pointBoardIndex].append(curDragPoint!)
                        updateWholeBoardPosition()
                    }
                    
                }
                //}
                //let positionOfPress = hitTestResult.first!.worldTransform.columns.3
                
                //let curPressLocation = SCNVector3(positionOfPress.x, positionOfPress.y, positionOfPress.z)
                //
                
            }
            //
            if let saleStage = playerBoardNode.childNode(withName: EnumNodeName.saleStage.rawValue, recursively: true) {
                saleStage.geometry?.firstMaterial?.diffuse.contents = UIColor.black
            }
            referencePoint.isHidden = true
            curDragPoint = nil
        }
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
                             print("click", randomButtonTopNode)
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
    func inserChessPos(insertChess: baseChessNode, insertTo: baseChessNode) -> Bool{
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
    func sellChess(playerID: Int, curChess: baseChessNode) {
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
        boardNode[curBoardSide].insert(curChess, at: curBoardIndex)
        curDragPoint?.position.y = 0.01
        playerBoardNode.addChildNode(curChess)
    }
    func appendNewNodeToBoard(curBoardSide:Int, curChess: baseChessNode) {
        boardNode[curBoardSide].append(curChess)
        curDragPoint?.position.y = 0.01
        playerBoardNode.addChildNode(curChess)
    }
    func generateUpgradeChess( _ subChessNodes : [baseChessNode]) -> baseChessNode{//用于合成高等级棋子 保留3个棋子的所有特效  待完善 todo
        //之后可以增加一些判断是否超过2级
        return baseChessNode(statusNum: EnumsChessStage.owned.rawValue , chessInfo: chessStruct(name: subChessNodes[0].chessName, desc: subChessNodes[0].chessDesc, atkNum: subChessNodes[0].atkNum! * 2, defNum: subChessNodes[0].defNum! * 2, chessRarity: subChessNodes[0].chessRarity, chessLevel: subChessNodes[0].chessLevel + 1, abilities: subChessNodes[0].abilities, rattleFunc: subChessNodes[0].rattleFunc, inheritFunc: subChessNodes[0].inheritFunc))
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
        var chessTimesDic:[[String : [Int]]] = [[:],[:],[:]] //棋子map 刷新问题
        var newCombineChess: [baseChessNode] = []
        var oldSubChessIndex: [Int] = []
        //
        for index in 0 ..< boardNode.count {
            for innerIndex in 0 ..< boardNode[index].count {
                //let curRootNode = boardRootNode[index][innerIndex + startIndex]
                let startIndex = (GlobalNumberSettings.chessNumber.rawValue - boardNode[index].count) / 2
                let curChessNode = boardNode[index][innerIndex]
                
                if (index == BoardSide.allySide.rawValue && curChessNode.chessLevel < 3) { //只有己方才触发
                    if chessTimesDic[curChessNode.chessLevel][curChessNode.chessName] != nil {
                        chessTimesDic[curChessNode.chessLevel][curChessNode.chessName]!.append(innerIndex)
                        if chessTimesDic[curChessNode.chessLevel][curChessNode.chessName]!.count >= 3 { //合成
                            var subChessNodes:[baseChessNode] = []
                            chessTimesDic[curChessNode.chessLevel][curChessNode.chessName]?.forEach{(subIndex) in
                                subChessNodes.append(boardNode[index][subIndex])
                            }
//                            boardNode[index] = boardNode[index].filter{(chessNode) -> Bool in
//                                if (chessNode.chessName == curChessNode.chessName) {
//                                    subChessNodes.append(chessNode)
//                                    chessNode.removeFromParentNode() //从棋盘上删除
//                                }
//                            return chessNode.chessName != curChessNode.chessName };
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
        //移除旧的棋子。todo!!!!! 写的方法可以优化
        var tempIndex = -1
        boardNode[BoardSide.allySide.rawValue] = boardNode[BoardSide.allySide.rawValue].filter{(item) in
            tempIndex += 1
            if oldSubChessIndex.contains(tempIndex) {
                item.removeFromParentNode()
            }
            return !oldSubChessIndex.contains(tempIndex)
        }
       
        //置入合成棋子
        newCombineChess.forEach{(newNode) in
            appendNewNodeToBoard(curBoardSide: BoardSide.allySide.rawValue, curChess: newNode)//直接置入本方场内 后期可以修改为置入等待区域
        }
        
       
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
    func attackActivity() {
        
    }
    func aRoundTaskAsync(_ beginIndex: inout [Int],_ attSide: Int, _ resolver: Resolver<Any>) {
        var beginIndexCopy = beginIndex
        var curIndex = beginIndex[attSide] //拷贝的
        var nextSide = attSide == BoardSide.enemySide.rawValue ? BoardSide.allySide.rawValue : BoardSide.enemySide.rawValue
        if (curIndex < boardNode[attSide].count && boardNode[nextSide].count > 0) { //当前游标小于进攻方数量
            let randomIndex = Int.randomIntNumber(lower: 0, upper: self.boardNode[nextSide].count)
            let attacker = self.boardNode[attSide][curIndex]
            let victim = self.boardNode[nextSide][randomIndex]
            let attackResult = attack(attackBoard: self.boardNode[attSide], attackIndex: curIndex, victimBoard: self.boardNode[nextSide], victimIndex: randomIndex)//self.boardNode[0][curIndex], self.boardNode[1][randomIndex]
            //
            //
            if attackResult[0] == 0 { //attacker eliminated
                self.boardNode[attSide].remove(at: curIndex)
            } else {
                beginIndexCopy[attSide] += 1
            }
            if attackResult[1] == 0 { //victim elinminated
                self.boardNode[nextSide].remove(at: randomIndex)
            }
            delay(attackResult[2]) { //延迟攻击动作时间
                let updateTime = self.updateChessBoardPosition(attackResult)
                if attackResult[0] == 0 { //attacker eliminated
                    if attacker.abilities.contains(EnumAbilities.inheritAddBuff.rawValue) { //有传承加buff结算一下
                        self.boardNode[attSide].forEach{ (attChess) in
                            //需要给attchess加buff
                            attChess.AddBuff(AtkNumber: attacker.chessLevel, DefNumber: attacker.chessLevel)
                        }
                    }
                }
                if attackResult[1] == 0 { //victim elinminated
                    if victim.abilities.contains(EnumAbilities.inheritAddBuff.rawValue) { //有传承加buff结算一下
                        self.boardNode[nextSide].forEach{ (attChess) in
                            //需要给attchess加buff
                            attChess.AddBuff(AtkNumber: attacker.chessLevel, DefNumber: victim.chessLevel)
                        }
                    }
                }
                delay(updateTime + 0.10) { //延迟刷新棋盘事件
                    if attacker.abilities.contains(EnumAbilities.rapid.rawValue) && self.boardNode[nextSide].count > 0 && attackResult[0] != 0 { // if alive and has rapid,attack again
                        attacker.abilityTrigger(abilityEnum: EnumString.rapid.rawValue.localized)
                        let randomNumber = Int.randomIntNumber(lower: 0, upper: self.boardNode[nextSide].count)
                        let attackAgainResult = attack(attackBoard: self.boardNode[attSide], attackIndex: curIndex, victimBoard: self.boardNode[nextSide], victimIndex: randomNumber)
                        if attackAgainResult[0] == 0 { //attacker eliminated
                            self.boardNode[attSide].remove(at: curIndex)
                        }
                        if attackAgainResult[nextSide] == 0 { //victim elinminated
                            self.boardNode[nextSide].remove(at: randomNumber)
                        }
                        delay(attackAgainResult[2]) { //延迟第二次攻击时间。风怒
                            let updateAgainTime = self.updateChessBoardPosition(attackAgainResult)
                            delay(updateAgainTime + 0.10) {
                                self.aRoundTaskAsync(&beginIndexCopy, nextSide, resolver)
                            }
                        }
                        
                    }else {
                       self.aRoundTaskAsync(&beginIndexCopy, nextSide, resolver)
                    }
                    
                    
                }
            }
        } else if boardNode[attSide].count > 0 && boardNode[nextSide].count > 0 {
            var nextRoundIndex = [0, 0]
            self.aRoundTaskAsync(&nextRoundIndex,nextSide, resolver)//从头开始
        } else {
            resolver.fulfill("success")
        }
    }
    
    //    func aRoundTask( _ beginIndex: inout Int) { //指针传递inout
    //        var curIndex = beginIndex
    //        if (beginIndex < boardNode[0].count) {
    //            let randomIndex = Int.randomIntNumber(lower: 0, upper: self.boardNode[1].count)
    //            let attackResult = attack(self.boardNode[0][beginIndex], self.boardNode[1][randomIndex])
    //
    //            if attackResult[0] == 0 { //attacker eliminated
    //                self.boardNode[0].remove(at: beginIndex)
    //            }
    //            if attackResult[1] == 0 { //victim elinminated
    //                self.boardNode[1].remove(at: randomIndex)
    //            }
    //            curIndex += 1
    //            delay(5) { self.aRoundTask(&curIndex) }
    //        } else if boardNode[0].count > 0 && boardNode[1].count > 0 {
    //            var beginIndex = 0
    //            delay(5) { self.aRoundTask(&beginIndex) } //从头开始
    //        }
    //    }
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
           aRoundTaskAsync(&beginIndex,randomSide, resolver)
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
        if curStage == EnumsGameStage.exchangeStage.rawValue {
            let delayTime = PlayerBoardTextAppear(TextContent: "BattleStage".localized) //弹出切换回合提示
            delay(delayTime) {
                var totalTime = 0.00
                //处理abilities beforeround事件
                for index in 0 ..< self.boardNode[1].count {
                    let curBoard = self.boardNode[1]
                    let curChess = self.boardNode[1][index]
                    if curChess.abilities.contains(EnumAbilities.liveInGroup.rawValue) {
                        let copyChess = curChess.copyable()
                        curChess.abilities = [] //empty ability,in case it keep adding
                        self.boardNode[1].append(copyChess)
                        self.playerBoardNode.addChildNode(copyChess)
                        curChess.abilityTrigger(abilityEnum: EnumString.liveInGroup.rawValue.localized)
                    }
                }
                let actionTime = self.updateWholeBoardPosition()
                totalTime += actionTime
                //
                self.curStage = EnumsGameStage.battleStage.rawValue
                //copy the backup data
                self.playerStatues[self.curPlayerId].curChesses = []
                self.boardNode[1].forEach{(curChess) in
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
        } else if curStage == EnumsGameStage.battleStage.rawValue {
            let delayTime = PlayerBoardTextAppear(TextContent: "ExchangeStage".localized) //弹出切换回合提示
            delay(delayTime){
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
        var randomLevel = Int.randomIntNumber(lower: 1, upper: curLevel + 1)
        var randomNum =  Int.randomIntNumber(lower: 0, upper: chessCollectionsLevel[randomLevel - 1].count)
        var curChessInfo =  chessCollectionsLevel[randomLevel - 1][randomNum]
        var randomTime = 1
        while boardPool[curChessInfo.name!]! <= 0 && randomTime < 10 {
            randomLevel = Int.randomIntNumber(lower: 1, upper: curLevel + 1)
            randomNum =  Int.randomIntNumber(lower: 0, upper: chessCollectionsLevel[randomLevel - 1].count)
            curChessInfo =  chessCollectionsLevel[randomLevel - 1][randomNum]
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
            let curSaleNumber = playerStatues[curPlayerId].curLevel + 2
            let curStartIndex = (GlobalNumberSettings.chessNumber.rawValue - curSaleNumber) / 2
            for index in 0 ..< curSaleNumber  {
                let curNode = boardRootNode[0][index + curStartIndex]
                //if let curNode = playerBoardNode.childNode(withName: "e" + String(index), recursively: true) {
                let randomStruct =  getRandomChessStructFromPool(curPlayerLevel)
                let tempChess = initChessWithPos(pos: curNode.position, sta: EnumsChessStage.forSale.rawValue, info: randomStruct )
                //tempChess.name = "chessE" + String(index)
                tempChess.position.y += 0.01
                boardNode[0].append(tempChess)
                playerBoardNode.addChildNode(tempChess)
                
                //}
            }
            for index in 0 ..< boardNode[1].count  {
                if let curNode = playerBoardNode.childNode(withName: "a" + String(index + 1), recursively: true) {
                    playerBoardNode.addChildNode(boardNode[1][index])
                    updateWholeBoardPosition()
                }
            }
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
                    tempChess.position.y += 0.01
                //print("tempchess", tempChess.position)
                    boardNode[0].append(tempChess)
                    playerBoardNode.addChildNode(tempChess)
             }
            updateWholeBoardPosition()
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
