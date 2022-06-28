# Activ5-Device
[![Swift](https://github.com/ActivBody/activ5-ios-bluetooth/actions/workflows/swift.yml/badge.svg)](https://github.com/ActivBody/activ5-ios-bluetooth/actions/workflows/swift.yml)
[![Release XC Framework](https://github.com/ActivBody/activ5-ios-bluetooth/actions/workflows/release-framework.yml/badge.svg)](https://github.com/ActivBody/activ5-ios-bluetooth/actions/workflows/release-framework.yml)
[![codecov](https://codecov.io/gh/ActivBody/activ5-ios-bluetooth/branch/develop/graph/badge.svg?token=5DHbG3Px8B)](https://codecov.io/gh/ActivBody/activ5-ios-bluetooth)
## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Activ5-Device is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Activ5-Device'
```

# Use of framework

## Basic funtionality

### Framework initialisation
In order to initialize the framework you need to call the following function. The best please to call it is in **AppDelegate** or somewhere a bit before calling Bluetooth related functions.

```swift
A5DeviceManager.initializeDeviceManager()
```

You need also to set who is the delegate who will receive the callbacks from the frame work. This is mostly done in the **ViewControllers** responsible for Device connect/disconnect and the ones that are receiving data from the device. Do not forget to set that the class is implementing the A5DeviceDelegate protocol.

```swift
class ViewController: A5DeviceDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        A5DeviceManager.delegate = self
    }
}
```

### Search for devices
You need to search for devices in order to load the devices. Each time a new device has been found

```swift
A5DeviceManager.scanForDevices {
// Action when a device has been found
}
```

A delegate call is being called as well. You can choose which approach to use.
```swift
func deviceFound(device: A5Device) {
// Action when a device has been found
}
```

When the device search timeouts a delegate function is being called.
```swift
func searchCompleted() {
// Action when a device search has been completed (timed out)
}
```


### Connect to a device
Connecting a device is easy. You just need to select the right one from the devices found and call  `connect`
```swift
A5DeviceManager.connect(device: aDevice.device) // you need to call the CBDevice property of the A5Device. 
```

When a device has been connected the delegate function `deviceConnected` is going to be called.
```swift
func deviceConnected(device: A5Device) {
// Action to do when a device is connected. Probably show the user that connection is successful and then call 
}
```

### Request Isometric Data from the A5 device
Isometric data start to be stream when `startIsometric()` is called.
```swift
device.startIsometric()
```

The isometric data is going to be received in the delegate function `didReceiveIsometric`. The `value` received is in Newtons.
```swift
func didReceiveIsometric(device: A5Device, value: Int) {
// Action when isometric data is received
}
```

### Stop receiving isometric data
In order to save device battery it is recomended to call `stop()` function. That way the device consumption drops to a minimum while still is being connected. 

```swift
device.stop()
```
_NB: After 7 minutes in `stop mode` the device will switch switch off_
If you don't want the device to timeout after 7 minutes you can switch on evergreen mode. This will keep the device awake.

```swift
device.evergreenMode = true
```

### Disconnect device
Disconnecting the device happens with calling `disconnect()` function
```swift 
device.disconnect()
```

After the device has been disconnected (it can happen also if the device is switched off by the user) the following delegate method is being called.
```swift
func deviceDisconnected(device: A5Device) {
// May show the user that the device has been disconnected or retry to connect if needed.
}
```


# Extended documentation

## A5Device
### Properties
```swift
var device: CBPeripheral
var name: String?
var writeCharacteristic: CBCharacteristic?
var readCharacteristic: CBCharacteristic?
public var usesNewProtocol: Bool = false
public var forceCharacteristic: CBCharacteristic?
public var imuCharacteristic: CBCharacteristic?
public var timestampCharacteristic: CBCharacteristic?
public var sampleRateCharacteristic: CBCharacteristic?
public var batteryLevelCharacteristic: CBCharacteristic?
public var serialNumberCharacteristic: CBCharacteristic?
public var communicationInitialized: Bool = false
public var rssi: Double = 0
public var deviceDataState: A5DeviceDataState = .disconnected
public var deviceVersion: String?
public var evergreenMode: Bool = false {
    didSet {
        setEvergreen(evergreenMode)
    }
}
public var connected: Bool {
    switch self.deviceDataState {
    case .disconnected:
        return false
    default:
        return true
    }
}
var forgetAfterDisconnected: Bool = false
private var evergreenTimer: Timer?
public var shouldReconnect = true
```

### Functionality
#### Initialize
```swift
init(device: CBPeripheral, name: String? = nil, writeCharacteristic: CBCharacteristic? = nil, readCharacteristic: CBCharacteristic? = nil)
```

#### Device Characteristics
```swift
enum Characteristic: String {
    case read = "5A01"
    case write = "5A02"
    case force = "F0FE"
    case timestamp = "F0F3"
    case imu = "F0F5"
    case sn1 = "SN1"
    case sn2 = "SN2"
    case sampleRate = "F0FA"
    case battery = "2A19"
    case serialNumber = "2A25"
    case unknown = "FFFF"
}
```

#### Device Communication
```swift
func sendCommand(_ command: A5Command)
func sendMessage(message: String)
func startIsometric()
func getBatteryLevel() throws -> Int
func getSerialNumber() -> String
func startIMU() throws
func stopIMU() throws 
func stop()
func disconnect()
```

#### Available Commands
```swift
    case doHandshake = "TVGTIME"
    case startIsometric = "ISOM!"
    case tare = "TARE!"
    case stop = "STOP!"
    case sn1 = "SN1!"
    case sn2 = "SN2!"
    case battery = "2A19"
    case serialNumber = "2A25"
}
```

#### Available Device States
```swift
public enum A5DeviceDataState {
case handshake
case isometric
case heartRate // Depricated
case stop
case disconnected
}
```

## A5DeviceManager
### Properties
```swift
static let instance: A5DeviceManager
static var delegate: A5DeviceDelegate?
private static let bluetoothQueue = DispatchQueue(label: "A5-Dispatch-Queue")
static let cbManager: CBCentralManager
static var devices: [String: A5Device]
static var connectedDevices: [String: A5Device]
static var options: A5DeviceManagerOptions
public static var squeezeState: A5SqueezeState
private static var searchTimer: Timer?
public static var connectionState: A5DeviceManagerConnectionState
```

### Functionality
```swift
public class func initializeDeviceManager()
public class func disconnectAllDevices()
public class func stopScanningForDevices()
class func scanForDevices(searchCompleted: @escaping () -> Void)
class func connect(device: CBPeripheral)
class func send(message: String, to device: A5Device)
class func device(for peripheral: CBPeripheral) -> (key: String, value:A5Device)?
```

### A5DeviceManagerOptions
```swift
public struct A5DeviceManagerOptions {
    public var services: [CBUUID] = [CBUUID(string: "0x5000")]
    public var autoHandshake: Bool = true
    public var searchTimeout = 30.0
    public var reconnectionStrategy: A5ReconnectStrategy = .automatically
    public var squeezeThreshold: SqueezeThreshold
}
```

#### A5DeviceManagerConnectionState
```swift
public enum A5DeviceManagerConnectionState {
    case disconnected
    case searching
    case connected
}
```

#### A5ReconnectStrategy
```swift
public enum A5ReconnectStrategy {
    case manually
    case automatically
}
```

#### A5SqueezeState
```swift
public enum A5SqueezeState {
    case squeezed
    case depressed
}
```



## A5DeviceManagerDelegate
```swift
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
```

### Default implementations
```swift
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
```

## DoubleSqueezeHelper

### Properties
```swift
    static var squeezeThreshold:SqueezeThreshold
    static var doublePressState: DoublePressState
    static var resetTimer: Timer?
```

### Double press states
```swift
enum DoublePressState {
    case initial, firstPressed, firstPressCompleted, secondPressed
}
```

### Double squeeze threshold
```swift
public struct SqueezeThreshold{
    var pressed = 20.0
    var depressed = 5.0
    
    static let base = SqueezeThreshold(pressed: 20, depressed: 5)
}
```

### Functionality
```swift
static func evaluateDoublePress(force: Double, onPressed: VoidClosure? = nil, onDepressed: VoidClosure? = nil, onSuccess: VoidClosure)
```

## IMUObject

### Properties
```swift
public var accelerationX: Double
public var accelerationY: Double
public var accelerationZ: Double
public var gyroX: Double
public var gyroY: Double
public var gyroZ: Double
public var timestamp: Double
var scaledValue: IMUObject
```
### Initializer
```swift
public init(accelerationX: Double, accelerationY: Double, accelerationZ: Double, gyroX: Double, gyroY: Double, gyroZ: Double, timestamp: Double)
```

### Int extensions for IMU objects
```swift
 var toGForce: Double
 var toRadPerSec: Double
 var toSec: Double
 var fromGForce: Int
 var fromRadPerSec: Int
 var fromSec: Int
```

## MessageParser

### Message type 
```swift
public enum MessageType: String {
    case initialMessage = "TC5k"
    case isometric = "IS"
    case timestamp = "TS"
    case imu = "IM"
    case sn1 = "SN1"
    case sn2 = "SN2"
    case battery = "battery"
    case serialNumber = "serialNumber"
    case unknown = "unknown"
    public init(from message: String)
}
```

### Functionality
```swift
public class func parseMessage(characteristic: CBCharacteristic)->(type: MessageType, value: Any?)
public class func parseLegacyMessage(_ message: String?) -> (type: MessageType, value: Any?)
 public class func parseValue(data: Data) -> Int
```




## Author

martin-key, martinkuvandzhiev@gmail.com

## License

Activ5-Device is available under the MIT license. See the LICENSE file for more info.
