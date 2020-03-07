//
//  customPlaneNode.swift
//  archess
//
//  Created by zhaoheng sun on 1/8/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import ARKit
import SceneKit

public class customPlaneNode: SCNNode {

    // MARK: - Public functions

    public func update(from planeAnchor: ARPlaneAnchor) {
        // We need to create a new geometry each time because it does not seem to update correctly for physics
        guard let device = MTLCreateSystemDefaultDevice(),
            let geom = ARSCNPlaneGeometry(device: device) else {
                fatalError()
        }
        
        // This allows the material to be invisible but still receive shadows and perform occlusion (hide objects behind them).
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.writesToDepthBuffer = true
        //material.colorBufferWriteMask = []
        material.diffuse.contents = UIColor(white: 0,alpha: 0.8)
        geom.firstMaterial = material

        geom.update(from: planeAnchor.geometry)

        // We modify our plane geometry each time ARKit updates the shape of an existing plane
        geometry = geom

        castsShadow = false

        // We have to specify we want to use the bounding box or it does not work
        let shape = SCNPhysicsShape(geometry: geom, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.collisionMargin : 0.0])
        //physicsBody?.restitution = 0.2
        physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        physicsBody?.allowsResting = true
        
        physicsBody?.categoryBitMask = BitMaskCategoty.playGround.rawValue
        physicsBody?.contactTestBitMask = -1
        physicsBody?.collisionBitMask = -1
        
        scale = SCNVector3(1,1.0,1)

    }
}
