//
//  MessageParser.swift
//  Activ5Device
//
//  Created by Martin Kuvandzhiev on 6.08.19.
//

import Foundation
import CoreBluetooth

public enum MessageType: String {
    case initialMessage = "TC5k"
    case isometric = "IS"
    case timestamp = "TS"
    case imu = "IM"
    case sn1 = "SN1"
    case sn2 = "SN2"
    case uuid1 = "i"
    case uuid2 = "I"
    case battery = "battery"
    case serialNumber = "serialNumber"
    case unknown = "unknown"
    
    
    public init(from message: String) {
        if message.starts(with: MessageType.initialMessage.rawValue) {
            self = .initialMessage
        } else if message.starts(with: MessageType.isometric.rawValue) {
            self = .isometric
        } else {
            var messageWithoutFirstCharacter = message
            messageWithoutFirstCharacter.removeFirst()
            if messageWithoutFirstCharacter.starts(with: MessageType.uuid1.rawValue) {
                self = .uuid1
            } else if messageWithoutFirstCharacter.starts(with: MessageType.uuid2.rawValue) {
                self = .uuid2
            } else if messageWithoutFirstCharacter.starts(with: MessageType.sn1.rawValue) {
                self = .sn1
            } else if messageWithoutFirstCharacter.starts(with: MessageType.sn2.rawValue) {
                self = .sn2
            } else {
                self = .unknown
            }
        }
    }
}

public class MessageParser {
    public class func parseMessage(characteristic: CBCharacteristic)->(type: MessageType, value: Any?) {
        guard let value = characteristic.value else {
            return (.unknown, nil)
        }
        
        switch characteristic.characteristicType {
        case .read:
            let messageString = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            return parseLegacyMessage(messageString)
        case .force:
            let forceData = parseValue(data: value)
            let forceInNewtons = Double(forceData).toNewtons
            let forceString = String(forceInNewtons)
            return (.isometric, forceString)
        case .imu:
            let imuData = parseIMUValue(data: value)
            return (.imu, imuData)
        case .sn1:
            let sn1Message = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            return (.sn1, sn1Message)
        case .sn2:
            let sn2Message = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            return (.sn2, sn2Message)
        case .battery:
            let batteryPercetage = UInt64(characteristic.value!.hexEncodedString(),radix: 16)
            return (.battery, batteryPercetage)
        case .serialNumber:
            let serialNumber = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            return (.serialNumber, serialNumber)
        case .uuid1:
            let uuid1 = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            return (.uuid1, uuid1)
        case .uuid2:
            let uuid2 = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            return (.uuid2, uuid2)
            
        case .unknown:
            let message = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            return (.unknown, message)
        default:
            return (.unknown, nil)
        }
    }
    
    public class func parseLegacyMessage(_ message: String?) -> (type: MessageType, value: Any?) {
        guard var message = message else {
            return (.unknown, nil)
        }
        
        message = message.replacingOccurrences(of: "\u{12}", with: "").replacingOccurrences(of: "\u{13}", with: "")
        
        let messageParts = message.components(separatedBy: ";")
        let messageType = MessageType(from: messageParts[0])
        switch messageType {
        case .initialMessage:
            let deviceVersion = messageParts[1]
            return (messageType, deviceVersion)
        case .isometric:
            let isomMessage = messageParts[0].replacingOccurrences(of: "IS", with: "")
            let indexOfSlash = isomMessage.firstIndex(of: "/")!
            let isomValue = String(isomMessage.prefix(upTo: indexOfSlash))
            let newtowns = Double(isomValue)?.toNewtonsLegacy ?? 0
            let valueString = String(newtowns)
            
            return (messageType, valueString)
        case .sn1:
            var sn1 = messageParts[0]
            sn1.removeFirst(4)
            return (messageType, sn1)
        case .sn2:
            var sn2 = messageParts[0]
            sn2.removeFirst(4)
            return (messageType, sn2)
        case .uuid1:
            var uuid1 = messageParts[0]
            uuid1.removeFirst(2)
            return (messageType, uuid1)
        case .uuid2:
            var uuid2 = messageParts[0]
            uuid2.removeFirst(2)
            return (messageType, uuid2)
        case .unknown:
            return (.unknown, nil)
        default:
            return (.unknown, nil)
        }
    }
    
