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
    func removeAndClearFromParentNode() {
        self.geometry?.firstMaterial!.normal.contents = nil
        self.geometry?.firstMaterial!.diffuse.contents = nil
        self.removeFromParentNode()
    }
    func fixCategoryMasks(mask: Int) {
        self.categoryBitMask = mask
        if let body = physicsBody {
            body.categoryBitMask = mask
        } else {
            if let geo = geometry {
                let shape = SCNPhysicsShape(geometry: geo, options: nil)
                let body = SCNPhysicsBody(type: SCNPhysicsBodyType.static, shape: shape)
                body.categoryBitMask = mask
                physicsBody = body
            }
        }
        for child in childNodes {
            child.fixCategoryMasks(mask: mask)
        }
    }
    
    
    func fixMaterials() {
        // walk down the scenegraph and update all children
        fixNormalMaps()
    
        // establish paint colors
//        copyGeometryForPaintColors()
//        setPaintColors()
    }
    
    private func fixNormalMap(_ geometry: SCNGeometry) {
        for material in geometry.materials {
            let prop = material.normal
            // astc needs gggr and .ag to compress to L+A,
            //   but will compress rg01 to RGB single plane (less quality)
            // bc/eac/explicit/no compression use rg01 and .rg
            //   rg01 is easier to see and edit in texture editors
            
            // set the normal to RED | GREEN (rg01 compression)
            // uses single plane on ASTC, dual on BC5/EAC_RG11/Explicit
            prop.textureComponents = [.red, .green]
            
            // set the normal to ALPHA | GREEN (gggr compression)
            // uses dual plane for ASTC, BC3nm
            // prop.textureComponents = [.alpha, .green]
        }
    }
    private struct AssociatedKey {
        static var rootID: String? = nil
    }
    
      public var rootID: String {
          get {
              return objc_getAssociatedObject(self, &AssociatedKey.rootID) as? String ?? ""
          }
          
          set {
              objc_setAssociatedObject(self, &AssociatedKey.rootID, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
          }
      }
    // fix the normal map reconstruction on scn files for compressed textures
    
    func fixNormalMaps() {
        if let curRoot = parent?.rootID {
            rootID = curRoot
        }
        if let geometry = geometry {
            fixNormalMap(geometry)
            // these will often just have the same material applied
            if let lods = geometry.levelsOfDetail {
                for lod in lods {
                    if let geometry = lod.geometry {
                        fixNormalMap(geometry)
                    }
                }
            }
        }
        
        for child in childNodes {
            child.fixNormalMaps()
        }
    }
    var simdBoundingBox: (min: SIMD3<Float>, max: SIMD3<Float>) {
          get {
              return (SIMD3<Float>(boundingBox.min), SIMD3<Float>(boundingBox.max))
          }
          set {
              boundingBox = (min: SCNVector3(newValue.min), max: SCNVector3(newValue.max))
          }
      }
    var gameObject: GameObject? {
           get { return entity as? GameObject }
           set { entity = newValue }
       }
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
    func nearestParentGameObject() -> GameObject? {
        if let result = gameObject { return result }
        if let parent = parent { return parent.nearestParentGameObject() }
        return nil
    }

    func findNodeWithPhysicsBody() -> SCNNode? {
        return findNodeWithPhysicsBodyHelper(node: self)
    }
    
    func findNodeWithGeometry() -> SCNNode? {
        return findNodeWithGeometryHelper(node: self)
    }
    
 
    
    var typeIdentifier: String? {
        if let name = name, !name.hasPrefix("_") {
            return name.split(separator: "_").first.map { String($0) }
        } else {
            return nil
        }
    }
    var horizontalSize: SIMD2<Float> {
        let (minBox, maxBox) = simdBoundingBox

        // Scene is y-up, horizontal extent is calculated on x and z
        let sceneWidth = abs(maxBox.x - minBox.x)
        let sceneLength = abs(maxBox.z - minBox.z)
        return SIMD2<Float>(sceneWidth, sceneLength)
    }
    
    private func findNodeWithPhysicsBodyHelper(node: SCNNode) -> SCNNode? {
        if node.physicsBody != nil {
            return node
        }
        for child in node.childNodes {
            if shouldContinueSpecialNodeSearch(node: child) {
                if let childWithPhysicsBody = findNodeWithPhysicsBodyHelper(node: child) {
                    return childWithPhysicsBody
                }
            }
        }
        return nil
    }
    
    private func findNodeWithGeometryHelper(node: SCNNode) -> SCNNode? {
        if node.geometry != nil {
            return node
        }
        for child in node.childNodes {
            if shouldContinueSpecialNodeSearch(node: child) {
                if let childWithGeosBody = findNodeWithGeometryHelper(node: child) {
                    return childWithGeosBody
                }
            }

        }
        return nil
    }
    private func shouldContinueSpecialNodeSearch(node: SCNNode) -> Bool {
           // end geo + physics search when a system collection is found
           if let isEndpoint = node.value(forKey: "isEndpoint") as? Bool, isEndpoint {
               return false
           }
           
           return true
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
extension CGPoint {
    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}
public func clamp<T>(_ value: T, _ minValue: T, _ maxValue: T) -> T where T: Comparable {
    return min(max(value, minValue), maxValue)
}

@objc public extension UIStackView {
    
    /// 设置子视图显示比例(此方法前请设置 .axis/.orientation)
    func setSubViewMultiplier(_ multiplier: CGFloat, at index: Int) {
        if index < subviews.count {
            let element = subviews[index];
            if self.axis == .horizontal {
                element.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: multiplier).isActive = true

            } else {
                element.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: multiplier).isActive = true
            }
        }
    }
}

extension SCNMaterial {
    convenience init(diffuse: Any?) {
        self.init()
        self.diffuse.contents = diffuse
        isDoubleSided = true
        lightingModel = .physicallyBased
    }
}

extension SCNMaterialProperty {
    var simdContentsTransform: float4x4 {
        get {
            return float4x4(contentsTransform)
        }
        set(newValue) {
            contentsTransform = SCNMatrix4(newValue)
        }
    }
}




