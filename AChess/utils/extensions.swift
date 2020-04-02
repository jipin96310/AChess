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


