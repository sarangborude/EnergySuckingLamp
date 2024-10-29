//
//  ViewModel.swift
//  BLE Lamp
//
//  Created by Sarang Borude on 6/19/24.
//

import SwiftUI
import CoreBluetooth
import UIKit

@Observable
class BLEViewModel: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // properties
    private let centralManager = CBCentralManager()
    private var peripherals = [CBPeripheral]()
    private var remotePeripheral: CBPeripheral?
    static private var txCharacteristic : CBCharacteristic?
    private var rxCharacteristic : CBCharacteristic?
    private var characteristicValue = ""
    static private var lightPeripheral: CBPeripheral?
    static public var isPeripheralConnected = false

    
//    public var lightColor: Color = Color.black {
//        didSet {
//            if(isPeripheralConnected) {
//                let lightComponents = lightColor.components
//                let r = Int(lightComponents.red * 255)
//                let g = Int(lightComponents.green * 255)
//                let b = Int(lightComponents.blue * 255)
//                writeToDevice(value: "\(r),\(g),\(b)")
//            }
//        }
//    }
    
    override init() {
        super.init()
        centralManager.delegate = self
    }
    
    func startScan() {
        peripherals = []
        print("Now Scanning...")
        centralManager.scanForPeripherals(withServices: [BLEService_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        //Timer.scheduledTimer(timeInterval: 17, target: self, selector: #selector(stopScan), userInfo: nil, repeats: false)
    }
    
    @objc func stopScan() {
        self.centralManager.stopScan()
        print("Scan Stopped")
        print("Number of Peripherals Found: \(peripherals.count)")
    }
    
    func disconnectFromDevice () {
        guard let remotePeripheral = remotePeripheral else { return }
        centralManager.cancelPeripheralConnection(remotePeripheral)
    }
    
    static func writeToDevice(value: String) {
        guard
            let peripheral = lightPeripheral,
            isPeripheralConnected,
            let characteristic = txCharacteristic else { return }
        print("writing \(value) to lamp........ **** Celebrations!!!")
        guard let data = value.data(using: .utf8) else { return }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            
        case .unknown:
            break
        case .resetting:
            break
        case .unsupported:
            break
        case .unauthorized:
            break
        case .poweredOff:
            print("Bluetooth Disabled- Make sure your Bluetooth is turned on")
        case .poweredOn:
            startScan()
        @unknown default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        stopScan()
        self.peripherals.append(peripheral)
        centralManager.connect(peripheral, options: nil)
        if remotePeripheral == nil {
            print("We found a new peripheral device with services")
            print("Peripheral name: \(String(describing: peripheral.name))")
            print("**********************************")
            print ("Advertisement Data : \(advertisementData)")
            remotePeripheral = peripheral
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        
        
        print("*****************************")
        print("Connection complete")
        print("Peripheral info: \(peripheral)")
        BLEViewModel.lightPeripheral = peripheral
        BLEViewModel.isPeripheralConnected = true
        
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        centralManager.stopScan()
        print("Scan Stopped")
        
        //Discovery callback
        peripheral.delegate = self
        //Only look for services that matches transmit uuid
        peripheral.discoverServices([BLEService_UUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        BLEViewModel.lightPeripheral = nil
        BLEViewModel.isPeripheralConnected = false
        startScan()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("*******************************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            
            peripheral.discoverCharacteristics(nil, for: service)
        }
        print("Discovered Services: \(services)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("*******************************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        print("Found \(characteristics.count) characteristics!")
        
        for characteristic in characteristics {
            //looks for the right characteristic
            
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                BLEViewModel.txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == rxCharacteristic {
            guard let data = characteristic.value else { return }
            guard let value = String(bytes: data, encoding: .utf8) else { return }
            characteristicValue = value
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing to characteristic \(error)")
        }
        
        if characteristic == BLEViewModel.txCharacteristic {
            guard let data = characteristic.value else { return }
            guard let value = String(bytes: data, encoding: .utf8) else { return }
            print("wrote characteristic on Feather, value: \(value)")
        }
    }
}

extension Color {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {
        
#if canImport(UIKit)
        typealias NativeColor = UIColor
#elseif canImport(AppKit)
        typealias NativeColor = NSColor
#endif
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        
        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            // You can handle the failure here as you want
            return (0, 0, 0, 0)
        }
        
        return (r, g, b, o)
    }
}
