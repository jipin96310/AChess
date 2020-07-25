//
//  ViewController+ARSCNViewDelegate.swift
//  AChess
//
//  Created by zhaoheng sun on 7/11/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import ARKit
import os.log

extension ViewController {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if anchor == prePlaneNode.anchor {
            // If board anchor was added, setup the level.
            DispatchQueue.main.async {
                if self.sessionState == .localizingToPlane {
                    self.sessionState = .setupBoard
                }
            }

            // We already created a node for the board anchor
            return prePlaneNode
        } else { //非本机anchor
//                playerBoardNode.placeBoard(on: playerBoardNode, gameScene: sceneView.scene, plane: prePlaneNode, multiSession: self.multipeerSession)
            guard let planeAnchor = anchor as? CustomAnchor else {return nil}
            guard let planeAnchorID = planeAnchor.anchorID else {return nil}
            var EmptyNode:ChessBoardNode? = nil
            for i in 0 ..< enemyPlayerBoardNodes.count {
                if enemyPlayerBoardNodes[i].playerID == nil {
                    enemyPlayerBoardNodes[i].playerID = planeAnchor.anchorID
                    EmptyNode = enemyPlayerBoardNodes[i]
                    EmptyNode?.placeBoard(on: EmptyNode!, gameScene: sceneView.scene, plane: prePlaneNode, multiSession: nil)
                    break;
                }
            }  
            return EmptyNode
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? CustomAnchor {
            // Update the game board's scale from the board anchor
            // The transform will have already been updated - without the scale
            node.simdScale = SIMD3<Float>( repeating: Float(planeAnchor.size.width) )
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        os_log(.info, "camera tracking state changed to %s", "\(camera.trackingState)")
        switch camera.trackingState {
        case .normal:
            DispatchQueue.main.async {
                self.trackingStateLabel.text = "Normal".localized
            }
        case .limited:
            DispatchQueue.main.async {
                self.trackingStateLabel.text = "Limited".localized
            }
        default:
            break
        }
    }
//
//    func session(_ session: ARSession, didFailWithError error: Error) {
//        // Get localized strings from error
//        let errorWithInfo = error as NSError
//        let messages = [
//            errorWithInfo.localizedDescription,
//            errorWithInfo.localizedFailureReason,
//            errorWithInfo.localizedRecoverySuggestion
//        ]
//
//        // Use `compactMap(_:)` to remove optional error messages.
//        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
//
//        // Present the error message to the user
//        showAlert(title: "Session Error", message: errorMessage, actions: nil)
//    }
//
    func sessionWasInterrupted(_ session: ARSession) {
        os_log(.info, "[sessionWasInterrupted] --  %s", "\(sessionState)")

        // Inform the user that the session has been interrupted
        isSessionInterrupted = true

        // Hide game board and level
        prePlaneNode.isHidden = true
        insertRoot.opacity = 0.0
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        os_log(.info, "[sessionInterruptionEnded] --  %s", "\(sessionState)")
    }

    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
}
