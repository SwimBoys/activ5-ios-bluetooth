//
//  File.swift
//  
//
//  Created by Martin Kuvandzhiev on 27.08.20.
//

import Foundation


public extension NSNotification.Name {
    static let searchCompleted = NSNotification.Name(rawValue: "Activ5Device.searchCompleted")
    static let deviceFound = NSNotification.Name(rawValue: "Activ5Device.deviceFound")
    static let deviceConnected = NSNotification.Name(rawValue: "Activ5Device.deviceConnected")
    static let deviceDisconnected = NSNotification.Name(rawValue: "Activ5Device.deviceDisconnected")
    static let deviceInitialized = NSNotification.Name(rawValue: "Activ5Device.deviceInitialized")
    static let didDetectDoubleSqeeze = NSNotification.Name(rawValue: "Activ5Device.didDetectDoubleSqeeze")
    static let didFailToConnect = NSNotification.Name(rawValue: "Activ5Device.didFailToConnect")
    static let didChangeBluetoothState = NSNotification.Name(rawValue: "Activ5Device.didChangeBluetoothState")
    static let bluetoothIsOff = NSNotification.Name(rawValue: "Activ5Device.bluetoothIsOff")
}
