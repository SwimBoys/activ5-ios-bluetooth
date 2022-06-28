//
//  A5DeviceManager.swift
//  Activ5-Device_Example
//
//  Created by Martin Kuvandzhiev on 27.08.2018.
//  Copyright (c) 2019 ActivBody Inc. <https://activ5.com>. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct A5DeviceManagerOptions {
    public var services: [CBUUID] = [CBUUID(string: "0x5000")]
    public var autoHandshake: Bool = true
    public var searchTimeout = 30.0
    public var reconnectionStrategy: A5ReconnectStrategy = .automatically
    public var squeezeThreshold: SqueezeThreshold = .base {
        didSet {
            DoubleSqeezeHelper.squeezeThreshold = squeezeThreshold
        }
    }
}

public enum A5DeviceManagerConnectionState {
    case disconnected
    case searching
    case connected
}

public enum A5ReconnectStrategy {
    case manually
    case automatically
}

public enum A5SqueezeState {
    case squeezed
    case depressed
}

public protocol A5DeviceDelegate: class {
    func searchCompleted()
    func deviceFound(device: A5Device)
    func deviceConnected(device: A5Device)
    func deviceDisconnected(device: A5Device)
    func deviceInitialized(device: A5Device)
    func didReceiveMessage(device: A5Device, message: String, type: MessageType)
    func didReceiveIsometric(device: A5Device, value: Double)
    func didReceiveIMUData(device: A5Device, value: IMUObject)
    func squeezeStateChanged(state: A5SqueezeState, device: A5Device)
    func didDetectDoubleSqeeze(device: A5Device)
    func didFailToConnect(device: A5Device, error: Error?)
    func didChangeBluetoothState(_ state: CBManagerState)
    func bluetoothIsSwitchedOff()
    func didReceiveSerialNumber(device: A5Device, value: String)
    func didReceiveBattery(device: A5Device,value: UInt64)
}

public extension A5DeviceDelegate {
    func didFailToConnect(device: CBPeripheral, error: Error?) {}
    func didReceiveMessage(device: A5Device, message: String, type: MessageType) {}
    func didReceiveIsometric(device:A5Device, value: Int) {}
    func didReceiveIMUData(device: A5Device, value: IMUObject) {}
    func didChangeBluetoothState(_ state: CBManagerState) {}
    func squeezeStateChanged(state: A5SqueezeState, device: A5Device) {}
    func didDetectDoubleSqeeze(device: A5Device) {}
    func bluetoothIsSwitchedOff() {}
    func didReceiveSerialNumber(device: A5Device, value: String){}
    func didReceiveBattery(device: A5Device,value: UInt64){}
}

public class A5DeviceManager: NSObject {
//MARK: - Public vars
    public static let instance = { return A5DeviceManager() }()
    public static weak var delegate: A5DeviceDelegate? {
        didSet {
            print(self.delegate)
        }
    }
    
    public static let cbManager = { return CBCentralManager(delegate: A5DeviceManager.instance, queue: bluetoothQueue)}()

    public static var devices = [String: A5Device]()
    public static var connectedDevices: [String: A5Device] {
        self.devices.filter({$0.value.connected == true})
    }
    public static var squeezeState: A5SqueezeState = .depressed
    
    public static var options = A5DeviceManagerOptions()
//MARK: - Private vars
    private static var searchTimer: Timer?
    private static let bluetoothQueue = DispatchQueue(label: "A5-Dispatch-Queue")
    
    public static var connectionState: A5DeviceManagerConnectionState {
        if cbManager.isScanning == true {
            return .searching
        }
        
        if connectedDevices.isEmpty == true {
            return .disconnected
        }
        
        return .connected
    }
    
    public static var isScanning: Bool {
        return (A5DeviceManager.connectionState == .searching) ? true : false
    }

    public static var isBluetoothOn: Bool {
        return (A5DeviceManager.cbManager.state == .poweredOn) ? true : false

    }
    
    
//MARK: - Functions
    public class func initializeDeviceManager(){
        _ = cbManager // initializing the CBManager
    }
    
    public class func disconnectAllDevices() {
        for device in A5DeviceManager.connectedDevices {
            device.value.forgetAfterDisconnected = true
            disconnect(device: device.value.device)
        }
    }

    public class func scanForDevices(searchCompleted: @escaping () -> Void) {
        //clean current list
        switch cbManager.state {
        case .poweredOn:
            break
        default:
            delegate?.bluetoothIsSwitchedOff()
            return
        }

        self.cbManager.scanForPeripherals(withServices: options.services)
        self.searchTimer = Timer.scheduledTimer(withTimeInterval: self.options.searchTimeout, repeats: false, block: { (_) in
            cbManager.stopScan()
            NotificationCenter.default.post(name: .searchCompleted, object: self)
            self.delegate?.searchCompleted()
            searchCompleted()
        })
    }

