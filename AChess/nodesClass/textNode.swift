//
//  textNode.swift
//  AChess
//
//  Created by zhaoheng sun on 1/28/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation
import SceneKit

class TextNode: SCNNode {
    private let textGeometry = SCNText()

    var string: String? {
        didSet {
            updateTextContainerFrame()
            textGeometry.string = string
        }
    }

    override init() {
        super.init()
        
        textGeometry.truncationMode = CATextLayerTruncationMode.middle.rawValue
        textGeometry.isWrapped = true
        textGeometry.alignmentMode = CATextLayerAlignmentMode.left.rawValue
        textGeometry.font = UIFont.systemFont(ofSize: 1)
        scale = SCNVector3(0.01, 0.01, 0.01)
       
        let blackMaterial = SCNMaterial()
        blackMaterial.diffuse.contents = UIColor.orange
        blackMaterial.locksAmbientWithDiffuse = true
        textGeometry.materials = [blackMaterial]

        geometry = textGeometry
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

  private func updateTextContainerFrame() {
            let (min, max) = boundingBox
            let width = CGFloat(max.x - min.x)
            let height = CGFloat(max.y - min.y)
            if width > 0 && height > 0 {
                print("width :",max.x - min.x,"height :",max.y - min.y,"depth :",max.z - min.z)
                textGeometry.containerFrame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
            }
            
    //        textGeometry.containerFrame = CGRect(origin: .zero, size: CGSize(width: 1.0, height: 1.0))
        }
}
