//
//  actions.swift
//  AChess
//
//  Created by zhaoheng sun on 1/27/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation
import SceneKit

//use when chess is attacking
func attackAction(_ attackerPos: SCNVector3, _ victimPos: SCNVector3) -> SCNAction{
    let adjustLens: Float = attackerPos.z > victimPos.z ? -0.03 : 0.03
    let firstPos = SCNVector3(attackerPos.x, attackerPos.y, attackerPos.z + adjustLens)
    let secondPos = SCNVector3(victimPos.x, victimPos.y, victimPos.z - adjustLens)
    let firstStep = SCNAction.move(to: firstPos, duration: 0.5)
    let secondStep = SCNAction.move(to: secondPos, duration: 1.5)
    let attackTo = SCNAction.sequence([firstStep, secondStep])
    return attackTo
}
//attacking finished
func backToAction(_ backNodePos: SCNVector3, _ attackerNode: baseChessNode, _ attackBoard: Int) -> SCNAction{
    print(attackBoard)
    let adjustLens: Float = attackBoard == BoardSide.allySide.rawValue ? 0.03 : -0.03
    let firstPos = SCNVector3(backNodePos.x, backNodePos.y, backNodePos.z - adjustLens)
    let firstStep = SCNAction.move(to: firstPos, duration: 1.5)
    let secondStep = SCNAction.move(to: backNodePos, duration: 0.5)
    var backSequence = [firstStep, secondStep]
    // if the current node has been eliminated, add fade action
//    if let curNodeBlood = attackerNode.defNum {
//        if curNodeBlood <= 0 {
//            backSequence += [SCNAction.fadeOut(duration: 0.3), SCNAction.removeFromParentNode()]
//        }
//    }
    return SCNAction.sequence(backSequence)
}
func bloodChangeAction(_ changeNodes: [baseChessNode], _ changeNums: [Int]) -> SCNAction { //最多支持两个node
    if changeNodes.count != changeNums.count {
        return SCNAction.customAction(duration: 0, action: { _,_ in
            print("error! the num of nodes is not equal to the num of numbers")
        })
    }

    let bloodSequence : [SCNAction] = [SCNAction.fadeOut(duration: 0.3), SCNAction.removeFromParentNode()]
    return SCNAction.customAction(duration: 1, action: { _,_ in
           for index in 0 ..< changeNodes.count {
               let curNode = changeNodes[index]
               //let otherNode = index == 0 ? changeNodes[1] : changeNodes[0]
               let curBlood = changeNums[index]
                //add explosion effect
                addExplosion(curNode)
               if curBlood > 0 {
                   curNode.defNum = changeNums[index]
               } else {
                   curNode.runAction(SCNAction.sequence(bloodSequence))
               }
           }
    })
}
func damageAppearAction(_ appearNodes: [baseChessNode], _ damageNum: [Int]) -> SCNAction{
    return SCNAction.customAction(duration: 0.1, action: { _,_ in
        for index in 0 ..< appearNodes.count {
            let curNode = appearNodes[index]
            let curDamage = damageNum[index]
            curNode.damageNum = curDamage
        }
    })
}
//func adjustPositionAction(_ rootNodes: [SCNNode], _ chessNodes: [baseChessNode]) -> SCNAction{
//    //
//    
//}
//when chess got attacked but survived
func beAttackedAction(){
    
}
//use when chess got eliminated
func vanishedAction(){
    
}
