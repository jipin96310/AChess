//
//  utils.swift
//  archess
//
//  Created by zhaoheng sun on 12/29/19.
//  Copyright © 2019 zhaoheng sun. All rights reserved.
//

import Foundation
import ARKit
// import scn files as scnnode
public func createCard() -> SCNNode{
    let scene = SCNScene(named: "art.scnassets/baseCard.scn")!
    let baseCardNode = scene.rootNode.childNode(withName: "baseCard", recursively: false)
    return baseCardNode!
}

public func createChess() -> SCNNode{
    let scene = SCNScene(named: "art.scnassets/baseChess.scn")!
    let baseCardNode = scene.rootNode.childNode(withName: "baseChess", recursively: false)
    return baseCardNode!
}


public func createPlayerBoard() -> SCNNode{
    let scene = SCNScene(named: "art.scnassets/playerBoard.scn")!
    let playerBoarderNode = scene.rootNode.childNode(withName: "playerBoard", recursively: false)
    return playerBoarderNode!
}

public func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
public func addExplosion(_ target: SCNNode) { //TODO the explosion effect doesnt look decent
    if let explosion = SCNParticleSystem(named: "particals.scnassets/confetti_explosion.scnp", inDirectory: nil) {
        explosion.loops = false
        explosion.particleLifeSpan = 1
        explosion.birthRate = 1
        //explosion.emissionDuration = CGFloat(1)
        explosion.emitterShape = SCNSphere(radius: 0.02)
        let confettiNode = SCNNode()
        confettiNode.addParticleSystem(explosion)
        confettiNode.position = SCNVector3(0, 0.02, 0)
        //confettiNode.scale = SCNVector3(0.001, 0.001, 0.001)
        target.addChildNode(confettiNode)
        delay(0.1, task: { () in
                confettiNode.removeParticleSystem(explosion)
                confettiNode.removeFromParentNode()
            })
    }
    
}

func isNameButton(_ childNode: SCNNode, _ buttonName: String) -> Bool {
    if childNode.name == buttonName {
        return true
    }
    if childNode.parent == nil {
           return false // target node can't be a parent/ancestor if we have no parent
       }
    if childNode.parent?.name == buttonName {
        return true
    } else {
       return isNameButton(childNode.parent!, buttonName)//递归 查询ancestor
    }
}
//find chess root node
func findChessRootNode(_ childNode: SCNNode) -> baseChessNode?{
    if childNode is baseChessNode {
        return childNode as? baseChessNode // this is the node you're looking for
    }
    if childNode.parent == nil {
        return nil // target node can't be a parent/ancestor if we have no parent
    }
    if childNode.parent is baseChessNode {
        return childNode.parent as? baseChessNode // target node is this node's direct parent
    }
           // otherwise recurse to check parent's parent and so on
    return findChessRootNode(childNode.parent!)
}


//public func adjustChessPosition(_ rootNodes: [SCNNode], _ chessNodes: [baseChessNode]) {
//    
//}

public extension Int {
    /*这是一个内置函数
     lower : 内置为 0，可根据自己要获取的随机数进行修改。
     upper : 内置为 UInt32.max 的最大值，这里防止转化越界，造成的崩溃。
     返回的结果： [lower,upper) 之间的半开半闭区间的数。
     */
    static func randomIntNumber(lower: Int = 0,upper: Int = Int(UInt32.max)) -> Int {
        return lower + Int(arc4random_uniform(UInt32(upper - lower)))
    }
    /**
     生成某个区间的随机数
     */
    static func randomIntNumber(range: Range<Int>) -> Int {
        return randomIntNumber(lower: range.lowerBound, upper: range.upperBound)
    }
}

typealias Task = (_ cancel : Bool) -> Void

func delay(_ time: TimeInterval, task: @escaping ()->()) ->  Task? {

    func dispatch_later(block: @escaping ()->()) {
        let t = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: t, execute: block)
    }
    var closure: (()->Void)? = task
    var result: Task?

    let delayedClosure: Task = {
        cancel in
      if let internalClosure = closure {
            if (cancel == false) {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }

    result = delayedClosure

    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
  return result
}

func cancel(_ task: Task?) {
    task?(true)
}
