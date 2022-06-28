//
//  IMUObject.swift
//  Activ5Device
//
//  Created by Martin Kuvandzhiev on 7.08.19.
//

import Foundation

public struct IMUObject {
    public var accelerationX: Double
    public var accelerationY: Double
    public var accelerationZ: Double
    public var gyroX: Double
    public var gyroY: Double
    public var gyroZ: Double
    public var timestamp: Double
    
    public init(accelerationX: Double, accelerationY: Double, accelerationZ: Double,
          gyroX: Double, gyroY: Double, gyroZ: Double, timestamp: Double) {
        self.accelerationX = accelerationX
        self.accelerationY = accelerationY
        self.accelerationZ = accelerationZ
        self.gyroX = gyroX
        self.gyroY = gyroY
        self.gyroZ = gyroZ
        self.timestamp = timestamp
    }
}
