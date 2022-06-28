# Activ5-Device

[![CI Status](https://img.shields.io/travis/starbuckbg/Activ5-Device.svg?style=flat)](https://travis-ci.org/starbuckbg/Activ5-Device)
[![Version](https://img.shields.io/cocoapods/v/Activ5-Device.svg?style=flat)](https://cocoapods.org/pods/Activ5-Device)
[![License](https://img.shields.io/cocoapods/l/Activ5-Device.svg?style=flat)](https://cocoapods.org/pods/Activ5-Device)
[![Platform](https://img.shields.io/cocoapods/p/Activ5-Device.svg?style=flat)](https://cocoapods.org/pods/Activ5-Device)

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
var deviceDataState: A5DeviceDataState = .disconnected
var deviceVersion: String?
var evergreenMode: Bool = false
```

### Functionality
#### Initialize
```swift
init(device: CBPeripheral, name: String? = nil, writeCharacteristic: CBCharacteristic? = nil, readCharacteristic: CBCharacteristic? = nil)
```

#### Device Communication
```swift
func sendCommand(_ command: A5Command)
func sendMessage(message: String)
func startIsometric()
func stop()
func disconnect()
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
static let bluetoothQueue: DispatchQueue
static var devices: [String: A5Device]
static var connectedDevices: [String: A5Device]
static var options: A5DeviceManagerOptions
```

### Functionality
```swift
class func scanForDevices(searchCompleted: @escaping () -> Void)
class func connect(device: CBPeripheral)
class func send(message: String, to device: A5Device)
class func device(for peripheral: CBPeripheral) -> (key: String, value:A5Device)?
```

### A5DeviceManagerOptions
```swift
public struct A5DeviceManagerOptions {
var services: [CBUUID] = [CBUUID(string: "0x5000")]
var autoHandshake: Bool = true
var searchTimeout = 30.0
}
```

## A5DeviceManagerDelegate
```swift
func searchCompleted()
func deviceFound(device: A5Device)
func deviceConnected(device: A5Device)
func deviceDisconnected(device: A5Device)
func didReceiveMessage(device: A5Device, message: String, type: MessageType)
func didReceiveIsometric(device: A5Device, value: Int)
func didFailToConnect(device: A5Device, error: Error?)
func didChangeBluetoothState(_ state: CBManagerState)
func bluetoothIsSwitchedOff()
```

### Default implementations
```swift
func didFailToConnect(device: CBPeripheral, error: Error?) {}
func didReceiveMessage(device: A5Device, message: String, type: MessageType) {}
func didReceiveIsometric(device:A5Device, value: Int) {}
func didChangeBluetoothState(_ state: CBManagerState) {}
func bluetoothIsSwitchedOff() {}
```


## Author

martin-key, martinkuvandzhiev@gmail.com

## License

Activ5-Device is available under the MIT license. See the LICENSE file for more info.
