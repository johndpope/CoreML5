//
//  ViewController.swift
//  CoreML5-text
//
//  Created by 刘文 on 2017/10/25.
//  Copyright © 2017年 刘文. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController {

    @IBOutlet var resultLabel: UILabel!
    @IBOutlet weak var textImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.identifyText()
    }
    
    func identifyText() {
        var textLayers : [CAShapeLayer] = []
        
        let request = VNDetectTextRectanglesRequest { (request, error) in
            guard let observations = request.results as? [VNTextObservation] else {
                fatalError("unexpected result type from VNDetectTextRectanglesRequest")
            }
            
            textLayers = self.addTextShapesToImageViewByObservations(observations, withImageView: self.textImageView)
        }
        
        if let image = self.textImageView.image, let cgImage = image.cgImage {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            guard let _ = try? handler.perform([request]) else {
                return print("Could not perform text Detection Request!")
            }
            
            for layer in textLayers {
                textImageView.layer.addSublayer(layer)
            }
        }
    }

    func addTextShapesToImageViewByObservations(_ observations: [VNTextObservation], withImageView imageView: UIImageView) -> [CAShapeLayer] {
        
        let layers: [CAShapeLayer] = observations.map { observation in
            let w = observation.boundingBox.size.width * textImageView.bounds.width
            let h = observation.boundingBox.size.height * textImageView.bounds.height
            let x = observation.boundingBox.origin.x * textImageView.bounds.width
            let y = (1 - observation.boundingBox.origin.y) * textImageView.bounds.height - h
            
            let layer = CAShapeLayer()
            layer.frame = CGRect(x: x , y: y, width: w, height: h)
            layer.borderColor = UIColor.green.cgColor
            layer.borderWidth = 2
            layer.cornerRadius = 3
            
            return layer
        }
        return layers
    }

}

