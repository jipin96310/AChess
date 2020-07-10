//
//  ViewController+Gestures.swift
//  AChess
//
//  Created by zhaoheng sun on 7/6/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import UIKit
import SceneKit

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
    
    @IBAction func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        switch sessionState {
        case .placingPlane, .adjustingPlane:
            if !prePlaneNode.isBorderHidden {
                sessionState = .setupBoard
            }
        default:
            break
        }
    }
    
}
