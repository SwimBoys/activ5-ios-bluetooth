//
//  ViewController.swift
//  Activ5-Device
//
//  Created by starbuckbg on 08/27/2018.
//  Copyright (c) 2018 starbuckbg. All rights reserved.
//

import UIKit
import CoreBluetooth
import Activ5Device

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    var devices: [String: A5Device] = A5DeviceManager.devices
    var lastMessage: [String: String] = [:]
    lazy var deviceNames: [String] = {return Array(self.devices.keys)}()
    var serialNumber: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        A5DeviceManager.delegate = self
        checkAppearance()
    }

    func checkAppearance() {
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                view.backgroundColor = .black
            } else {
                view.backgroundColor = .white
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        checkAppearance()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func searchForDevicesTapped(_ sender: Any) {
        self.statusLabel.text = "Searching for devices"
        A5DeviceManager.scanForDevices {
            // Action when a device has been found
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let deviceName = self.deviceNames[indexPath.row]
        cell.textLabel?.text = deviceName
        cell.detailTextLabel?.text = ""
        if let deviceInfo = self.devices[deviceName] {
            if deviceInfo.deviceDataState == .disconnected {
                cell.detailTextLabel?.text = "Disconnected"
            } else {
                cell.detailTextLabel?.text = self.lastMessage[deviceName] ?? ""
            }
        }

        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let device = self.devices[deviceNames[indexPath.row]] else {
            return
        }

        let alertSheet = UIAlertController(title: "Select action", message: nil, preferredStyle: .actionSheet)

        let connectAction = UIAlertAction(title: "Connect", style: .default) { (_) in
            A5DeviceManager.connect(device: device.device)
        }
        let disconnectAction = UIAlertAction(title: "Disconnect", style: .destructive) { (_) in
            device.disconnect()
        }
        let requestIsomAction = UIAlertAction(title: "Request isometric", style: .default) { (_) in
            device.startIsometric()
        }
        let requestTare = UIAlertAction(title: "Request tare", style: .default) { (_) in
            device.sendCommand(.tare)
        }
        let requestStop = UIAlertAction(title: "Request stop", style: .default) { (_) in
            device.stop()
        }

        let startIMUAction = UIAlertAction(title: "Start IMU", style: .default) { (_) in
            do {
                try device.startIMU()
            } catch {
                self.statusLabel.text = "IMU Unavailable on that device"
            }
        }

        let stopIMUAction = UIAlertAction(title: "Stop IMU", style: .default) { (_) in
            do {
                try device.stopIMU()
            } catch {
                self.statusLabel.text = "IMU Unavailable on that device"
            }
        }

        let switchOnEvergreenMode = UIAlertAction(title: "Swith On Evergreen", style: .default) { (_) in
            device.evergreenMode = true
        }
        let switchOffEvergreenMode = UIAlertAction(title: "Swith Off Evergreen", style: .destructive) { (_) in
            device.evergreenMode = false
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            alertSheet.dismiss(animated: true, completion: nil)
        }
        let setFastSampleRateAction = UIAlertAction(title: "Set 25ms Sample Rate", style: .default) { (_) in
            device.setSampleRate(sampleRate: 25)
        }
        let setStandardSampleRateAction = UIAlertAction(title: "Set 100ms Sample Rate", style: .default) { (_) in
            device.setSampleRate(sampleRate: 100)
        }

        let serialNumberAction = UIAlertAction(title: "Serial Number", style: .default) { (_) in
            let serialNumber =  device.getSerialNumber()

            if let deviceName = device.name {
                self.lastMessage[deviceName] = serialNumber
                if let deviceIndex = self.deviceNames.index(of: deviceName) {
                    self.tableView.reloadRows(at: [IndexPath(row: deviceIndex, section: 0)], with: .none)
                }
            }
        }
        let disconnectAllAction = UIAlertAction(title: "Disconnect All Devices", style: .destructive) { (_) in
            A5DeviceManager.disconnectAllDevices()
        }

        let batteryAction = UIAlertAction(title: "Battery percentage", style: .default) { (_) in
            guard let percentage = try? device.getBatteryLevel() else {
                self.statusLabel.text = "Battery level is not readable"
                return
            }

            if let deviceName = device.name {
                self.lastMessage[deviceName] = String(format: "%d %%", percentage)
                if let deviceIndex = self.deviceNames.index(of: deviceName) {
                    self.tableView.reloadRows(at: [IndexPath(row: deviceIndex, section: 0)], with: .none)
                }
            }
        }

        switch device.deviceDataState {
        case .disconnected:
            alertSheet.addAction(connectAction)
            alertSheet.addAction(cancelAction)
        default:
            alertSheet.addAction(requestIsomAction)
            alertSheet.addAction(requestTare)
            alertSheet.addAction(requestStop)
            alertSheet.addAction(startIMUAction)
            alertSheet.addAction(stopIMUAction)
            alertSheet.addAction(setFastSampleRateAction)
            alertSheet.addAction(setStandardSampleRateAction)
            alertSheet.addAction(serialNumberAction)
            alertSheet.addAction(batteryAction)
            switch device.evergreenMode {
            case true:
                alertSheet.addAction(switchOffEvergreenMode)
            case false:
                alertSheet.addAction(switchOnEvergreenMode)
            }
            alertSheet.addAction(disconnectAction)
            alertSheet.addAction(disconnectAllAction)
            alertSheet.addAction(cancelAction)
        }

        self.present(alertSheet, animated: true, completion: nil)

    }
}

extension ViewController: A5DeviceDelegate {
    func deviceInitialized(device: A5Device) {
        if let deviceName = device.name {
            self.lastMessage[deviceName] = "Connected"
            if let deviceIndex = self.deviceNames.index(of: deviceName) {
                self.tableView.reloadRows(at: [IndexPath(row: deviceIndex, section: 0)], with: .none)
            }
        }
    }

    func searchCompleted() {
        self.statusLabel.text = "Search completed"
    }

    func deviceFound(device: A5Device) {
        self.devices = A5DeviceManager.devices
        deviceNames = Array(self.devices.keys)
        self.statusLabel.text = (device.name ?? "A Device") + " found"
        self.tableView.reloadData()
    }

    func deviceConnected(device: A5Device) {
        self.statusLabel.text = (device.name ?? "A Device") + " connected"
    }

    func didReceiveMessage(device: A5Device, message: String, type: MessageType) {
        if let deviceName = device.name {
            var messageToShow = ""
            switch type {
            case .initialMessage:
                messageToShow = "Connected"
            case .isometric:
                break
            default:
                messageToShow = ""
            }

            self.lastMessage[deviceName] = messageToShow

            if let deviceIndex = self.deviceNames.index(of: deviceName) {
                self.tableView.reloadRows(at: [IndexPath(row: deviceIndex, section: 0)], with: .none)
            }
        }
    }

    func didReceiveSerialNumber(device: A5Device, value: String) {
        if let deviceName = device.name {
            self.lastMessage[deviceName] = value
            if let deviceIndex = self.deviceNames.index(of: deviceName) {
                self.tableView.reloadRows(at: [IndexPath(row: deviceIndex, section: 0)], with: .none)
            }
        }
    }
    
    func didReceiveBattery(device: A5Device,value: UInt64) {
        self.statusLabel.text = "Battery level fetched"
        if let deviceName = device.name {
            self.lastMessage[deviceName] = String(format: "%d %%", value)
            if let deviceIndex = self.deviceNames.index(of: deviceName) {
                self.tableView.reloadRows(at: [IndexPath(row: deviceIndex, section: 0)], with: .none)
            }
        }
    }


    func didReceiveIsometric(device: A5Device, value: Double) {
        if let deviceName = device.name {
            self.lastMessage[deviceName] = "IS" + value.description
            if let deviceIndex = self.deviceNames.index(of: deviceName) {
                self.tableView.reloadRows(at: [IndexPath(row: deviceIndex, section: 0)], with: .none)
            }
        }
    }

    func didReceiveIMUData(device: A5Device, value: IMUObject) {
        if let deviceName = device.name {
            self.lastMessage[deviceName] = String(format: "X%0.2f Y%0.2f Z%0.2f", value.accelerationX, value.accelerationY, value.accelerationZ)
            print(Date())
            if let deviceIndex = self.deviceNames.index(of: deviceName) {
                self.tableView.reloadRows(at: [IndexPath(row: deviceIndex, section: 0)], with: .none)
            }
        }
    }

    func didDetectDoubleSqeeze(device: A5Device) {
        self.statusLabel.text = "\(device.name ?? "") Detected Double Sqeeze"
    }

    func deviceDisconnected(device: A5Device) {
        self.statusLabel.text = (device.name ?? "A Device") + " disconnected"
        self.devices = A5DeviceManager.devices
        deviceNames = Array(self.devices.keys)
        self.tableView.reloadData()
    }

    func didFailToConnect(device: A5Device, error: Error?) {

    }
}
