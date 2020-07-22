//
//  PlaneAnchor.swift
//  AChess
//
//  Created by zhaoheng sun on 7/11/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import ARKit
import MultipeerConnectivity.MCPeerID

class CustomAnchor: ARAnchor {
    let size: CGSize
    var anchorID: MCPeerID? = nil
    
    init(transform: float4x4, size: CGSize) {
        self.size = size
        super.init(name: "CustomAnchor", transform: transform)
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.size = aDecoder.decodeCGSize(forKey: "size")
        super.init(coder: aDecoder)
    }

    // this is guaranteed to be called with something of the same class
    required init(anchor: ARAnchor) {
        let other = anchor as! CustomAnchor
        self.size = other.size
        super.init(anchor: other)
    }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(size, forKey: "size")
    }
}
