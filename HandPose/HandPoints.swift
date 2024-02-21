//
//  HandPoints.swift
//  HandPose
//
//  Created by Viktor Varenik on 21.02.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation

struct HandPoints {
    let wrist: CGPoint
    let thumb: [CGPoint]
    let index: [CGPoint]
    let middle: [CGPoint]
    let ring: [CGPoint]
    let little: [CGPoint]
}
