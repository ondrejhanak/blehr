//
//  SensorService.swift
//  blehr
//
//  Created by Ondrej Hanak on 31.07.2025.
//

import CoreBluetooth
import Combine

protocol SensorServiceType: AnyObject {
    var isConnectionAvailable: AnyPublisher<Bool, Never> { get }
    var connectedSensorName: AnyPublisher<String?, Never> { get }
    var heartRate: AnyPublisher<Int?, Never> { get }
    var heartbeatPulse: AnyPublisher<Void, Never> { get }

    func startScanning()
}

final class SensorService: NSObject, SensorServiceType {
    private let heartRateServiceUUID = CBUUID(string: "0x180D")
    private let heartRateMeasurementUUID = CBUUID(string: "0x2A37")
    private let isConnectionAvailableSubject = PassthroughSubject<Bool, Never>()
    private let connectedSensorNameSubject = PassthroughSubject<String?, Never>()
    private let heartRateSubject = PassthroughSubject<Int?, Never>()
    private let heartbeatPulseSubject = PassthroughSubject<Void, Never>()
    private var centralManager: CBCentralManager!

    private var heartRatePeripheral: CBPeripheral? {
        didSet {
            if let peripheral = heartRatePeripheral {
                connectedSensorNameSubject.send(peripheral.name ?? "???")
            } else {
                connectedSensorNameSubject.send(nil)
            }
        }
    }

    var isConnectionAvailable: AnyPublisher<Bool, Never> {
        isConnectionAvailableSubject.eraseToAnyPublisher()
    }

    var connectedSensorName: AnyPublisher<String?, Never> {
        connectedSensorNameSubject.eraseToAnyPublisher()
    }

    var heartRate: AnyPublisher<Int?, Never> {
        heartRateSubject.eraseToAnyPublisher()
    }

    var heartbeatPulse: AnyPublisher<Void, Never> {
        heartbeatPulseSubject.eraseToAnyPublisher()
    }

    // MARK: - Lifecycle

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Methods

    func startScanning() {
        heartRateSubject.send(nil)
        connectedSensorNameSubject.send(nil)
        centralManager.stopScan()
        centralManager.scanForPeripherals(withServices: [heartRateServiceUUID])
    }

    // MARK: - Private

    private func parseHeartRate(data: Data) -> Int {
        let byteArray = [UInt8](data)
        let flag = byteArray[0]
        if flag & 0x01 == 0 {
            return Int(byteArray[1]) // UInt8
        } else {
            return Int(UInt16(byteArray[1]) | UInt16(byteArray[2]) << 8) // UInt16 little endian
        }
    }
}

extension SensorService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let isAvailable = central.state == .poweredOn
        isConnectionAvailableSubject.send(isAvailable)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        startScanning()
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
        heartRatePeripheral = peripheral
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
}

extension SensorService: CBPeripheralDelegate {
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
        heartbeatPulseSubject.send(())
        heartRateSubject.send(bpm)
    }
}
