//
//  ContentView.swift
//  Shared
//
//  Created by Martin Kuvandzhiev on 25.06.20.
//

import SwiftUI
import Activ5Device

struct ContentView: View {
    @ObservedObject var store: DeviceStore
    @State var isPresented = false
    @State var selectedItem: DeviceMessage?
    @State var isShowingDetailController = false
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(
                    destination: DetailView(device: selectedItem),
                    isActive: $isShowingDetailController) {
                    EmptyView()
                }
                Text(store.currentTitleMessage)
                List {
                    Section(header: Text("Available devices")) {
                        ForEach(store.devices) { device in
                            VStack {
                                Button(action: {
                                    self.selectedItem = device
                                    self.isPresented = true
                                    #if os(macOS)
                                    self.isShowingDetailController = true
                                    #endif
                                }, label: {
                                    DeviceTableViewCell(device: device)
                                })
                            }
                        }
                    }
                }
            }
            .navigationTitle("BLE Tester App")
            .navigationBarItems(trailing: Button("Scan", action: scan))
            .onAppear {
                store.searchForDevices()
            }
        }
        .actionSheet(isPresented: $isPresented) {
            #if os(iOS)
            return ActionSheet(title: Text("Actions"), message: nil, buttons: actionButtons)
            #endif
        }
        
    }
    
    var actionButtons: [Alert.Button] {
        guard let selectedItem = self.selectedItem else {
            return [Alert.Button]()
        }
        
        if selectedItem.device.connected {
            return [
                Alert.Button.default(Text("Disconnect"), action: {
                    selectedItem.device.disconnect()
                }),
                Alert.Button.default(Text("Open Details"), action: {
                    isShowingDetailController = true
                }),
                Alert.Button.default(Text("Start Isometric"), action: {
                    selectedItem.device.startIsometric()
                }),
                Alert.Button.default(Text("Stop Isometric"), action: {
                    selectedItem.device.stop()
                }),
                Alert.Button.default(Text("Start IMU"), action: {
                    try? selectedItem.device.startIMU()
                    
                }),
                Alert.Button.default(Text("Stop IMU"), action: {
                    try? selectedItem.device.stopIMU()
                }),
                Alert.Button.default(Text("20ms Sample Period"), action: {
                    selectedItem.device.setSampleRate(sampleRate: 25)
                }),
                Alert.Button.default(Text("100ms Sample Period"), action: {
                    selectedItem.device.setSampleRate(sampleRate: 100)
                }),
                Alert.Button.cancel()
            ]
        }
        
        return
            [
                Alert.Button.default(Text("Connect"), action: {
                    A5DeviceManager.connect(device: selectedItem.device.device)
                }),
                Alert.Button.cancel()
            ]
    }
    
    func scan() {
        store.searchForDevices()
    }
}

struct DeviceTableViewCell: View {
    @ObservedObject var device: DeviceMessage
    var body: some View {
        HStack {
            Text(device.device.name ?? "").padding()
            Spacer()
            Text(device.message)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: DeviceStore())
            
    }
}