    public class func stopScanningForDevices() {
        self.searchTimer?.invalidate()
        self.searchTimer = nil
        cbManager.stopScan()
    }
    
    public class func connect(device: CBPeripheral) {
        self.cbManager.connect(device, options: nil)
        if let a5Device = A5DeviceManager.device(for: device) {
            a5Device.value.deviceDataState = .connecting
        }
    }
    
    class func disconnect(device: CBPeripheral) {
        self.cbManager.cancelPeripheralConnection(device)
    }

    class func send(message: String, to device: A5Device) {
        let message = "A"+message+"\u{13}"
        let data = message.data(using: String.Encoding.utf8)!
        guard let writeChar = device.writeCharacteristic else {
            return
        }

        device.device.writeValue(data, for: writeChar, type: CBCharacteristicWriteType.withResponse)
    }

    public class func device(for peripheral: CBPeripheral) -> (key: String, value:A5Device)? {
        var allDevices = A5DeviceManager.devices
        for item in connectedDevices {
            allDevices[item.key] = item.value
        }

        guard let device = allDevices.filter({ (deviceToCheck) -> Bool in
            return deviceToCheck.value.device == peripheral
        }).first else {
            return nil
        }
        return (device.key, device.value)
    }
}

//MARK:- CBCentralManager Implementation
extension A5DeviceManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        A5DeviceManager.delegate?.didChangeBluetoothState(central.state)
        NotificationCenter.default.post(name: .didChangeBluetoothState, object: self, userInfo: ["state":central.state])
        switch central.state {
        case .poweredOn :
            print("Ready for device connect")
        case .poweredOff:
            A5DeviceManager.connectedDevices.forEach { device in
                A5DeviceManager.devices.removeValue(forKey: device.value.name!)
                DispatchQueue.main.async {
                    A5DeviceManager.delegate?.deviceDisconnected(device: device.value)
                }
            }
        default:
            break
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String else {
            return
        }

        var device: A5Device
        
        if A5DeviceManager.connectedDevices.keys.contains(deviceName) == false {
            let newDevice = A5Device(device: peripheral, name: deviceName, writeCharacteristic: nil, readCharacteristic: nil)
            newDevice.rssi = RSSI.doubleValue
            device = newDevice
            
            if let oldDeviceInstance = A5DeviceManager.devices[deviceName],
                oldDeviceInstance.shouldReconnect,
                A5DeviceManager.options.reconnectionStrategy == .automatically {
                
                A5DeviceManager.connect(device: newDevice.device)
            }
            
            A5DeviceManager.devices[deviceName] = device
        } else {
            A5DeviceManager.devices[deviceName]?.rssi = RSSI.doubleValue
            device = A5DeviceManager.devices[deviceName]!
        }
        DispatchQueue.main.async {
            A5DeviceManager.delegate?.deviceFound(device: device)
            NotificationCenter.default.post(name: .deviceFound, object: self, userInfo: ["device":device])
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let device = A5DeviceManager.device(for: peripheral) {
            device.value.device.delegate = self
            device.value.deviceDataState = .connected
            device.value.device.discoverServices(nil)
            DispatchQueue.main.async {
                A5DeviceManager.delegate?.deviceConnected(device: device.value)
                NotificationCenter.default.post(name: .deviceConnected, object: self, userInfo: ["device":device.value])
            }
            return
        }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard let device = A5DeviceManager.device(for: peripheral)?.value else {
            return
        }
        DispatchQueue.main.async {
            A5DeviceManager.delegate?.didFailToConnect(device: device, error: error)
            NotificationCenter.default.post(name: .didFailToConnect, object: self, userInfo: ["device":device, "error": error])
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let device = A5DeviceManager.device(for: peripheral)?.value else {
            return
        }
        
        device.deviceDataState = .disconnected
        device.communicationInitialized = false
        device.rssi = 0
        
        if device.forgetAfterDisconnected || (device.shouldReconnect == false && A5DeviceManager.options.reconnectionStrategy == .manually) {
            A5DeviceManager.devices.removeValue(forKey: device.name ?? "")
        } else {
            A5DeviceManager.devices.removeValue(forKey: device.name ?? "")
            A5DeviceManager.scanForDevices {
                    
            }
        }
        DispatchQueue.main.async {
            A5DeviceManager.delegate?.deviceDisconnected(device: device)
            NotificationCenter.default.post(name: .deviceDisconnected, object: self, userInfo: ["device": device])
        }
    }
}

//MARK: - CBPeripheral Implementation
extension A5DeviceManager: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        
        guard let device = A5DeviceManager.device(for: peripheral)?.value else {
            return
        }
        
        device.usesNewProtocol = services
            .filter({$0.uuid.uuidString == "F0F0"})
            .count > 0
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        guard let device = A5DeviceManager.device(for: peripheral) else {
            return
        }

        for characrteristic in characteristics {
            switch characrteristic.characteristicType {
            case .read:
                device.value.readCharacteristic = characrteristic
                peripheral.setNotifyValue(true, for: characrteristic)
            case .write:
                device.value.writeCharacteristic = characrteristic
            case .force:
                device.value.forceCharacteristic = characrteristic
            case .timestamp:
                device.value.timestampCharacteristic = characrteristic
            case .imu:
                device.value.imuCharacteristic = characrteristic
            case .sampleRate:
                device.value.sampleRateCharacteristic = characrteristic
            case .battery:
                device.value.batteryLevelCharacteristic = characrteristic
            case .serialNumber:
                device.value.serialNumberCharacteristic = characrteristic
                device.value.device.readValue(for: characrteristic)
            case .uuid1:
                device.value.uuid1Characteristic = characrteristic
                device.value.device.readValue(for: characrteristic)
            case .uuid2:
                device.value.uuid2Characteristic = characrteristic
                device.value.device.readValue(for: characrteristic)
                
            default:
                break
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let device = A5DeviceManager.device(for: peripheral)?.value else {
            return
        }
        
        let parsedData = MessageParser.parseMessage(characteristic: characteristic)
        let messageType: MessageType = parsedData.type
        var message: String = ""
        var batteryMessage: UInt64 = 0
        var imuData = IMUObject(accelerationX: 0, accelerationY: 0, accelerationZ: 0, gyroX: 0, gyroY: 0, gyroZ: 0, timestamp: 0)
        
        if device.communicationInitialized == false && ((device.serialNumber != nil && device.uuid != nil) || device.usesNewProtocol == false) {
            device.communicationInitialized = true
            DispatchQueue.main.async {
                A5DeviceManager.delegate?.deviceInitialized(device: device)
                NotificationCenter.default.post(name: .deviceInitialized, object: self, userInfo: ["device": device])
            }
        }
        
        switch messageType {
        case .initialMessage:
            device.deviceDataState = .connected
            device.deviceVersion = (parsedData.value as? String) ?? ""
            if A5DeviceManager.options.autoHandshake == true {
                device.sendCommand(.doHandshake)
                device.deviceDataState = .stop
            }
        case .isometric:
            device.deviceDataState = .isometric
            message = (parsedData.value as? String) ?? ""
        case .imu:
            if let value = parsedData.value as? IMUObject {
                imuData = value
            }
        case .sn1:
            message = (parsedData.value as? String) ?? ""
        case .sn2:
            message = (parsedData.value as? String) ?? ""
        case .uuid1:
            message = (parsedData.value as? String) ?? ""
            device.uuid1 = message
        case .uuid2:
            message = (parsedData.value as? String) ?? ""
            device.uuid2 = message.replacingOccurrences(of: "\0", with: "")
        case .serialNumber:
            message = (parsedData.value as? String) ?? ""
            device.serialNumber = message
        case .battery:
            batteryMessage = (parsedData.value as? UInt64) ?? UInt64.zero
        default:
            device.deviceDataState = .stop
        }
        
        
        DispatchQueue.main.async {
            A5DeviceManager.delegate?.didReceiveMessage(device: device, message: message, type: messageType)
            if messageType == .isometric, let value = Double(message) {
                A5DeviceManager.delegate?.didReceiveIsometric(device: device, value: value)
                DoubleSqeezeHelper.evaluateDoublePress(force: value, onPressed: {
                    if A5DeviceManager.squeezeState != .squeezed {
                        A5DeviceManager.delegate?.squeezeStateChanged(state: .squeezed, device: device)
                        A5DeviceManager.squeezeState = .squeezed
                    }
                }, onDepressed: {
                    if A5DeviceManager.squeezeState != .depressed {
                        A5DeviceManager.delegate?.squeezeStateChanged(state: .depressed, device: device)
                        A5DeviceManager.squeezeState = .depressed
                    }
                }) {
                    A5DeviceManager.delegate?.didDetectDoubleSqeeze(device: device)
                    NotificationCenter.default.post(name: .didDetectDoubleSqeeze, object: self, userInfo: ["device": device])
                }
            }
            if messageType == .imu {
                A5DeviceManager.delegate?.didReceiveIMUData(device: device, value: imuData)
            }
            if messageType == .sn1 {
                A5DeviceManager.delegate?.didReceiveSerialNumber(device: device, value: message)
            } else if messageType == .sn2 {
                A5DeviceManager.delegate?.didReceiveSerialNumber(device: device, value: message)
            }
            
            if messageType == .serialNumber {
                A5DeviceManager.delegate?.didReceiveSerialNumber(device: device, value: message)
            }
            
            if messageType == .battery {
                A5DeviceManager.delegate?.didReceiveBattery(device: device, value: batteryMessage)
            }
        }
    }
    
    
}
