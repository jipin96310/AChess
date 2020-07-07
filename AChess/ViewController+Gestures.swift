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
    
}
