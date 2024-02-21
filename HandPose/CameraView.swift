//
//  CameraView.swift
//  HandPose
//
//  Created by Viktor Varenik on 21.02.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import UIKit
import AVFoundation

class CameraView: UIView {
    private var overlayLayer = CAShapeLayer()
    private var pointsPath = UIBezierPath()

    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer == previewLayer {
            overlayLayer.frame = layer.bounds
        }
    }

    private func setupOverlay() {
        previewLayer.addSublayer(overlayLayer)
    }
    
    private var previousHand: HandPoints?
    
    func showPoints(_ hands: [HandPoints], color: UIColor) {
        pointsPath.removeAllPoints()
        
        for hand in hands {
            // Wrist
            pointsPath.move(to: hand.wrist)
            pointsPath.addArc(withCenter: hand.wrist, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            
            // Thumb
            pointsPath.move(to: hand.wrist)
            hand.thumb.forEach { p in
                pointsPath.addLine(to: p)
                pointsPath.addArc(withCenter: p, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                pointsPath.move(to: p)
            }
            
            // Index
            pointsPath.move(to: hand.wrist)
            hand.index.forEach { p in
                pointsPath.addLine(to: p)
                pointsPath.addArc(withCenter: p, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                pointsPath.move(to: p)
            }
            
            // Middle
            pointsPath.move(to: hand.wrist)
            hand.middle.forEach { p in
                pointsPath.addLine(to: p)
                pointsPath.addArc(withCenter: p, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                pointsPath.move(to: p)
            }
            
            // Ring
            pointsPath.move(to: hand.wrist)
            hand.ring.forEach { p in
                pointsPath.addLine(to: p)
                pointsPath.addArc(withCenter: p, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                pointsPath.move(to: p)
            }
            
            // Little
            pointsPath.move(to: hand.wrist)
            hand.little.forEach { p in
                pointsPath.addLine(to: p)
                pointsPath.addArc(withCenter: p, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                pointsPath.move(to: p)
            }
        }
        overlayLayer.strokeColor = color.cgColor
        overlayLayer.fillColor = UIColor.blue.cgColor
        overlayLayer.lineWidth = 8
        overlayLayer.lineJoin = .round
        overlayLayer.backgroundColor = .init(gray: 0, alpha: 1)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayLayer.path = pointsPath.cgPath
        CATransaction.commit()
    }
}
