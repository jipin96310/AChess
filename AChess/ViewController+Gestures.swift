//
//  ViewController+Gestures.swift
//  AChess
//
//  Created by zhaoheng sun on 7/6/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
extension ViewController: UIGestureRecognizerDelegate {
   
    @IBAction func handleRotation(_ gesture: CustomRotateGestureRecognizer) {
         guard !isPlayerBoardinited else { return }
         
         sessionState = .adjustingPlane
         
         switch gesture.state {
         case .changed where gesture.isThresholdExceeded:
             if prePlaneNode.eulerAngles.x > .pi / 2 {
                 prePlaneNode.simdEulerAngles.y += Float(gesture.rotation)
             } else {
                 prePlaneNode.simdEulerAngles.y -= Float(gesture.rotation)
             }
             gesture.rotation = 0
         default:
             break
         }
     }
    @IBAction func handlePinch(_ gesture: CustomPinchGestureRecognizer) {
        guard !isPlayerBoardinited else { return }
        
        sessionState = .adjustingPlane
        
        switch gesture.state {
        case .changed where gesture.isThresholdExceeded:
            prePlaneNode.scale(by: Float(gesture.scale))
            gesture.scale = 1
        default:
            break
        }
    }
    @IBAction func handlePan(_ gesture: CustomPanGestureRecognizer) {
          
          guard !isPlayerBoardinited else { return }
          
          sessionState = .adjustingPlane
          
          let location = gesture.location(in: sceneView)
          let results = sceneView.hitTest(location, types: .existingPlane)
          guard let nearestPlane = results.first else {
              return
          }
          
          switch gesture.state {
          case .began:
              panOffset = nearestPlane.worldTransform.columns.3.xyz - prePlaneNode.simdWorldPosition
          case .changed:
              prePlaneNode.simdWorldPosition = nearestPlane.worldTransform.columns.3.xyz - panOffset
          default:
              break
          }
      }
    
    @objc func onTap(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
        if !hitTestResult.isEmpty {
            if isPlayerBoardinited == false {
                switch sessionState {
                case .placingPlane, .adjustingPlane:
                    if !prePlaneNode.isBorderHidden {
                        sessionState = .setupBoard
                    }
                default:
                    break
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
                        DispatchQueue.global().async {
                            self.randomButtonTopNode.runAction(SCNAction.sequence([
                                SCNAction.move(by: SCNVector3(0,-0.01,0), duration: 0.25),
                                SCNAction.move(by: SCNVector3(0,0.01,0), duration: 0.25),
                                SCNAction.customAction(duration: 0, action: { _,_ in
                                    self.isRandoming = false
                                })
                            ]))  
                        }
                        if self.playerStatues[self.curPlayerId].curCoin > 0 && !self.isFreezed {
                            self.playerStatues[self.curPlayerId].curCoin -= 1
                            self.initBoardChess(initStage: EnumsGameStage.exchangeStage.rawValue)
                        }
                        
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
                        //即将开始战斗 备份当前阵容
                        self.playerStatues[0].curChesses = copyChessArr(curBoard: self.boardNode[BoardSide.allySide.rawValue])
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
    
}
