//
//  A5Device.swift
//  Activ5-Device_Example
//
//  Created by Martin Kuvandzhiev on 3.09.2018.
//  Copyright (c) 2019 ActivBody Inc. <https://activ5.com>. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum A5DeviceDataState {
    case connecting
    case connected
    case isometric
    case stop
    case disconnected
}

public enum A5Error: Error {
    case imuUnsupported
    case batteryLevelNotReadable
}

public class A5Device {
    public var device: CBPeripheral
    public var name: String?
    public var serialNumber: String?
    public var writeCharacteristic: CBCharacteristic?
    public var readCharacteristic: CBCharacteristic?
    //API spec v2
    public var usesNewProtocol: Bool = false
    public var forceCharacteristic: CBCharacteristic?
    public var imuCharacteristic: CBCharacteristic?
    public var timestampCharacteristic: CBCharacteristic?
    public var sampleRateCharacteristic: CBCharacteristic?
    public var batteryLevelCharacteristic: CBCharacteristic?
    public var serialNumberCharacteristic: CBCharacteristic?
    public var uuid1Characteristic: CBCharacteristic?
    public var uuid2Characteristic: CBCharacteristic?
    
    public var communicationInitialized: Bool = false
    public var rssi: Double = 0
    public var deviceDataState: A5DeviceDataState = .disconnected
    public var deviceVersion: String?
    public var uuid1: String?
    public var uuid2: String?
    public var uuid: String? {
        guard let uuid1 = self.uuid1, let uuid2 = self.uuid2 else {
            return nil
        }
        return uuid1 + uuid2
    }
    
    public var evergreenMode: Bool = false {
        didSet {
            setEvergreen(evergreenMode)
        }
    }
    
    public var connected: Bool {
        switch self.deviceDataState {
        case .disconnected, .connecting:
            return false
        default:
            return true
        }
    }
    
    var forgetAfterDisconnected: Bool = false
    private var evergreenTimer: Timer?
    public var shouldReconnect = true
    
    public init(device: CBPeripheral, name: String? = nil, writeCharacteristic: CBCharacteristic? = nil, readCharacteristic: CBCharacteristic? = nil) {
        self.device = device
        self.name = name
        self.writeCharacteristic = writeCharacteristic
        self.readCharacteristic = readCharacteristic
    }
}

extension A5Device {
    enum Characteristic: String {
        case read = "5A01"
        case write = "5A02"
        case force = "F0FE"
        case timestamp = "F0F3"
        case imu = "F0F5"
        case uuid1 = "F0F7"
        case uuid2 = "F0F8"
        case sn1 = "SN1"
        case sn2 = "SN2"
        case sampleRate = "F0FA"
        case battery = "2A19"
        case serialNumber = "2A25"
        case unknown = "FFFF"
    }
}

extension A5Device: Equatable {
    public static func == (lhs: A5Device, rhs: A5Device) -> Bool {
        return lhs.name == rhs.name
    }
}

extension A5Device: Hashable {
    public var hashValue: Int {
            return self.name?.hashValue ?? 0
    }
}

//Bluetooth functionality
public enum A5Command:String {
    case doHandshake = "TVGTIME"
    case startIsometric = "ISOM!"
    case tare = "TARE!"
    case stop = "STOP!"
    case sn1 = "SN1!"
    case sn2 = "SN2!"
    case uuid1 = "ID1!"
    case uuid2 = "ID2!"
    case battery = "2A19"
    case serialNumber = "2A25"
}

public extension A5Device {
    func sendCommand(_ command: A5Command) {
        self.sendMessage(message: command.rawValue)
        switch command {
        case .stop:
            self.deviceDataState = .stop
        case .doHandshake:
            if self.uuid1Characteristic == nil, self.uuid2Characteristic == nil {
                self.sendCommand(.uuid1)
                self.sendCommand(.uuid2)
            }
            if self.serialNumberCharacteristic == nil {
                self.sendCommand(.sn1)
                self.sendCommand(.sn2)
            }
        default:
            break
        }
    }

    private func sendMessage(message: String) {
        A5DeviceManager.send(message: message, to: self)
    }
    
    func startIsometric() {
        if let forceCharacteristic = self.forceCharacteristic {
            self.device.setNotifyValue(true, for: forceCharacteristic)
        } else {
            self.sendCommand(.startIsometric)
        }
    }
    
    
    func getBatteryLevel() throws -> Int {
        guard let batteryLevelCharacteristic = batteryLevelCharacteristic else {
            throw A5Error.batteryLevelNotReadable
        }
        let battery = MessageParser.parseMessage(characteristic: batteryLevelCharacteristic)
        guard let batteryPercentage: UInt64 = battery.value as? UInt64 else {
            self.device.readValue(for: batteryLevelCharacteristic)
            throw A5Error.batteryLevelNotReadable
        }
        return Int(batteryPercentage)
    }
    
    @discardableResult
    func getSerialNumber() -> String? {
        guard let serialNumberCharacteristic = serialNumberCharacteristic else {
            return ""
        }
        let serialNumber = MessageParser.parseMessage(characteristic: serialNumberCharacteristic)
        if serialNumber.type == .serialNumber {
            self.serialNumber = serialNumber.value as? String
            return self.serialNumber
        }
        return nil
    }
    
    func stop() {
        if let forceCharacteristic = self.forceCharacteristic {
            self.device.setNotifyValue(false, for: forceCharacteristic)
        } else {
            self.sendCommand(.stop)
        }
    }
    
    func setSampleRate(sampleRate: Int) {
        let sampleRate = Int16(sampleRate)
        let data: Data = withUnsafeBytes(of: sampleRate, { Data($0)} )
        guard let sampleRateCharacteristic = self.sampleRateCharacteristic else {
            return
        }
        
        self.device.writeValue(data, for: sampleRateCharacteristic, type: .withResponse)
    }
    
    func startIMU() throws {
        guard let imuCharacteristic = self.imuCharacteristic else {
            throw A5Error.imuUnsupported
        }
        self.device.setNotifyValue(true, for: imuCharacteristic)
    }
    
    func stopIMU() throws {
        guard let imuCharacteristic = self.imuCharacteristic else {
            throw A5Error.imuUnsupported
        }
        self.device.setNotifyValue(false, for: imuCharacteristic)
    }

    func disconnect() {
        self.shouldReconnect = false
        A5DeviceManager.disconnect(device: self.device)
        self.deviceDataState = .disconnected
    }
}

public extension A5Device {
    func setEvergreen(_ enabled: Bool) {
        switch enabled {
        case true:
            evergreenTimer?.invalidate()
            evergreenTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { (timer) in
                switch self.deviceDataState {
                case .stop, .connected:
                    self.sendCommand(.stop)
                default:
                    break
                }
            })
            evergreenTimer?.tolerance = 100
        case false:
            evergreenTimer?.invalidate()
            evergreenTimer = nil
        }
    }
}
