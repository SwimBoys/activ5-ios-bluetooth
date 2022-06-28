//
//  A5DeviceManagerTests.swift
//  Activ5-Device_Tests
//
//  Created by Martin Kuvandzhiev on 7.08.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import Activ5Device
@testable import Pods_Activ5_Device_Example

class A5DeviceManagerTests: XCTestCase {

    override func setUp() {

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitializeDeviceManager() {
        A5DeviceManager.initialize()
    }

    func testScanForDevices() {
        A5DeviceManager.scanForDevices(searchCompleted: {})
    }

    func testStopScanning() {
        A5DeviceManager.stopScanningForDevices()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
