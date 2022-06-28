import XCTest
import CoreBluetooth

@testable import Activ5Device
@testable import Pods_Activ5_Device_Example

class MessageParserTests: XCTestCase {

    //Test read by characteristic
    func testReadInitialMessageByCharacteristic() {
        let mutableCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "5A01"),
                                                            properties: [CBCharacteristicProperties.read],
                                                            value: Data(base64Encoded: "ElRDNWs7MS4wMDswNDtCQVRPSxM="),
                                                            permissions: CBAttributePermissions.readable)
        let parsedData = MessageParser.parseMessage(characteristic: mutableCharacteristic)
        XCTAssert(parsedData.type == .initialMessage)
        XCTAssert(parsedData.value is String)
    }

    func testReadLegacyIsomDataByCharacteristic() {
        let mutableCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "5A01"),
                                                            properties: [CBCharacteristicProperties.read],
                                                            value: Data(base64Encoded: "EklTOS9JUxMwMTswNDtCQVRPSxM="),
                                                            permissions: CBAttributePermissions.readable)
        let parsedData = MessageParser.parseMessage(characteristic: mutableCharacteristic)
        XCTAssert(parsedData.type == .isometric)
        XCTAssert(parsedData.value is String)
    }

    func testReadIsomDataByCharacteristic() {
        let mutableCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "F0FE"),
                                                            properties: [CBCharacteristicProperties.read],
                                                            value: Data(base64Encoded: "AP8="),
                                                            permissions: CBAttributePermissions.readable)
        let parsedData = MessageParser.parseMessage(characteristic: mutableCharacteristic)
        XCTAssert(parsedData.type == .isometric)
        XCTAssert(parsedData.value is String)
    }

    func testReadIMUDataByCharacteristic() {
        let mutableCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "F0F5"),
                                                            properties: [CBCharacteristicProperties.read],
                                                            value: Data(base64Encoded: "PgDy/qsQ9v/e/+z/4ioWAA=="),
                                                            permissions: CBAttributePermissions.readable)
        let parsedData = MessageParser.parseMessage(characteristic: mutableCharacteristic)
        XCTAssert(parsedData.type == .imu)
        XCTAssert(parsedData.value is IMUObject)
    }

    func testReadCharacteristicWithoutValue() {
        let mutableCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "F0F5"),
                                                            properties: [CBCharacteristicProperties.read],
                                                            value: nil,
                                                            permissions: CBAttributePermissions.readable)
        let parsedData = MessageParser.parseMessage(characteristic: mutableCharacteristic)
        XCTAssert(parsedData.type == .unknown)
        XCTAssertNil(parsedData.value)
    }

    func testReadInvalidCharacteristic() {
        let mutableCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "1234"), // unknown uuid
                                                            properties: [CBCharacteristicProperties.read],
                                                            value: Data(base64Encoded: "AP8="),
                                                            permissions: CBAttributePermissions.readable)
        let parsedData = MessageParser.parseMessage(characteristic: mutableCharacteristic)
        XCTAssert(parsedData.type == .unknown)
        XCTAssertNil(parsedData.value)
    }

    //Test parsing functions
    func testInitialMessageConversion() {
        let message = Data(base64Encoded: "ElRDNWs7MS4wMDswNDtCQVRPSxM=")//125443356b3b312e30303b30343b4241544f4b13
        let stringData = String(data: message!, encoding: String.Encoding.ascii)
        let parsedData = MessageParser.parseLegacyMessage(stringData)

        XCTAssert(parsedData.type == .initialMessage)
        XCTAssert(parsedData.value is String)
    }

    func testIsomMessageConversion() {
        let message = Data(base64Encoded: "EklTOS9JUxMwMTswNDtCQVRPSxM=")//124953392f49531330313b30343b4241544f4b13
        let stringData = String(data: message!, encoding: String.Encoding.ascii)
        let parsedData = MessageParser.parseLegacyMessage(stringData)
        XCTAssert(parsedData.type == .isometric)
        XCTAssert(parsedData.value is String)
    }

    func testIMUData() {
        // FF0F FE1F FF07 FF0F FE1F FF07 92090907 == Values are: 1 g, 2 g, 0.5 g, 250 dps, 500 dps, 125 dps, 30 min
        let data = Data(base64Encoded: "/w/+H/8H/w/+H/8HkgkJBw==")
        let imuData = MessageParser.parseIMUValue(data: data!)
        XCTAssertEqual(imuData.accelerationX, 1.0, accuracy: 0.01)
        XCTAssertEqual(imuData.accelerationY, 2.0, accuracy: 0.01)
        XCTAssertEqual(imuData.accelerationZ, 0.5, accuracy: 0.01)

        XCTAssertEqual(imuData.gyroX, 4.36, accuracy: 0.01)
        XCTAssertEqual(imuData.gyroY, 8.72, accuracy: 0.01)
        XCTAssertEqual(imuData.gyroZ, 2.18, accuracy: 0.01)

        XCTAssertEqual(imuData.timestamp, 1800, accuracy: 0.001)
    }

    func testInvalidMessage() {
        let invalidMessage = "Some invalid message"
        XCTAssert(MessageParser.parseLegacyMessage(nil).type == .unknown)
        XCTAssert(MessageParser.parseLegacyMessage(invalidMessage).type == .unknown)
    }
}
