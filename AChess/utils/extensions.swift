//
//  extensions.swift
//  AChess
//
//  Created by zhaoheng sun on 2/3/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation
import ARKit

extension Int {
    var degreesToRadius: Double { return Double(self) * .pi/180}
}
extension Double {
    var degreesToRadius: Double { return Double(self) * .pi/180}
}
extension Float {
    func standardizedAngle(forMinimalRotationTo angle: Float, increment: Float) -> Float {
        var standardized = self
        while abs(standardized - angle) > increment / 2 {
            if self > angle {
                standardized -= increment
            } else {
                standardized += increment
            }
        }
        return standardized
    }
}
extension String {
    func getPrefixStr(symbol: String) -> String{
        let range: Range = self.range(of: symbol)!
        let location: Int = self.distance(from: self.startIndex, to: range.lowerBound)
        let subStr = self.prefix(location)
        return String(subStr)
    }
}
extension SCNNode {
    func hasAncestor(_ node: SCNNode) -> Bool {
        if self === node {
            return true // this is the node you're looking for
        }
        if self.parent == nil {
            return false // target node can't be a parent/ancestor if we have no parent
        }
        if self.parent === node {
            return true // target node is this node's direct parent
        }
        // otherwise recurse to check parent's parent and so on
        return self.parent!.hasAncestor(node)
    }
}
extension float4x4 {
    var trans: SIMD3<Float> {
        get {
            return columns.3.xyz
        }
        set(newValue) {
            columns.3 = SIMD4<Float>(newValue, 1)
        }
    }
    
    var scale: SIMD3<Float> {
        return SIMD3<Float>(length(columns.0), length(columns.1), length(columns.2))
    }

    init(translation vector: SIMD3<Float>) {
        self.init(SIMD4<Float>(1, 0, 0, 0),
                  SIMD4<Float>(0, 1, 0, 0),
                  SIMD4<Float>(0, 0, 1, 0),
                  SIMD4<Float>(vector.x, vector.y, vector.z, 1))
    }
    
    init(scale factor: Float) {
        self.init(scale: SIMD3<Float>(repeating: factor))
    }
    init(scale vector: SIMD3<Float>) {
        self.init(SIMD4<Float>(vector.x, 0, 0, 0),
                  SIMD4<Float>(0, vector.y, 0, 0),
                  SIMD4<Float>(0, 0, vector.z, 0),
                  SIMD4<Float>(0, 0, 0, 1))
    }
    
    static let identity = matrix_identity_float4x4
}
extension SIMD4 where Scalar == Float {
    static let zero = SIMD4<Float>(repeating: 0.0)
    
    var xyz: SIMD3<Float> {
        get {
            return SIMD3<Float>(x, y, z)
        }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
    
    init(_ xyz: SIMD3<Float>, _ w: Float) {
        self.init(xyz.x, xyz.y, xyz.z, w)
    }
    
    var hasNaN: Bool {
        return x.isNaN || y.isNaN || z.isNaN || w.isNaN
    }
    
    func almostEqual(_ value: SIMD4<Float>, within tolerance: Float) -> Bool {
        return length(self - value) <= tolerance
    }
}

