//
//  ChessNode.swift
//  archess
//
//  Created by zhaoheng sun on 1/12/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import SceneKit

public class baseChessNode: SCNNode {
    // MARK: - Lifecycle
    var atk = 0
    var def = 1
    private let atkTextNode = TextNode()
    var atkString: String? {
        didSet {
            atkTextNode.string = atkString
        }
    }
    
    override init()
       {
        super.init()
        let curNode = createChess()
        self.addChildNode(curNode)
        if let atkLabelNode = curNode.childNode(withName: "detailLabel", recursively: true) {
            atkLabelNode.addChildNode(atkTextNode)
        }
       }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
//    public func plusPoints() {
//        handPoints += 1
//    }
//    public func subPoints() {
//        if handPoints > 0 {
//            handPoints -= 1
//        } else {
//            handPoints = 0
//        }
//    }
}
