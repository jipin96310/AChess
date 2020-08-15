//
//  prePlane.swift
//  AChess
//
//  Created by zhaoheng sun on 7/5/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation
import ARKit

class PrePlane: SCNNode {

    
        /// The minimum size of the board in meters
        static let minimumScale: Float = 0.3
        
        /// The maximum size of the board in meters
        static let maximumScale: Float = 10.0 // 15x27m @ 10, 1.5m x 2.7m @ 1

        
        /// The color of the border
        static let borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        /// Indicates whether the segments of the border are disconnected.
        private var isBorderOpen = false
        
        
        /// The game board's most recent positions.
        private var recentPositions: [SIMD3<Float>] = []
        
        /// The game board's most recent rotation angles.
        private var recentRotationAngles: [Float] = []
        
        /// Previously visited plane anchors.
        private var anchorsOfVisitedPlanes: Set<ARAnchor> = []
        
        /// The node used to visualize the game border.
        private let borderNode = SCNNode()
        
        // MARK: - Properties
        /// The BoardAnchor in the scene
        var anchor: CustomAnchor?
        
        /// Indicates whether the border is currently hidden
        var isBorderHidden: Bool {
            return borderNode.isHidden || borderNode.action(forKey: "hide") != nil
        }

       /// The level's preferred size.
       /// This is used both to set the aspect ratio and to determine
       /// the default size.
       var preferredSize: CGSize = CGSize(width: 2.4, height: 1.6) {
           didSet {
               updateBorderAspectRatio()
           }
       }

       /// The aspect ratio of the level.
       var aspectRatio: Float { return Float(preferredSize.height / preferredSize.width) }

   
       
       /// List of the segments in the border.
       private var borderSegments: [PrePlane.BorderSegment] = []
       
       // MARK: - Initialization
       override init() {
           super.init()
           
           // Set initial game board scale
           simdScale = SIMD3<Float>(repeating: PrePlane.minimumScale)
           
           // Create all border segments
//           Corner.allCases.forEach { corner in
//               Alignment.allCases.forEach { alignment in
//                   let borderSize = CGSize(width: 1, height: CGFloat(aspectRatio))
//                   //let borderSegment = BorderSegment(corner: corner, alignment: alignment, borderSize: borderSize)
//
//                   //borderSegments.append(borderSegment)
//                   //borderNode.addChildNode(borderSegment)
//               }
//           }
           
           // Create fill plane
           borderNode.addChildNode(fillPlane)
           
           // Orient border to XZ plane and set aspect ratio
           borderNode.eulerAngles.x = .pi / 2
           borderNode.isHidden = true
           
           addChildNode(borderNode)
       }
       
       required init?(coder aDecoder: NSCoder) {
           fatalError("\(#function) has not been implemented")
       }

       // MARK: - Appearance
       /// Hides the border.
       func hideBorder(duration: TimeInterval = 0.5) {
           guard borderNode.action(forKey: "hide") == nil else { return }
           
           borderNode.removeAction(forKey: "unhide")
           borderNode.runAction(.fadeOut(duration: duration), forKey: "hide") {
               self.borderNode.isHidden = true
           }
       }
       
       /// Unhides the border.
       func unhideBorder() {
           guard borderNode.action(forKey: "unhide") == nil else { return }
           
           borderNode.removeAction(forKey: "hide")
           borderNode.runAction(.fadeIn(duration: 0.5), forKey: "unhide")
           borderNode.isHidden = false
       }
       
       /// Updates the game board with the latest hit test result and camera.
       func update(with hitTestResult: ARHitTestResult, camera: ARCamera) {
           if isBorderHidden {
               unhideBorder()
           }

//           if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor {
//               performCloseAnimation(flash: !anchorsOfVisitedPlanes.contains(planeAnchor))
//               anchorsOfVisitedPlanes.insert(planeAnchor)
//           } else {
//               performOpenAnimation()
//           }
           
           updateTransform(with: hitTestResult, camera: camera)
       }
       
       func reset() {
           borderNode.removeAllActions()
           borderNode.isHidden = true
           recentPositions.removeAll()
           recentRotationAngles.removeAll()
           isHidden = false
       }

