//
//  boardChessesStruct.swift
//  AChess
//
//  Created by zhaoheng sun on 7/25/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import Foundation

public struct boardChessesStruct: Codable {
    
   
    var boardChesses: [[codableChessStruct]] = []//棋子
    

    init(boardChesses: [[codableChessStruct]]) {
        self.boardChesses = boardChesses
    }

}
