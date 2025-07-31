//
//  HeartRateView.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

import SwiftUI

struct HeartRateView: View {
    @ObservedObject var viewModel: HeartRateViewModel

    var body: some View {
        VStack(spacing: 30) {
            Text("Heart Rate")
                .font(.title)

            if !viewModel.bluetoothAvailable {
                Text("Please enable Bluetooth to see the heart rate.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Button("Settings") {
                    viewModel.openSettings()
                }
                .buttonStyle(.borderedProminent)
            } else if let bpm = viewModel.heartRate {
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .scaleEffect(viewModel.heartbeatPulse ? 1.25 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.3), value: viewModel.heartbeatPulse)
                    Text(bpm, format: .number)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundColor(.red)
                if let sensorName = viewModel.sensorName {
                    Text(sensorName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                ProgressView()
                Text("Searching for a sensor...")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

#Preview {
    HeartRateView(viewModel: .init())
}
