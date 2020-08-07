//
//  CVPixelBufferHelper.swift
//  AChess
//
//  Created by zhaoheng sun on 8/4/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//
import CoreVideo

extension CVPixelBuffer {
    func searchTopPoint(handGesture: String) -> [[CGPoint]]? {
        // Get width and height of buffer
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)

        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)

        // Lock buffer
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))

        // Unlock buffer upon exiting
        defer {
            CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        }

        //var returnPoint: CGPoint?
        var finalPoints: [[CGPoint]] = []
        var rawPoints: [[[CGPoint]]] = []
        var whitePixelsCount = 0
        //a variable which will decrease from bottom to top
        //
        if let baseAddress = CVPixelBufferGetBaseAddress(self) {
            let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

            // we look at pixels from bottom to top
            for y in (0 ..< height).reversed() {
                if y % 4 != 0 { // every 4 pixel
                    continue
                }
                //
                var curRowPoints: [CGPoint]? = []
                //record blank pixels
                var blankPointsNum = 0
                var curCountFlag = 1
                for x in (0 ..< width).reversed() {
                    // We look at top groups of 5 non black pixels
                    let pixel = buffer[y * bytesPerRow + x * 4]
                    let abovePixel = buffer[min(y + 1, height) * bytesPerRow + x * 4]
                    let belowPixel = buffer[max(y - 1, 0) * bytesPerRow + x * 4]
                    let rightPixel = buffer[y * bytesPerRow + min(x + 1, width) * 4]
                    let leftPixel = buffer[y * bytesPerRow + max(x - 1, 0) * 4]

                    if pixel > 0 && abovePixel > 0 && belowPixel > 0 && rightPixel > 0 && leftPixel > 0 {
                        
                        if finalPoints.count > 0 && finalPoints.last!.count > 0 {
                            let curHeightStr = String(format: "%.4f", finalPoints.last!.last!.y)
                            if let curHeight = Float(curHeightStr) {
                                if abs(Float(y) - curHeight * Float(height)) > 20 { //y轴超过50像素点
                                    print(height, curHeight)
                                    if whitePixelsCount > 4 {
                                        rawPoints.append(finalPoints)
                                        whitePixelsCount = 0
                                    }
                                    
                                    finalPoints = []
                                }
                            }
                            
                        }
//                        let newPoint = CGPoint(x: x, y: y)
//                        // we return a normalized point (0-1)
//                        returnPoint = CGPoint(x: newPoint.x / CGFloat(width), y: newPoint.y / CGFloat(height))
//                        whitePixelsCount += 1
                        if curRowPoints!.count <= curCountFlag{
                            let newPoint = CGPoint(x: x, y: y)
                            curRowPoints!.append(CGPoint(x: newPoint.x / CGFloat(width), y: newPoint.y / CGFloat(height)))
                            whitePixelsCount += 1
                        } else {
                            if(blankPointsNum >= 10) {
                                let newPoint = CGPoint(x: x, y: y)
                                curRowPoints!.append(CGPoint(x: newPoint.x / CGFloat(width), y: newPoint.y / CGFloat(height)))
                                whitePixelsCount += 1
                                ///clear flag/
                                blankPointsNum = 0
                                curCountFlag += 2
                            } else {
                                curRowPoints?.removeLast()
                                whitePixelsCount -= 1
                                let newPoint = CGPoint(x: x, y: y)
                                curRowPoints!.append(CGPoint(x: newPoint.x / CGFloat(width), y: newPoint.y / CGFloat(height)))
                                whitePixelsCount += 1
                            }
                        }
                    } else {
                        blankPointsNum += 1
                    }
                }
                if(curRowPoints!.count > 0 && curRowPoints!.count % 2 == 0) { //必须有头有尾
                    if let twoArr = randomSplit(arr: curRowPoints!) {
                        var spaceArr:[(Int, CGFloat)] = []
                        for i in 1 ..< twoArr.count { //排序间距
                            let curSpace = twoArr[i][0].x - twoArr[i - 1][0].x
                            if spaceArr.count == 0 {
                                spaceArr.append((i, twoArr[i][0].x - twoArr[i - 1][0].x))
                            } else {
                                for j in 0 ..< spaceArr.count {
                                  if spaceArr[j].1 >= curSpace {
                                    spaceArr.insert((i, curSpace), at: j)
                                    break
                                   }
                                }
                            }
                          
                        }
                        if spaceArr.count > 1 {
                            var indexArr:[Int] = []
                            var removeIndex:[Int] = []
                            for j in 1 ..< spaceArr.count {
                                if (spaceArr[j].1 > 4 * spaceArr[j - 1].1) { //当有一个距离点突增3倍时，则应该就是干扰点
                                    for i in j ..< spaceArr.count { //剩下的点都是鉴定是否过滤的
                                        indexArr.append(spaceArr[i].0)
                                    }
                                    break;
                                }
                            }
                            for i in 0 ..< twoArr.count {
                                if indexArr.contains(i) { //如果包含干扰点index
                                    removeIndex.append(i - 1)
                                } else {
                                    if removeIndex.count > 0 {
                                        break
                                    }
                                }
                            }
                            for i in (0 ..< twoArr.count).reversed() {
                                if indexArr.contains(i) {
                                    removeIndex.append(i)
                                } else {
                                    break
                                }
                            }
                            let fixedArr = multiDeleteArr(index: removeIndex, arr: twoArr)
                            curRowPoints = []
                            fixedArr.forEach{ item in
                                curRowPoints?.append(contentsOf: item)
                            }
                        }
                    }
                   
                    finalPoints.append(curRowPoints!)
                }
                
            } //for y loop end
        }

        // We count the number of pixels in our frame. If the number is too low then we return nil because it means it's detecting a false positive
        rawPoints.forEach{ points in
            if points.count > finalPoints.count {
                finalPoints = points
            }
        }
        //print(rawPoints.count)
        return finalPoints
    }
}
