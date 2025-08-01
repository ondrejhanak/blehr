//
//  SensorState.swift
//  blehr
//
//  Created by Ondrej Hanak on 31.07.2025.
//

import Foundation

struct SensorInfo: Identifiable, Equatable {
    let id: UUID
    let bpm: Int
    let name: String?
    let timestamp: Date
}

enum SensorState: Equatable {
    case disabled
    case ready
    case scanning
    case connected(SensorInfo)
}
