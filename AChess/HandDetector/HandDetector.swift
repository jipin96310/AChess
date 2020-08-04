//
//  HandDetector.swift
//  AChess
//
//  Created by zhaoheng sun on 8/4/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import CoreML
import Vision
import UIKit

public class HandDetector {
    // MARK: - Variables

    private let visionQueue = DispatchQueue(label: "com.zhs.ARChess.visionqueue")

    private lazy var predictionRequest: VNCoreMLRequest = {
        // Load the ML model through its generated class and create a Vision request for it.
        do {
            let model = try VNCoreMLModel(for: HandModel().model)
            let request = VNCoreMLRequest(model: model)
            // This setting determines if images are scaled or cropped to fit our 224x224 input size. Here we try scaleFill so we don't cut part of the image.
            request.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFill
            return request
        } catch {
            fatalError("can't load Vision ML model: \(error)")
        }
    }()
    private lazy var gestureRequest: VNCoreMLRequest = {
        // Load the ML model through its generated class and create a Vision request for it.
        do {
          
            let model = try VNCoreMLModel(for:  hand().model)
            let request = VNCoreMLRequest(model: model)
            // This setting determines if images are scaled or cropped to fit our 224x224 input size. Here we try scaleFill so we don't cut part of the image.
            return request
        } catch {
            fatalError("can't load Vision ML model: \(error)")
        }
    }()
    // MARK: - Public functions

    public func performDetection(inputBuffer: CVPixelBuffer, _ orientation: UIDeviceOrientation?, completion: @escaping (_ outputBuffer: CVPixelBuffer?, _ error: Error?, _ gesture: String) -> Void) {
        // Right orientation because the pixel data for image captured by an iOS device is encoded in the camera sensor's native landscape orientation
        var requestHandler = VNImageRequestHandler(cvPixelBuffer: inputBuffer, orientation: .right)
        if orientation != nil {
            if (orientation == .portrait) {
               requestHandler = VNImageRequestHandler(cvPixelBuffer: inputBuffer, orientation: .right)
            } else if (orientation == .landscapeLeft) {
                requestHandler = VNImageRequestHandler(cvPixelBuffer: inputBuffer, orientation: .up)
            }
            
        }
        // We perform our CoreML Requests asynchronously.
        visionQueue.async {
            // Run our CoreML Request
            do {
                try requestHandler.perform([self.predictionRequest])
                try requestHandler.perform([self.gestureRequest])
                guard let observation = self.predictionRequest.results?.first as? VNPixelBufferObservation else {
                    fatalError("Unexpected result type from VNCoreMLRequest")
                }
                guard let observationGesture = self.gestureRequest.results?.first as? VNClassificationObservation  else {
                    fatalError("Unexpected result type from VNCoreMLRequest")
                }
                //guard let firstObservation = observationGesture.first else {return}
                // The resulting image (mask) is available as observation.pixelBuffer
                completion(observation.pixelBuffer, nil, observationGesture.identifier)
            } catch {
                completion(nil, error, "")
            }
        }
    }
    public func suspendDect() {
        visionQueue.suspend()
    }
}
