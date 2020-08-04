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
      
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
          let nodeA = contact.nodeA
          let nodeB = contact.nodeB

                if nodeA.physicsBody?.categoryBitMask == BitMaskCategoty.baseChess.rawValue {
                  if nodeB.name != nil && nodeB.name == ContactCategory.hand.rawValue {
                      print(String(nodeA.physicsBody!.categoryBitMask) + " touch " + nodeB.name!)
                  }
              }
              if nodeA.name != nil && nodeB.name == ContactCategory.hand.rawValue {
                  if nodeB.name != nil && nodeB.name == ContactCategory.baseChess.rawValue {
                      print(String(nodeA.physicsBody!.categoryBitMask) + " touch " + nodeB.name!)
                  }
                  
              }
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        //
    }
    

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
                            print(handGesture)
                            if(handGesture == "closedFist") {
                                self.curHandGesture = HandGestureCategory.closeFist
                            } else  {
                                self.curHandGesture = HandGestureCategory.openFist
                                if let curHoldingChess = self.handPoint.childNode(withName: "baseChess", recursively: true) {
                                    let tempNode = curHoldingChess
                                    curHoldingChess.removeFromParentNode()
                                    tempNode.position = self.handPoint.position
                                    self.sceneView.scene.rootNode.addChildNode(tempNode)
                                } else {
                                    //not holding anything
                                }
                            }
                            // Release currentBuffer when finished to allow processing next frame
                            self.currentBuffer = nil
                            
                            guard let tipPoint = normalizedFingerTip else {
                                return
                            }
                            if tipPoint.count < 1 {
                                return
                            }
                            /////////// need to convert [[]] to [] only keep the widest line and top line and bottm line
    //                        var renderArr1 : [CGPoint] = []
    //                        var renderArr2 : [CGPoint] = []
                            var midPointVector = SCNVector3(0, 0 ,0)
                            var midPointZ = Float(0)
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
                                let tempNode = SCNNode(geometry: SCNSphere(radius: 0.001))
                                tempNode.simdTransform = hitTestResult1.worldTransform
                                let firstVector = tempNode.position
                                tempNode.simdTransform = hitTestResult2.worldTransform
                                let lastVector = tempNode.position
                                //if its longer than longestwidth
                                let curLongest = lastVector.x - firstVector.x
                                //longestWidth = curLongest > longestWidth ? curLongest : longestWidth
                                if index == 0 {
                                    midPointZ = firstVector.z
                                    //print("1", midPointZ)
                                } else if index == Int(tipPoint.count / 2) {
                                        midPointVector = averageVector(left: firstVector, right: lastVector)
                            
                                } else if index == tipPoint.count - 2 {
                                    
                                    midPointZ = midPointZ > firstVector.z ? midPointZ - (midPointZ - firstVector.z) / 2 : firstVector.z - (firstVector.z - midPointZ) / 2
                                    //print("2", midPointZ, firstVector.z)
                                }
                            }
 
                            self.handPoint.position = midPointVector
                            self.handPoint.position.z = midPointZ
                            self.handPoint.position.y += 0.01
                            self.handPoint.isHidden = false
                                    //hands physics body
                                    //self.sceneView.scene.rootNode.addChildNode(newRound)
                            
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                                    //self.handPoint.isHidden = true
                                })
                                
                        }
                    }

                    guard let outBuffer = outputBuffer else {
                        return
                    }

                    // Create UIImage from CVPixelBuffer
                    previewImage = UIImage(ciImage: CIImage(cvPixelBuffer: outBuffer))
                    normalizedFingerTip = outBuffer.searchTopPoint()

                }
            }
    
}
