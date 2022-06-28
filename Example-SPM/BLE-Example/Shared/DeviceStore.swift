//
//  DeviceStore.swift
//  BLE-Example
//
//  Created by Martin Kuvandzhiev on 26.06.20.
//

import Foundation
import Combine
import Activ5Device

extension A5Device: Identifiable {
    public var id: String {
        return self.name ?? UUID().uuidString
    }
}

class DeviceMessage:ObservableObject, Identifiable, Equatable, Hashable {
    public var id: String {
        return device.name ?? UUID().uuidString
    }
    
    var device: A5Device
    @Published var message: String = ""
    
    init(device: A5Device) {
        self.device = device
    }
    
    static func == (lhs: DeviceMessage, rhs: DeviceMessage) -> Bool {
        return lhs.device.name == rhs.device.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.device.name ?? "")
    }
}

class DeviceStore: ObservableObject, A5DeviceDelegate {
    
    @Published var devices: [DeviceMessage] = [DeviceMessage]()
    @Published var currentTitleMessage: String = ""
    init() {
        A5DeviceManager.delegate = self
    }

    func searchForDevices() {
        A5DeviceManager.scanForDevices {

        }
    }

    func searchCompleted() {
        self.currentTitleMessage = "Search completed"
    }
    

    func deviceFound(device: A5Device) {
        var setOfDevices = Set<DeviceMessage>(self.devices)
        setOfDevices.insert(DeviceMessage(device: device))
        self.devices = Array(setOfDevices)
    }

    func deviceConnected(device: A5Device) {
        let connectedDevice = self.devices.filter({$0.device.name == device.name})
        connectedDevice.forEach({$0.message = "Connected"})
    }

    func deviceDisconnected(device: A5Device) {
        let connectedDevice = self.devices.filter({$0.device.name == device.name})
        connectedDevice.forEach({$0.message = "Disconnected"})
    }

    func deviceInitialized(device: A5Device) {
        
    }

    func didReceiveIsometric(device: A5Device, value: Double) {
        let connectedDevice = self.devices.filter({$0.device.name == device.name})
        connectedDevice.forEach({$0.message = String(format: "IS%0.2f", value)})
    }
    
    func didReceiveIMUData(device: A5Device, value: IMUObject) {
        let connectedDevice = self.devices.filter({$0.device.name == device.name})
        connectedDevice.forEach({$0.message = String(format: "X%0.2f Y%0.2f Z%0.2f", value.accelerationX, value.accelerationY, value.accelerationZ)})
    }
    
    func didFailToConnect(device: A5Device, error: Error?) {
        let connectedDevice = self.devices.filter({$0.device.name == device.name})
        connectedDevice.forEach({$0.message = "Connection failed"})
    }

}


class MockDeviceStore: ObservableObject {
    @Published var devices: [MockDevice] = [MockDevice(name: "Device 1"), MockDevice(name: "Device 2")]
    var timer: Timer?
    
    func searchForDevices() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: {(timer) in
            self.devices.append(MockDevice(name: Date().description))
        })
    }
}
