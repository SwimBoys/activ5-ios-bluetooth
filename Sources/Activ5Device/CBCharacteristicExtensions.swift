//
//  CBCharacteristicExtensions.swift
//  Activ5Device
//
//  Created by Martin Kuvandzhiev on 6.08.19.
//

import Foundation
import CoreBluetooth

extension CBCharacteristic {
    var characteristicType: A5Device.Characteristic {
        guard let characteristicType = A5Device.Characteristic(rawValue: self.uuid.uuidString) else {
            return .unknown
        }
        return characteristicType
    }
    
    
}
