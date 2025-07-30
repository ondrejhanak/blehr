//
//  ViewModel.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

import CoreBluetooth
import Combine
import UIKit

final class HeartRateViewModel: NSObject, ObservableObject {
    @Published var heartRate: Int?
    @Published var heartbeatPulse = false
    @Published var subtitle: String?

    private var centralManager: CBCentralManager!
    private var heartRatePeripheral: CBPeripheral?
    private let heartRateServiceUUID = CBUUID(string: "0x180D")
    private let heartRateMeasurementUUID = CBUUID(string: "0x2A37")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

extension HeartRateViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            print("Bluetooth is not available.")
            return
        }
        subtitle = "Searching for a sensor..."
        centralManager.scanForPeripherals(withServices: [heartRateServiceUUID])
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        guard let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool, isConnectable else {
            return
        }
        heartRatePeripheral = peripheral
        heartRatePeripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
        DispatchQueue.main.async {
            self.subtitle = peripheral.name
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
}

extension HeartRateViewModel: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        guard let service = services.first(where: { $0.uuid == heartRateServiceUUID }) else { return }
        peripheral.discoverCharacteristics([heartRateMeasurementUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        guard let characteristic = characteristics.first(where: { $0.uuid == heartRateMeasurementUUID }) else { return }
        peripheral.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let bpm = parseHeartRate(from: data)
        DispatchQueue.main.async {
            self.heartRate = bpm
            self.heartbeatPulse.toggle()
        }
    }

    private func parseHeartRate(from data: Data) -> Int {
        let byteArray = [UInt8](data)
        let flag = byteArray[0]
        if flag & 0x01 == 0 {
            return Int(byteArray[1]) // UInt8
        } else {
            return Int(UInt16(byteArray[1]) | UInt16(byteArray[2]) << 8) // UInt16 little endian
        }
    }
}
