//
//  HeartRateViewModel.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

import Combine
import UIKit

@MainActor
final class HeartRateViewModel: ObservableObject {
    private var sensorService: SensorServiceType
    private var cancellables = Set<AnyCancellable>()

    @Published var bluetoothAvailable = true
    @Published var heartRate: Int?
    @Published var heartbeatPulse = false
    @Published var sensorName: String?

    // MARK: - Lifecycle

    init(sensorService: SensorServiceType = SensorService()) {
        self.sensorService = sensorService
        setupObservation()
    }

    // MARK: - Methods

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Private

    private func setupObservation() {
        sensorService.isConnectionAvailable
            .receive(on: RunLoop.main)
            .sink { [weak self] isAvailable in
                self?.handleAvailabilityChange(isAvailable)
            }
            .store(in: &cancellables)
        sensorService.heartRate
            .receive(on: RunLoop.main)
            .assign(to: &$heartRate)
        sensorService.heartbeatPulse
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.heartbeatPulse.toggle()
            }
            .store(in: &cancellables)
        sensorService.connectedSensorName
            .receive(on: RunLoop.main)
            .assign(to: &$sensorName)
    }

    private func handleAvailabilityChange(_ isAvailable: Bool) {
        bluetoothAvailable = isAvailable
        if isAvailable {
            sensorService.startScanning()
        }
    }
}
