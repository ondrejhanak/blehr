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
                disabledView
            case .ready:
                EmptyView() // no visual representation
            case .scanning:
                scanningView
            case let .connected(info):
                PulseView(info: info)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var disabledView: some View {
        Text("Please enable Bluetooth to see the heart rate.")
            .font(.body)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
        Button("Settings") {
            viewModel.openSettings()
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    private var scanningView: some View {
        ProgressView()
        Text("Searching for a sensor...")
            .font(.caption)
            .foregroundColor(.gray)
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
