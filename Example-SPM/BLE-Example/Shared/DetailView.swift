//
//  DetailView.swift
//  BLE-Example
//
//  Created by Martin Kuvandzhiev on 26.06.20.
//

import SwiftUI
import Activ5Device

struct DetailView: View {
    var device: DeviceMessage?
    
    var body: some View {
        VStack {
            List {
                if let device = device {
                    DetailCell(label: "Name", details: device.device.name ?? "")
                    DetailCell(label: "RSSI", details: String(format: "%0.2f dB", device.device.rssi))
                    DetailCell(label: "Device Version", details: device.device.deviceVersion ?? "Unknown")
                    DetailCell(label: "IMU Supported", details: device.device.imuCharacteristic != nil ? "Yes" : "No")
                    DetailCell(label: "High-res Isom Supported", details: device.device.forceCharacteristic != nil ? "Yes" : "No")
                    DetailCell(label: "Serial Number", details: device.device.serialNumber ?? "")
                    DetailCell(label: "UUID", details: device.device.uuid ?? "")
                } else {
                    DetailCell(label: "Error", details: "Device not available")
                }
            }.navigationTitle("Device Details")
        }
    }
}

struct DetailCell: View {
    var label: String
    var details: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(details).foregroundColor(Color.gray)
            
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView()
    }
}
