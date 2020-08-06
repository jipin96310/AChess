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
                        var midPointVec:SCNVector3 = SCNVector3(0, 0 ,0)
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
                            //                        if index == 0 {
                            //                            midPointZ = firstVector.z
                            //                            //print("1", midPointZ)
                            //                        } else if index == tipPoint.count - 1 {
                            
                            if index == tipPoint.count / 2 {
                                let midX = firstVector.x > lastVector.x ? lastVector.x + (firstVector.x - lastVector.x) :
                                    firstVector.x + (lastVector.x - firstVector.x)
                                let midPoint = SCNVector3(midX, firstVector.y, firstVector.z)
                                midPointVec = midPoint
                                midPointCG = CGPoint(x: CGFloat(midX), y: firstPoint.y)
                                midPointZ = firstVector.z
                            }
                         
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: {
                                tempNode1.removeFromParentNode()
                                tempNode2.removeFromParentNode()
                            })
                        }
                        
                       
                        if distanceSCNVector3(from: midPointVec, to: self.handPoint.position) < 0.03 || self.overDistanceCount >= 2 {
                            self.handPoint.position = midPointVec
                            //self.handPoint.position.y += 0.01
                            self.overDistanceCount = 0
                        } else {
                            self.overDistanceCount += 1
                        }
                        
                        self.handPoint.isHidden = false
                        if(handGesture == EnumsHandGesture.closedFist.rawValue) { //握拳
                            self.curHandGesture = HandGestureCategory.closeFist
                            ///let midHitTest = self.sceneView.hitTest(midPointCG, types: )
                           
                            let midHitT = self.sceneView.hitTest(midPointCG, options: [SCNHitTestOption.ignoreHiddenNodes: true, SCNHitTestOption.rootNode: self.playerBoardNode])
                            if !midHitT.isEmpty {
                                print(midHitT.first?.node)
                            }
                            
                            
                        } else if (handGesture == EnumsHandGesture.openFist.rawValue) {
                            self.curHandGesture = HandGestureCategory.openFist
                            if let curHoldingChess = self.handPoint.childNode(withName: "baseChess", recursively: true) {
                                let tempNode = curHoldingChess
                                curHoldingChess.removeFromParentNode()
                                tempNode.position = self.handPoint.position
                                self.sceneView.scene.rootNode.addChildNode(tempNode)
                            } else {
                                //not holding anything
                            }
                        } else {
                            
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
    
}
