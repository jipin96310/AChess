//
//  utils.swift
//  archess
//
//  Created by zhaoheng sun on 12/29/19.
//  Copyright © 2019 zhaoheng sun. All rights reserved.
//

import Foundation
import ARKit

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
