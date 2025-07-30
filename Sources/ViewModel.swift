//
//  ViewModel.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

@preconcurrency import CoreBluetooth
import Combine
import UIKit

@MainActor
final class HeartRateViewModel: NSObject, ObservableObject {
    @Published var heartRate: Int?
    @Published var heartbeatPulse = false
    @Published var subtitle: String?
    @Published var bluetoothAvailable = true

    private var centralManager: CBCentralManager!
    private var heartRatePeripheral: CBPeripheral?
    private nonisolated let heartRateServiceUUID = CBUUID(string: "0x180D")
    private nonisolated let heartRateMeasurementUUID = CBUUID(string: "0x2A37")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func startScanning() {
        heartRate = nil
        subtitle = "Searching for a sensor..."
        centralManager.scanForPeripherals(withServices: [heartRateServiceUUID])
    }

    private nonisolated func parseHeartRate(data: Data) -> Int {
        let byteArray = [UInt8](data)
        let flag = byteArray[0]
        if flag & 0x01 == 0 {
            return Int(byteArray[1]) // UInt8
        } else {
            return Int(UInt16(byteArray[1]) | UInt16(byteArray[2]) << 8) // UInt16 little endian
        }
    }

    private func handleAvailabilityChange(_ isAvailable: Bool) {
        bluetoothAvailable = isAvailable
        if isAvailable {
            startScanning()
        }
    }
}

nonisolated extension HeartRateViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let isAvailable = central.state == .poweredOn
        Task { @MainActor in
            handleAvailabilityChange(isAvailable)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        Task { @MainActor in
            startScanning()
        }
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
        peripheral.delegate = self
        central.stopScan()
        central.connect(peripheral, options: nil)
        Task { @MainActor in
            heartRatePeripheral = peripheral
            subtitle = peripheral.name
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
}

nonisolated extension HeartRateViewModel: CBPeripheralDelegate {
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
        let bpm = parseHeartRate(data: data)
        Task { @MainActor in
            heartRate = bpm
            heartbeatPulse.toggle()
        }
    }
}
