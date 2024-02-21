//
//  CameraViewController.swift
//  HandPose
//
//  Created by Viktor Varenik on 21.02.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController {
    private var cameraView: CameraView { view as! CameraView }
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    private var lastDrawPoint: CGPoint?
    private var isFirstSegment = true
    private var lastObservationTimestamp = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handPoseRequest.maximumHandCount = 2
        // Add double tap gesture recognizer for clearing the draw path.
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        recognizer.numberOfTouchesRequired = 1
        recognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(recognizer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            if cameraFeedSession == nil {
                cameraView.previewLayer.videoGravity = .resizeAspectFill
                try setupAVSession()
                cameraView.previewLayer.session = cameraFeedSession
            }
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.cameraFeedSession?.startRunning()
            }
        } catch {
            AppError.display(error, inViewController: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    
    func setupAVSession() throws {
        // Select a front facing camera, make an input.
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw AppError.captureSessionSetup(reason: "Could not find a front facing camera.")
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw AppError.captureSessionSetup(reason: "Could not create video device input.")
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else {
            throw AppError.captureSessionSetup(reason: "Could not add video device input to the session")
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            // Add a video data output.
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            throw AppError.captureSessionSetup(reason: "Could not add video data output to the session")
        }
        session.commitConfiguration()
        cameraFeedSession = session
}
    
    @IBAction func handleGesture(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            
            let hands = try handPoseRequest.results?.map({ observation in
                // All figners+wrist points
                let thumbPoints = try observation.recognizedPoints(.thumb).toSortedThumbArray()
                let indexPoints = try observation.recognizedPoints(.indexFinger).toSortedIndexArray()
                let middlePoints = try observation.recognizedPoints(.middleFinger).toSortedMiddleArray()
                let ringPoints = try observation.recognizedPoints(.ringFinger).toSortedRingArray()
                let littlePoints = try observation.recognizedPoints(.littleFinger).toSortedLittleArray()
                let thumbPointsFixed = thumbPoints.map { $0.location.toUIKitCoordinates(previewLayer: cameraView.previewLayer) }
                let indexPointsFixed = indexPoints.map { $0.location.toUIKitCoordinates(previewLayer: cameraView.previewLayer) }
                let middlePointsFixed = middlePoints.map { $0.location.toUIKitCoordinates(previewLayer: cameraView.previewLayer) }
                let tringPointsFixed = ringPoints.map { $0.location.toUIKitCoordinates(previewLayer: cameraView.previewLayer) }
                let littlePointsFixed = littlePoints.map { $0.location.toUIKitCoordinates(previewLayer: cameraView.previewLayer) }
                let wristPointsFixed = try observation.recognizedPoint(.wrist).location.toUIKitCoordinates(previewLayer: cameraView.previewLayer)
                
                let hand = HandPoints(wrist: wristPointsFixed, thumb: thumbPointsFixed, index: indexPointsFixed, middle: middlePointsFixed, ring: tringPointsFixed, little: littlePointsFixed)
                return hand
            })
            if let hands = hands {
                cameraView.showPoints(hands, color: .red)
            }
        } catch {
            cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
}

// FIXME: Stupid code
// Don't punch me pls :(
extension Dictionary<VNHumanHandPoseObservation.JointName, VNRecognizedPoint> {
    func toSortedThumbArray() -> [VNRecognizedPoint] {
            var arr: [VNRecognizedPoint] = []
            arr.append(self[.thumbTip]!)
            arr.append(self[.thumbIP]!)
            arr.append(self[.thumbMP]!)
            arr.append(self[.thumbCMC]!)
            return arr.reversed()
        }
        
        func toSortedIndexArray() -> [VNRecognizedPoint] {
            var arr: [VNRecognizedPoint] = []
            arr.append(self[.indexTip]!)
            arr.append(self[.indexDIP]!)
            arr.append(self[.indexPIP]!)
            arr.append(self[.indexMCP]!)
            return arr.reversed()
        }
        
        func toSortedMiddleArray() -> [VNRecognizedPoint] {
            var arr: [VNRecognizedPoint] = []
            arr.append(self[.middleTip]!)
            arr.append(self[.middleDIP]!)
            arr.append(self[.middlePIP]!)
            arr.append(self[.middleMCP]!)
            return arr.reversed()
        }
        
        func toSortedRingArray() -> [VNRecognizedPoint] {
            var arr: [VNRecognizedPoint] = []
            arr.append(self[.ringTip]!)
            arr.append(self[.ringDIP]!)
            arr.append(self[.ringPIP]!)
            arr.append(self[.ringMCP]!)
            return arr.reversed()
        }
        
        func toSortedLittleArray() -> [VNRecognizedPoint] {
            var arr: [VNRecognizedPoint] = []
            arr.append(self[.littleTip]!)
            arr.append(self[.littleDIP]!)
            arr.append(self[.littlePIP]!)
            arr.append(self[.littleMCP]!)
            return arr.reversed()
        }
}

extension CGPoint {
    func toUIKitCoordinates(previewLayer: AVCaptureVideoPreviewLayer) -> CGPoint {
        let avFoundationCoords = CGPoint(x: x, y: 1 - y)
        return previewLayer.layerPointConverted(fromCaptureDevicePoint: avFoundationCoords)
    }
}