    public class func parseValue(data: Data) -> Int {
        let value = data.withUnsafeBytes { $0.load(as: Int16.self) }
        return Int(value)
    }
    
    public class func parseIMUValue(data: Data) -> IMUObject {
        let accelerationX = parseValue(data: data.subdata(in: Range(uncheckedBounds: (lower: 0, upper: 2))))
        let accelerationY = parseValue(data:data.subdata(in: Range(uncheckedBounds: (lower: 2, upper: 4))))
        let accelerationZ = parseValue(data:data.subdata(in: Range(uncheckedBounds: (lower: 4, upper: 6))))
        let gyroX = parseValue(data:data.subdata(in: Range(uncheckedBounds: (lower: 6, upper: 8))))
        let gyroY = parseValue(data:data.subdata(in: Range(uncheckedBounds: (lower: 8, upper: 10))))
        let gyroZ = parseValue(data:data.subdata(in: Range(uncheckedBounds: (lower: 10, upper: 12))))
        let timestampData = data.subdata(in: Range(uncheckedBounds: (lower: 12, upper: 16))).withUnsafeBytes { $0.load(as: Int32.self) }
        let timestamp = Int(timestampData)
        
        
        return IMUObject(accelerationX: accelerationX.toGForce,
                         accelerationY: accelerationY.toGForce,
                         accelerationZ: accelerationZ.toGForce,
                         gyroX: gyroX.toRadPerSec,
                         gyroY: gyroY.toRadPerSec,
                         gyroZ: gyroZ.toRadPerSec,
                         timestamp: timestamp.toSec)
    }
}

public extension Int {
    var toGForce: Double {
        // According to Accelerometer spec 1G = 0x0FFF value
        return Double(self)/Double(0x0FFF)
    }
    
    var toRadPerSec: Double {
        // According to Gyro spec 250 dps == 0x0FFF
        
        return Double(self) * (250.0 / Double(0x0FFF)) * .pi/180.0
    }
    
    var toSec: Double {
        // Timestamp resolution is 30.5us - rollover should be ~36 hours
        return Double(self) * 30.5 / 1000000.0 / 2.0
    }
}

public extension IMUObject {
    var scaledValue: IMUObject {
        var imuObject = self
        let rotationScalingMultiplier = 1.15 // introduced in https://github.com/ActivBody/ac-imu-app/commit/e3281a53efdd38b49e791f86b4f32cea016022e4
        
        imuObject.gyroX *= rotationScalingMultiplier
        imuObject.gyroY *= rotationScalingMultiplier
        imuObject.gyroZ *= rotationScalingMultiplier
        
        return imuObject
    }
}

public extension Double {
    var fromGForce: Int {
        // According to Accelerometer spec 1G = 0x0FFF value
        return Int(self * Double(0x0FFF))
    }
    
    var fromRadPerSec: Int {
        // According to Gyro spec 250 dps == 0x0FFF
        return Int(self / ((250.0 / Double(0x0FFF))*(.pi/180.0)))
    }
    
    var fromSec: Int {
        // Timestamp resolution is 30.5us - rollover should be ~36 hours
        return Int(self / 30.5 * 1000000.0 * 2.0)
    }
    
    var toLBF: Float {
        return Float(self) * 0.0610498269896194
    }
    
    var toLBFLegacy: Float {
        return Float(self) * 0.24419930795
    }

    var toNewtons: Double {
        return Double(self * 0.27156315909)
    }
    
    var toNewtonsLegacy: Double {
        return Double(self * 1.08625263633)
    }
}

extension Data {
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }

    public func hexEncodedString() -> String {
        return String(self.reduce(into: "".unicodeScalars, { (result, value) in
            result.append(Data.hexAlphabet[Int(value/16)])
            result.append(Data.hexAlphabet[Int(value%16)])
        }))
    }
}