       /// Incrementally scales the board by the given amount
       func scale(by factor: Float) {
           // assumes we always scale the same in all 3 dimensions
           let currentScale = simdScale.x
           let newScale = mediant(currentScale * factor, PrePlane.minimumScale, PrePlane.maximumScale)
           simdScale = SIMD3<Float>(repeating: newScale)
       }

       func useDefaultScale() {
           let scale = preferredSize.width
           simdScale = SIMD3<Float>(repeating: Float(scale))
       }

       // MARK: Helper Methods
       /// Update the transform of the game board with the latest hit test result and camera
       private func updateTransform(with hitTestResult: ARHitTestResult, camera: ARCamera) {
           let position = hitTestResult.worldTransform.trans
           
           // Average using several most recent positions.
           recentPositions.append(position)
           recentPositions = Array(recentPositions.suffix(10))
           
           // Move to average of recent positions to avoid jitter.
           let average = recentPositions.reduce(SIMD3<Float>(repeating: 0), { $0 + $1 }) / Float(recentPositions.count)
           simdPosition = average
           
           // Orient bounds to plane if possible
           if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor {
               orientToPlane(planeAnchor, camera: camera)
               scaleToPlane(planeAnchor)
           } else {
               // Fall back to camera orientation
               orientToCamera(camera)
               simdScale = SIMD3<Float>(repeating: PrePlane.minimumScale)
           }
           
           // Remove any animation duration if present
           SCNTransaction.animationDuration = 0
       }
       
       private func orientToCamera(_ camera: ARCamera) {
           rotate(to: camera.eulerAngles.y)
       }
       
       private func orientToPlane(_ planeAnchor: ARPlaneAnchor, camera: ARCamera) {
           // Get board rotation about y
           simdOrientation = simd_quatf(planeAnchor.transform)
           var boardAngle = simdEulerAngles.y
           
           // If plane is longer than deep, rotate 90 degrees
           if planeAnchor.extent.x > planeAnchor.extent.z {
               boardAngle += .pi / 2
           }
           
           // Normalize angle to closest 180 degrees to camera angle
           boardAngle = boardAngle.standardizedAngle(forMinimalRotationTo: camera.eulerAngles.y, increment: .pi)
           
           rotate(to: boardAngle)
       }
       
       private func rotate(to angle: Float) {
           // Avoid interpolating between angle flips of 180 degrees
           let previouAngle = recentRotationAngles.reduce(0, { $0 + $1 }) / Float(recentRotationAngles.count)
           if abs(angle - previouAngle) > .pi / 2 {
               recentRotationAngles = recentRotationAngles.map { $0.standardizedAngle(forMinimalRotationTo: angle, increment: .pi) }
           }
           
           // Average using several most recent rotation angles.
           recentRotationAngles.append(angle)
           recentRotationAngles = Array(recentRotationAngles.suffix(20))
           
           // Move to average of recent positions to avoid jitter.
           let averageAngle = recentRotationAngles.reduce(0, { $0 + $1 }) / Float(recentRotationAngles.count)
           simdRotation = SIMD4<Float>(0, 1, 0, averageAngle)
       }
       
       private func scaleToPlane(_ planeAnchor: ARPlaneAnchor) {
           // Determine if extent should be flipped (plane is 90 degrees rotated)
           let planeXAxis = planeAnchor.transform.columns.0.xyz
           let axisFlipped = abs(dot(planeXAxis, simdWorldRight)) < 0.5
           
           // Flip dimensions if necessary
           var planeExtent = planeAnchor.extent
           if axisFlipped {
               planeExtent = vector3(planeExtent.z, 0, planeExtent.x)
           }
           
           // Scale board to the max extent that fits in the plane
           var width = min(planeExtent.x, PrePlane.maximumScale)
           let depth = min(planeExtent.z, width * aspectRatio)
           width = depth / aspectRatio
           simdScale = SIMD3<Float>(repeating: width)
           
           // Adjust position of board within plane's bounds
           var planeLocalExtent = SIMD3<Float>(width, 0, depth)
           if axisFlipped {
               planeLocalExtent = vector3(planeLocalExtent.z, 0, planeLocalExtent.x)
           }
           adjustPosition(withinPlaneBounds: planeAnchor, extent: planeLocalExtent)
       }
       
