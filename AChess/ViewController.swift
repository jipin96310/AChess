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
    var isPlayerBoardinited = false
    var playerBoardNode = createPlayerBoard()
    var boardNode :[[baseChessNode]] = [[],[]]
    var boardRootNode :[[SCNNode]] = [[],[]]
    var setting = (controlMethod : 0, particalOn : 0)//0:  0 用tap的方式操作。1用手识别操作
    var rootNodeDefalutColor = [UIColor.red, UIColor.green]
    //
    var handPoint = SCNNode() // use for mode1 with hand
    var referencePoint = SCNNode() // use for mode0 with touching on screen
    
    var curDragPoint: baseChessNode? = nil
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
                               rootNode.removeFromParentNode()
                                
                               curDragPoint = rootNode
                                self.sceneView.scene.rootNode.addChildNode(curDragPoint!)
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
            }
        } else if sender.state == .ended
        {
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
                }
            }
        }
    func checkCollisionWithChess(_ pressLocation: SCNVector3) {
//        let node = SCNNode()
//        node.coll
    }
    //test func remember to delete
    func initChessWithPos(pos: SCNVector3) -> baseChessNode{
        let chessNode = baseChessNode()
        chessNode.atkNum = 1
        chessNode.defNum = 3
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
        let chessNode = initChessWithPos(pos: SCNVector3(xP, yP + 0.01, zP))
        
        self.sceneView.scene.rootNode.addChildNode(chessNode)
                       
                       
    }
    func updateChessBoardPosition( _ attackResult: [Double] ) -> Double {
        let totalTime = 0.50
        for typeIndex in 0 ..< 2 { // 0: 1:  2号位是动作时间
            if attackResult[typeIndex] == 0 {
                for index in 0 ..< self.boardNode[typeIndex].count {
                    
                    let curRootNode  = boardRootNode[typeIndex][index]
                    let curChessNode = self.boardNode[typeIndex][index]
                    let updateAction = SCNAction.move(to: SCNVector3(curRootNode.position.x, curRootNode.position.y + 0.01 , curRootNode.position.z), duration: totalTime)
                    curChessNode.runAction(updateAction)
                    
                }
            }
        }
        return totalTime
    }
    func aRoundTaskAsync(_ beginIndex: inout Int, _ resolver: Resolver<Any>) {
          var curIndex = beginIndex
           if (curIndex < boardNode[0].count) {
               let randomIndex = Int.randomIntNumber(lower: 0, upper: self.boardNode[1].count)
               let attackResult = attack(self.boardNode[0][curIndex], self.boardNode[1][randomIndex])
               
               if attackResult[0] == 0 { //attacker eliminated
                   self.boardNode[0].remove(at: beginIndex)
               } else {
                 curIndex += 1
                }
               if attackResult[1] == 0 { //victim elinminated
                   self.boardNode[1].remove(at: randomIndex)
               }
               delay(attackResult[2]) {
                let updateTime = self.updateChessBoardPosition(attackResult)
                delay(updateTime + 0.10) { //
                   self.aRoundTaskAsync(&curIndex, resolver)
                }
                }
           } else if boardNode[0].count > 0 && boardNode[1].count > 0 {
               var nextRoundIndex = 0
               self.aRoundTaskAsync(&nextRoundIndex, resolver)//从头开始
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
    func beginRounds(){ //当前默认是敌人方进行攻击 后续调整
       // while boardNode[0].count > 0 && boardNode[1].count > 0 {
        Promise<Any>(resolver: { (resolver) in
           var beginIndex = 0
           aRoundTaskAsync(&beginIndex, resolver)
            }).done { (v) in
                print("done", v)
            }
//            var beginIndex = 0
//            aRoundTask(&beginIndex)
       // }
    }
    func initGameTest() {
        for index in 1 ..< 8 {
            if let curNode = playerBoardNode.childNode(withName: "e" + String(index), recursively: true) {
                let tempChess = initChessWithPos(pos: curNode.position)
                tempChess.position.y += 0.01
                //
                let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: SCNCylinder(radius: 0.01, height: 0.001), options: nil))
                
                curNode.physicsBody = body
                curNode.physicsBody?.categoryBitMask = BitMaskCategoty.baseChessHolder.rawValue
                curNode.physicsBody?.contactTestBitMask = BitMaskCategoty.hand.rawValue
                //
                playerBoardNode.addChildNode(tempChess)
                boardRootNode[0].append(curNode)
                boardNode[0].append(tempChess)
            }
        }
        for index in 1 ..< 8 {
            if let curNode = playerBoardNode.childNode(withName: "a" + String(index), recursively: true) {
                let tempChess = initChessWithPos(pos: curNode.position)
                tempChess.position.y += 0.01
                //
                let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: SCNCylinder(radius: 0.01, height: 0.001), options: nil))
                
                curNode.physicsBody = body
                curNode.physicsBody?.categoryBitMask = BitMaskCategoty.baseChessHolder.rawValue
                curNode.physicsBody?.contactTestBitMask = BitMaskCategoty.hand.rawValue
                //
                playerBoardNode.addChildNode(tempChess)
                boardRootNode[1].append(curNode)
                boardNode[1].append(tempChess)
            }
        }
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
        let body = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: newNode, options: [SCNPhysicsShape.Option.scale: SCNVector3(0.3, 0.3, 0.3)]))
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
                            boardNode.geometry?.firstMaterial?.diffuse.contents = rootNodeDefalutColor[index]
                        } else {
                            print("findNode: ", boardNode)
                            boardNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                        }
                    }
                }
            }
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
        //print(planeNode.position)
        planeNode.update(from: planeAnchor)
    }

    public func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node as? customPlaneNode else {
            return
        }
        //print(planeNode.position)
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
