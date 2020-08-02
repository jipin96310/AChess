//
//  RootViewController.swift
//  AChess
//
//  Created by zhaoheng sun on 8/1/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import UIKit
import SceneKit

class RootViewController: UIViewController {
    

    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet var curView: UIView!
    @IBOutlet weak var seaImage: UIImageView!
    @IBOutlet weak var mountainImage: UIImageView!
    @IBOutlet weak var plainImage: UIImageView!
    @IBOutlet weak var plainView: UIView!
    @IBOutlet weak var seaView: UIView!
    @IBOutlet weak var mountainView: UIView!
    

    @IBOutlet weak var playButton: UIButton!
    
    override func viewDidLoad() {
        setBoarder(images: [plainImage,mountainImage])
        
        //playButton.layer.zPosition = 1
        self.view.sendSubviewToBack(sceneView)
        
        UIView.animate(withDuration: 1, delay: 0.01, options: [.curveEaseInOut], animations: {
            
        }, completion: { (finished) in
            UIView.animate(withDuration: 1, delay: 0.01, animations: {
                self.seaImage.alpha = 1
                self.seaImage.center.y += 100
            })
        })
        UIView.animate(withDuration: 1, delay: 0.01, options: [.curveEaseInOut], animations: {
                   
               }, completion: { (finished) in
                UIView.animate(withDuration: 1, delay: 0.51, animations: {
                    self.plainImage.alpha = 1
                    self.plainImage.center.y += 100
                   })
               })
        UIView.animate(withDuration: 1, delay: 0.01, options: [.curveEaseInOut], animations: {
                   
               }, completion: { (finished) in
                   UIView.animate(withDuration: 1, delay: 1.01, animations: {
                    self.mountainImage.alpha = 1
                    self.mountainImage.center.y += 100
                   })
               })
    }
    
    
    func setBoarder(images: [UIImageView]) {
        
        images.forEach{  image in
            let bd = CALayer();
            bd.frame = CGRect(x: 0, y: 0, width: 5, height: image.layer.frame.size.height);
            bd.backgroundColor = UIColor.init(white: 0.5, alpha: 1).cgColor;
            image.layer.addSublayer(bd);
            
        }
        
    }
    
}