       private func adjustPosition(withinPlaneBounds planeAnchor: ARPlaneAnchor, extent: SIMD3<Float>) {
           var positionAdjusted = false
           let worldToPlane = planeAnchor.transform.inverse
           
           // Get current position in the local plane coordinate space
           var planeLocalPosition = (worldToPlane * simdTransform.columns.3)
           
           // Compute bounds min and max
           let boardMin = planeLocalPosition.xyz - extent / 2
           let boardMax = planeLocalPosition.xyz + extent / 2
           let planeMin = planeAnchor.center - planeAnchor.extent / 2
           let planeMax = planeAnchor.center + planeAnchor.extent / 2
           
           // Adjust position for x within plane bounds
           if boardMin.x < planeMin.x {
               planeLocalPosition.x += planeMin.x - boardMin.x
               positionAdjusted = true
           } else if boardMax.x > planeMax.x {
               planeLocalPosition.x -= boardMax.x - planeMax.x
               positionAdjusted = true
           }
           
           // Adjust position for z within plane bounds
           if boardMin.z < planeMin.z {
               planeLocalPosition.z += planeMin.z - boardMin.z
               positionAdjusted = true
           } else if boardMax.z > planeMax.z {
               planeLocalPosition.z -= boardMax.z - planeMax.z
               positionAdjusted = true
           }
           
           if positionAdjusted {
               simdPosition = (planeAnchor.transform * planeLocalPosition).xyz
           }
       }
       
       private func updateBorderAspectRatio() {
           let borderSize = CGSize(width: 1, height: CGFloat(aspectRatio))
           for segment in borderSegments {
               segment.borderSize = borderSize
           }
           if let plane = fillPlane.geometry as? SCNPlane {
               let length = 1 - 2 * BorderSegment.thickness
               plane.height = length * CGFloat(aspectRatio)
               let textureScale = float4x4(scale: SIMD3<Float>(40, 40 * aspectRatio, 1))
               plane.firstMaterial?.diffuse.simdContentsTransform = textureScale
               plane.firstMaterial?.emission.simdContentsTransform = textureScale
           }
           isBorderOpen = false
       }
       
       // MARK: Animations
//       private func performOpenAnimation() {
//           guard !isBorderOpen, !isAnimating else { return }
//           isBorderOpen = true
//           isAnimating = true
//
//           // Open animation
//
//           SCNTransaction.animate(duration: PrePlane.animationDuration / 4, animations: {
//
//               SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
//               self.borderNode.opacity = 1.0
//               for segment in self.borderSegments {
//                   segment.open()
//               }
//
//               // Add a scale/bounce animation.
//               SCNTransaction.animate(duration: GameBoard.animationDuration / 4, animations: {
//                   SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
//                   self.simdScale = SIMD3<Float>(repeating: GameBoard.minimumScale)
//               })
//           }, completion: {
//               // completion is run on main-thread
//               SCNTransaction.animate(duration: 0.0, animations: {
//                   self.borderNode.runAction(pulseAction(), forKey: "pulse")
//                   self.isAnimating = false
//               })
//           })
//       }
       
//       private func performCloseAnimation(flash: Bool = false) {
//           guard isBorderOpen, !isAnimating else { return }
//           isBorderOpen = false
//           isAnimating = true
//
//           borderNode.removeAction(forKey: "pulse")
//           borderNode.opacity = 1.0
//
//           // Close animation
//           SCNTransaction.animate(duration: PrePlane.animationDuration / 2, animations: {
//               SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
//               borderNode.opacity = 0.99
//           }, completion: {
//               SCNTransaction.animate(duration: PrePlane.animationDuration / 4, animations: {
//                   SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
//                   for segment in self.borderSegments {
//                       segment.close()
//                   }
//               }, completion: {
//                   self.isAnimating = false
//               })
//           })
//
//           if flash {
//               let waitAction = SCNAction.wait(duration: GameBoard.animationDuration * 0.75)
//               let fadeInAction = SCNAction.fadeOpacity(to: 0.6, duration: GameBoard.animationDuration * 0.125)
//               let fadeOutAction = SCNAction.fadeOpacity(to: 0.0, duration: GameBoard.animationDuration * 0.125)
//               fillPlane.runAction(.sequence([waitAction, fadeOutAction, fadeInAction]))
//           }
//       }
       
