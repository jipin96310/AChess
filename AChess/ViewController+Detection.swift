//
//  ViewController+Detection.swift
//  AChess
//
//  Created by zhaoheng sun on 8/4/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision
import CoreML

extension ViewController {
      
//    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
//          let nodeA = contact.nodeA
//          let nodeB = contact.nodeB
//
//        if nodeA.physicsBody?.categoryBitMask == BitMaskCategoty.baseChess.rawValue {
//            print(String(nodeA.physicsBody!.categoryBitMask) + " touch " + nodeB.name!)
//        }
//        if nodeB.physicsBody?.categoryBitMask == BitMaskCategoty.baseChess.rawValue {
//            print(String(nodeB.physicsBody!.categoryBitMask) + " touch " + nodeA.name!)
//        }
//
//    }
//    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
//        //
//    }
    

    func startDetection() {
        // To avoid force unwrap in VNImageRequestHandler
        guard let buffer = currentBuffer else { return }
        let orient = UIDevice.current.orientation
        handDetector.performDetection(inputBuffer: buffer, orient) { outputBuffer, _ , handGesture in
            // Here we are on a background thread
            var previewImage: UIImage?
            var normalizedFingerTip: [[CGPoint]]?
            
           
            
            defer {
                DispatchQueue.main.async {
                    self.previewView.image = previewImage
                    //assign to hand gesture global value
                    if handGesture == EnumsHandGesture.closedFist.rawValue {
                        self.gestureInstructionLabel.text = "closed".localized
                    } else {
                        self.gestureInstructionLabel.text = ""
                    }
                    
                    // Release currentBuffer when finished to allow processing next frame
                    self.currentBuffer = nil
                    
                    if self.gameConfigStr.enableHandTracking { //开启手部追踪
                        guard let tipPoint = normalizedFingerTip else {
                            return
                        }
                        if tipPoint.count < 1 { //行数过少
                            return
                        }
                        
                        //calculate mid point
                        var midPointZ = Float(0)
                        var longestWidth:Float = 0
                        //var midPointVec:SCNVector3 = SCNVector3(0, 0 ,0)
                        var midPointCG:CGPoint = CGPoint(x: 0,y: 0)
                        for index in 0 ..< tipPoint.count {
                            let curRowPoints = tipPoint[index]
                            if(curRowPoints.count < 1) {
                                continue
                            }
                            let firstPoint = VNImagePointForNormalizedPoint(curRowPoints.first!, Int(self.view.bounds.size.width), Int(self.view.bounds.size.height))
                            let lastPoint = VNImagePointForNormalizedPoint(curRowPoints.last!, Int(self.view.bounds.size.width), Int(self.view.bounds.size.height))
                            let hitTestResults1 = self.sceneView.hitTest(firstPoint, types: .existingPlaneUsingExtent)
                            guard let hitTestResult1 = hitTestResults1.first else { return }
                            let hitTestResults2 = self.sceneView.hitTest(lastPoint, types: .existingPlaneUsingExtent)
                            guard let hitTestResult2 = hitTestResults2.first else { return }
                            let tempNode1 = SCNNode(geometry: SCNSphere(radius: 0.001))
                            let tempNode2 = SCNNode(geometry: SCNSphere(radius: 0.001))
                            tempNode1.simdTransform = hitTestResult1.worldTransform
                            let firstVector = tempNode1.position
                            tempNode2.simdTransform = hitTestResult2.worldTransform
                            let lastVector = tempNode2.position
                            //print("f", firstVector, "l", lastVector)
                            self.sceneView.scene.rootNode.addChildNode(tempNode1)
                            self.sceneView.scene.rootNode.addChildNode(tempNode2)
                            //if its longer than longestwidth
                            //let curLefter = firstVector.x < leftestPoint.x ? firstVector : leftestPoint
                            //leftestPoint = firstVector.x < leftestPoint.x ? firstVector : leftestPoint
                            //leftestPoint = lastVector.x < leftestPoint.x ? lastVector : leftestPoint
                            
                            if index == tipPoint.count / 2 {
                                let midX = firstVector.x > lastVector.x ? lastVector.x + (firstVector.x - lastVector.x) :
                                    firstVector.x + (lastVector.x - firstVector.x)
                                let midXCG = firstPoint.x > lastPoint.x ? lastPoint.x + (firstPoint.x - lastPoint.x) :
                                firstPoint.x + (lastPoint.x - firstPoint.x)
//                                let midPoint = SCNVector3(midX, firstVector.y, firstVector.z)
//                                midPointVec = midPoint
                                midPointCG = CGPoint(x: midXCG, y: firstPoint.y)
                                midPointZ = firstVector.z
                            }
                         
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: {
                                tempNode1.removeFromParentNode()
                                tempNode2.removeFromParentNode()
                            })
                        }
                        
                        
                        //Mark: 不同手势对应操作
                        let hitTestResults3 = self.sceneView.hitTest(midPointCG, types: .existingPlaneUsingExtent)
                        guard let hitTestResult3 = hitTestResults3.first else { return }
                        let tempNode3 = SCNNode(geometry: SCNSphere(radius: 0.001))
                        tempNode3.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                        tempNode3.simdTransform = hitTestResult3.worldTransform
                                
                        if distanceSCNVector3(from: tempNode3.position, to: self.handPoint.position) < 0.03 || self.overDistanceCount >= 2 {
                            self.handPoint.position = tempNode3.position
                            //self.handPoint.position.y += 0.01
                            self.overDistanceCount = 0
                        } else {
                            self.overDistanceCount += 1
                        }
                        
                        self.handPoint.isHidden = false
                        
                        if(handGesture == EnumsHandGesture.closedFist.rawValue) { //握拳
                            self.curHandGesture = HandGestureCategory.closeFist
                            ///let midHitTest = self.sceneView.hitTest(midPointCG, types: )
                            //self.sceneView.scene.rootNode.addChildNode(tempNode3)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                                tempNode3.removeFromParentNode()
                            })
                            if !(self.curDragPoint != nil) { //没有持有棋子
                                let midHitT = self.sceneView.hitTest(midPointCG, options: [SCNHitTestOption.ignoreHiddenNodes: true, SCNHitTestOption.rootNode: self.playerBoardNode, SCNHitTestOption.categoryBitMask: BitMaskCategoty.baseChess.rawValue])
                                if !midHitT.isEmpty && midHitT.first?.node.physicsBody?.categoryBitMask == BitMaskCategoty.baseChess.rawValue {
                                    if let childNode = midHitT.first?.node {
                                        if let rootBaseChess = findChessRootNode(childNode) {
                                            self.curDragPoint = rootBaseChess
                                            if let rootNodePos = self.findChessPos(rootBaseChess) {
                                                self.curDragPos = [rootNodePos[0]] //当前只存棋盘不存index
                                                if rootNodePos[0] < 2 {
                                                    self.boardNode[rootNodePos[0]].remove(at: rootNodePos[1])
                                                } else {
                                                    self.storageNode.remove(at: rootNodePos[1])
                                                }
                                            }
                                            self.curDragPoint!.position = SCNVector3(0,0.01,0)
                                            self.handPoint.addChildNode(self.curDragPoint!)
                                        }
                                    }
                                } else if self.gameConfigStr.enableButtonGestureControl {
                                    if let curButtonMask = self.findVectorHitButton(midPointCG: midPointCG) { //确认当前是不是button
                                        switch curButtonMask {
                                        case BitMaskCategoty.upgradeButton.rawValue:
                                            self.tapUpgradeAction()
                                            break
                                        case BitMaskCategoty.randomButton.rawValue:
                                            self.tapRandomAction()
                                            break
                                        case BitMaskCategoty.freezeButton.rawValue:
                                            self.tapFreezedButton()
                                            break
                                        case BitMaskCategoty.endRoundButton.rawValue:
                                            self.tapEndButtonAction()
                                            break
                                        default:
                                            break
                                        }
                                    }
                                }
                            } else { //持有了棋子 需要渲染颜色
                                if let curPointCategory = self.findVectorHitPlace(midPointCG: midPointCG) {
                                    self.setBoardColor(boardCate: curPointCategory)
                                }
                            }
                            
                        } else if (handGesture == EnumsHandGesture.openFist.rawValue) {
                            self.curHandGesture = HandGestureCategory.openFist
                            if self.curDragPoint != nil { //持有了棋子
                                var midHitT = self.sceneView.hitTest(midPointCG, options: [SCNHitTestOption.ignoreHiddenNodes: true, SCNHitTestOption.rootNode: self.playerBoardNode, SCNHitTestOption.categoryBitMask: BitMaskCategoty.enemySide.rawValue])
                                self.curDragPoint?.removeFromParentNode()
                                self.playerBoardNode.addChildNode(self.curDragPoint!)
                                if !midHitT.isEmpty && midHitT.first?.node.physicsBody?.categoryBitMask == BitMaskCategoty.enemySide.rawValue { //敌人棋盘
                                    print("enemy", midHitT)
                                    self.endOnEnemyBoard(hitTestResult: hitTestResults3)
                                } else {
                                   midHitT = self.sceneView.hitTest(midPointCG, options: [SCNHitTestOption.ignoreHiddenNodes: true, SCNHitTestOption.rootNode: self.playerBoardNode, SCNHitTestOption.categoryBitMask: BitMaskCategoty.allySide.rawValue])
                                    if !midHitT.isEmpty && midHitT.first?.node.physicsBody?.categoryBitMask == BitMaskCategoty.allySide.rawValue { //友方棋盘
                                        print("ally", midHitT)
                                        self.endOnAllyBoard(hitTestResult: hitTestResults3)
                                    } else {
                                        midHitT = self.sceneView.hitTest(midPointCG, options: [SCNHitTestOption.ignoreHiddenNodes: true, SCNHitTestOption.rootNode: self.playerBoardNode, SCNHitTestOption.categoryBitMask: BitMaskCategoty.saleScreen.rawValue])
                                        if !midHitT.isEmpty && midHitT.first?.node.physicsBody?.categoryBitMask == BitMaskCategoty.saleScreen.rawValue { //出售板
                                            print("sale", midHitT)
                                            self.sellChess(playerID: self.curPlayerId, curChess: self.curDragPoint!, curBoardSide: self.curDragPos[0])
                                        } else {
                                            midHitT = self.sceneView.hitTest(midPointCG, options: [SCNHitTestOption.ignoreHiddenNodes: true, SCNHitTestOption.rootNode: self.playerBoardNode, SCNHitTestOption.categoryBitMask: BitMaskCategoty.storageSide.rawValue])
                                            if !midHitT.isEmpty && midHitT.first?.node.physicsBody?.categoryBitMask == BitMaskCategoty.storageSide.rawValue { //储藏室
                                                print("storage", midHitT)
                                                self.endOnStorage(hitTestResult: hitTestResults3)
                                            } else {//送回老家
                                                print("home", midHitT)
                                                self.recoverNodeToBoard(dragPos: self.curDragPos)
                                                
                                            }
                                        }
                                    }
                                }
                                self.curDragPoint = nil
                                self.curDragPos = []
                                self.setBoardColor(boardCate: nil)
                            }
                        } else { //none gesture
                            self.recoverBoardColor()
                        }
                    }
                    
                }
            }
            
            guard let outBuffer = outputBuffer else {
                return
            }
            
            // Create UIImage from CVPixelBuffer
            previewImage = UIImage(ciImage: CIImage(cvPixelBuffer: outBuffer))
            normalizedFingerTip = outBuffer.searchTopPoint(handGesture: handGesture)
            
        }
    }
    
    
    func findVectorHitButton(midPointCG: CGPoint) -> Int? {
        let ButtonMasks = [BitMaskCategoty.randomButton.rawValue, BitMaskCategoty.upgradeButton.rawValue, BitMaskCategoty.endRoundButton.rawValue, BitMaskCategoty.freezeButton.rawValue]
        for i in 0 ..<  ButtonMasks.count {
            let midHitT = self.sceneView.hitTest(midPointCG, options: [SCNHitTestOption.ignoreHiddenNodes: true, SCNHitTestOption.rootNode: self.playerBoardNode, SCNHitTestOption.categoryBitMask: ButtonMasks[i]])
            if !midHitT.isEmpty && midHitT.first?.node.physicsBody?.categoryBitMask == ButtonMasks[i] {
                return ButtonMasks[i]
            }
        }
        return nil
    }
    
    
    
    
    
    func findVectorHitPlace(midPointCG: CGPoint) -> Int? {
        let PlaceMasks = [BitMaskCategoty.enemySide.rawValue, BitMaskCategoty.allySide.rawValue, BitMaskCategoty.saleScreen.rawValue, BitMaskCategoty.storageSide.rawValue]
        for i in 0 ..<  PlaceMasks.count {
            let midHitT = self.sceneView.hitTest(midPointCG, options: [SCNHitTestOption.ignoreHiddenNodes: true, SCNHitTestOption.rootNode: self.playerBoardNode, SCNHitTestOption.categoryBitMask: PlaceMasks[i]])
            if !midHitT.isEmpty && midHitT.first?.node.physicsBody?.categoryBitMask == PlaceMasks[i] {
                return PlaceMasks[i]
            }
        }
        return nil
    }
    
}
