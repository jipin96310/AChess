//
//  CustomRotateGestureRecognizer.swift
//  AChess
//
//  Created by zhaoheng sun on 7/7/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

class CustomRotateGestureRecognizer: UIRotationGestureRecognizer {
    
    /// The threshold after which this gesture is detected.
    private static let threshold: CGFloat = .pi / 18 // (10°)
    
    /// Indicates whether the currently active gesture has exceeeded the threshold.
    private(set) var isThresholdExceeded = false
    
    var previousRotation: CGFloat = 0
    var rotationDelta: CGFloat = 0
    
    /// Observe when the gesture's `state` changes to reset the threshold.
    override var state: UIGestureRecognizer.State {
        didSet {
            switch state {
            case .began, .changed:
                break
            default:
                // Reset threshold check.
                isThresholdExceeded = false
                previousRotation = 0
                rotationDelta = 0
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        if isThresholdExceeded {
            rotationDelta = rotation - previousRotation
            previousRotation = rotation
        }
        
        if !isThresholdExceeded && abs(rotation) > CustomRotateGestureRecognizer.threshold {
            isThresholdExceeded = true
            previousRotation = rotation
        }
    }
}
