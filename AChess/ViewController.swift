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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
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
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        // We want to receive the frames from the video
        sceneView.session.delegate = self
        // Run the view's session
        sceneView.session.run(configuration)
        //set contact delegate
        sceneView.scene.physicsWorld.contactDelegate = self
       
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
    @objc func onTap(sender: UITapGestureRecognizer) {
            guard let sceneView = sender.view as? ARSCNView else {return}
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
            if !hitTestResult.isEmpty {
                if isPlayerBoardinited == false {
                    self.initPlayerBoard(hitTestResult: hitTestResult.first!)
                    isPlayerBoardinited = true
                } else {
                    self.addChessTest(hitTestResult: hitTestResult.first!)
                }
            }
        }
    //test func remember to delete
    func initChessWithPos(pos: SCNVector3) -> baseChessNode{
        let chessNode = baseChessNode()
        chessNode.atkNum = 2
        chessNode.defNum = 4
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
        
        chessNode.physicsBody = body
        
        chessNode.position = SCNVector3(xP,yP,zP)
        return chessNode
    }
    func addChessTest(hitTestResult: ARHitTestResult) {
        
        let positionOFPlane = hitTestResult.worldTransform.columns.3
        let xP = positionOFPlane.x
        let yP = positionOFPlane.y
        let zP = positionOFPlane.z
        let chessNode = initChessWithPos(pos: SCNVector3(xP, yP, zP))
        
        self.sceneView.scene.rootNode.addChildNode(chessNode)
                       
                       
    }
    func aRoundTaskAsync(_ beginIndex: inout Int, _ resolver: Resolver<Any>) {
          var curIndex = beginIndex
           if (curIndex < boardNode[0].count) {
               let randomIndex = Int.randomIntNumber(lower: 0, upper: self.boardNode[1].count)
               let attackResult = attack(self.boardNode[0][curIndex], self.boardNode[1][randomIndex])
               print("attacker:", self.boardNode[0][beginIndex], "vic:", self.boardNode[1][randomIndex])
               if attackResult[0] == 0 { //attacker eliminated
                   self.boardNode[0].remove(at: beginIndex)
               } else {
                 curIndex += 1
                }
               if attackResult[1] == 0 { //victim elinminated
                   self.boardNode[1].remove(at: randomIndex)
               }
               delay(5) { self.aRoundTaskAsync(&curIndex, resolver) }
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
                    
                    playerBoardNode.addChildNode(tempChess)
                    boardNode[0].append(tempChess)
                }
            }
        for index in 1 ..< 8 {
            if let curNode = playerBoardNode.childNode(withName: "a" + String(index), recursively: true) {
                let tempChess = initChessWithPos(pos: curNode.position)
                tempChess.position.y += 0.01
               
                playerBoardNode.addChildNode(tempChess)
                boardNode[1].append(tempChess)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
           //let attackResult = attack(self.boardNode[0][0], self.boardNode[1][1])
            self.beginRounds()
           
//            let startPos = self.boardNode[0][0].position
//            let attackSequence = SCNAction.sequence([attackAction(startPos, self.boardNode[1][1].position),backToAction(startPos)])
//            self.boardNode[0][0].runAction(attackSequence)
            
        })
           
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
        playerBoardNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        //playGroundNode.physicsBody?.categoryBitMask = BitMaskCategoty.playGround.rawValue
        //playGroundNode.physicsBody?.contactTestBitMask = BitMaskCategoty.baseCard.rawValue
        self.sceneView.scene.rootNode.addChildNode(playerBoardNode)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                                       self.initGameTest()
                                   })
       
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
extension Int {
    var degreesToRadius: Double { return Double(self) * .pi/180}
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
