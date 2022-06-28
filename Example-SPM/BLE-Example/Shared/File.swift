//
//  File.swift
//  BLE-Example
//
//  Created by Martin Kuvandzhiev on 26.06.20.
//

import Foundation

class MockDevice: Identifiable  {
    var name: String
    var id = UUID()
    
    init(name: String) {
        self.name = name
    }
}
