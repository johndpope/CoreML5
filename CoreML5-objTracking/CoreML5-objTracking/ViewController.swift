//
//  ViewController.swift
//  CoreML5-objTracking
//
//  Created by 刘文 on 2017/10/25.
//  Copyright © 2017年 刘文. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {

    // Vision
    var objObservation: VNDetectedObjectObservation?
//    var trackObjRequest: VNTrackObjectRequest?
    let sequenceRequestHandler = VNSequenceRequestHandler()
    
    lazy var overlayView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.green.cgColor
        view.layer.borderWidth = 5
        view.layer.cornerRadius = 8
        view.backgroundColor = .clear
        
        self.view.addSubview(view)
        return view
    }()
    
    // AVFoundation
    lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back), let input = try? AVCaptureDeviceInput(device: device) else {
            return session
        }
        session.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "ObjectTrackingQueue"))
        session.addOutput(output)
        
        return session
    }()
    
    lazy var captureLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.captureSession.startRunning()
        
        self.view.layer.addSublayer(self.captureLayer)
        
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tapGesCallback(tapGes:)))
        self.view.addGestureRecognizer(tapGes)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.captureLayer.frame = self.view.frame
    }
    
    @objc func tapGesCallback(tapGes: UITapGestureRecognizer) {
        self.overlayView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        self.overlayView.center = tapGes.location(in: self.view)
        
        var convertedRect = self.captureLayer.metadataOutputRectConverted(fromLayerRect: self.overlayView.frame)
        convertedRect.origin.y = 1 - convertedRect.origin.y - self.overlayView.frame.height / self.view.frame.height
        
        self.objObservation = VNDetectedObjectObservation(boundingBox: convertedRect)
    }
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        guard let observation = self.objObservation else {
            return
        }
        
        let trackObjRequest = VNTrackObjectRequest(detectedObjectObservation: observation, completionHandler: trackObjRequestCallback)
        trackObjRequest.trackingLevel = .accurate
        
        try! self.sequenceRequestHandler.perform([trackObjRequest], on: imageBuffer)
    }
    
    func trackObjRequestCallback(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let observation = request.results?.first as? VNDetectedObjectObservation else {
                self.overlayView.frame = .zero
                return
            }
            self.objObservation = observation
            
            var boundingBox = observation.boundingBox
            boundingBox.origin.y = 1 - boundingBox.origin.y - boundingBox.height
            let frame = self.captureLayer.layerRectConverted(fromMetadataOutputRect: boundingBox)
            self.overlayView.frame = frame
        }
    }
}