       // MARK: Convenience Methods
       private lazy var fillPlane: SCNNode = {
           let length = 1 - 2 * BorderSegment.thickness
           let plane = SCNPlane(width: length, height: length * CGFloat(aspectRatio))
           let node = SCNNode(geometry: plane)
           node.name = "fillPlane"
           node.opacity = 0.6
           
           let material = plane.firstMaterial!
           material.diffuse.contents = UIColor.gray
//           let textureScale = float4x4(scale: SIMD3<Float>(40, 40 * aspectRatio, 1))
//           material.diffuse.simdContentsTransform = textureScale
//           material.emission.contents = UIImage(named: "gameassets.scnassets/textures/grid.png")
//           material.emission.simdContentsTransform = textureScale
           material.diffuse.wrapS = .repeat
           material.diffuse.wrapT = .repeat
           material.isDoubleSided = true
           material.ambient.contents = UIColor.black
           material.lightingModel = .constant
           
           return node
       }()
    
    enum Corner: CaseIterable {
           case topLeft
           case topRight
           case bottomLeft
           case bottomRight
           
           var u: Float {
               switch self {
               case .topLeft:     return -1
               case .topRight:    return 1
               case .bottomLeft:  return -1
               case .bottomRight: return 1
               }
           }
           
           var v: Float {
               switch self {
               case .topLeft:     return -1
               case .topRight:    return -1
               case .bottomLeft:  return 1
               case .bottomRight: return 1
               }
           }
       }
       
       enum Alignment: CaseIterable {
           case horizontal
           case vertical
           
           func xOffset(for size: CGSize) -> Float {
               switch self {
               case .horizontal: return Float(size.width / 2 - BorderSegment.thickness) / 2
               case .vertical:   return Float(size.width / 2)
               }
           }
           
           func yOffset(for size: CGSize) -> Float {
               switch self {
               case .horizontal: return Float(size.height / 2 - BorderSegment.thickness / 2)
               case .vertical:   return Float(size.height / 2) / 2
               }
           }
       }
       
       class BorderSegment: SCNNode {
           
           // MARK: - Configuration & Initialization
           
           /// Thickness of the border lines.
           static let thickness: CGFloat = 0.012
           
           /// The scale of segment's length when in the open state
           static let openScale: Float = 0.4
           
           let corner: Corner
           let alignment: Alignment
           let plane: SCNPlane
           
           init(corner: Corner, alignment: Alignment, borderSize: CGSize) {
               self.corner = corner
               self.alignment = alignment
               
               plane = SCNPlane(width: BorderSegment.thickness, height: BorderSegment.thickness)
               self.borderSize = borderSize
               super.init()
               
               let material = plane.firstMaterial!
               material.diffuse.contents = PrePlane.borderColor
               material.emission.contents = PrePlane.borderColor
               material.isDoubleSided = true
               material.ambient.contents = UIColor.black
               material.lightingModel = .constant
               geometry = plane
               opacity = 0.8
           }
           
           var borderSize: CGSize {
               didSet {
                   switch alignment {
                   case .horizontal: plane.width = borderSize.width / 2
                   case .vertical:   plane.height = borderSize.height / 2
                   }
                   simdScale = SIMD3<Float>(repeating: 1)
                   simdPosition = SIMD3<Float>(corner.u * alignment.xOffset(for: borderSize),
                                         corner.v * alignment.yOffset(for: borderSize),
                                         0)
               }
           }
           
           required init?(coder aDecoder: NSCoder) {
               fatalError("\(#function) has not been implemented")
           }
           
           // MARK: - Animating Open/Closed
           
           func open() {
               var offset = SIMD2<Float>()
               if alignment == .horizontal {
                   simdScale = SIMD3<Float>(BorderSegment.openScale, 1, 1)
                   offset.x = (1 - BorderSegment.openScale) * Float(borderSize.width) / 4
               } else {
                   simdScale = SIMD3<Float>(1, BorderSegment.openScale, 1)
                   offset.y = (1 - BorderSegment.openScale) * Float(borderSize.height) / 4
               }
               
               simdPosition = SIMD3<Float>(corner.u * alignment.xOffset(for: borderSize) + corner.u * offset.x,
                                     corner.v * alignment.yOffset(for: borderSize) + corner.v * offset.y,
                                     0)
           }
           
           func close() {
               simdScale = SIMD3<Float>(repeating: 1)
               simdPosition = SIMD3<Float>(corner.u * alignment.xOffset(for: borderSize),
                                     corner.v * alignment.yOffset(for: borderSize),
                                     0)
           }
       }
    
}

