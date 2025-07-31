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
            switch viewModel.state {
            case .disabled:
                Text("Please enable Bluetooth to see the heart rate.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Button("Settings") {
                    viewModel.openSettings()
                }
                .buttonStyle(.borderedProminent)
            case .ready:
                EmptyView() // no visual representation
            case .scanning:
                ProgressView()
                Text("Searching for a sensor...")
                    .font(.caption)
                    .foregroundColor(.gray)
            case .connected(let info):
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .scaleEffect(viewModel.heartbeatPulse ? 1.25 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.3), value: info.timestamp)
                    Text(info.bpm, format: .number)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundColor(.red)
                Text(info.name)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

#if DEBUG
#Preview("connected") {
    let info = SensorInfo(bpm: 123, name: "Preview Sensor", timestamp: .now)
    let service = SensorServiceMock(state: .connected(info))
    return HeartRateView(viewModel: HeartRateViewModel(sensorService: service))
}

#Preview("disabled") {
    let service = SensorServiceMock(state: .disabled)
    return HeartRateView(viewModel: HeartRateViewModel(sensorService: service))
}

#Preview("ready") {
    let service = SensorServiceMock(state: .ready)
    return HeartRateView(viewModel: HeartRateViewModel(sensorService: service))


}

#Preview("scanning") {
    let service = SensorServiceMock(state: .scanning)
    return HeartRateView(viewModel: HeartRateViewModel(sensorService: service))

}
#endif
