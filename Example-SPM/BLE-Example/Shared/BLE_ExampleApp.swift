//
//  BLE_ExampleApp.swift
//  Shared
//
//  Created by Martin Kuvandzhiev on 25.06.20.
//

import SwiftUI

@main
struct BLE_ExampleApp: App {
    @StateObject var deviceStore = DeviceStore()
    var body: some Scene {
        WindowGroup {
            ContentView(store: deviceStore)
        }
    }
}

struct BLE_ExampleApp_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
