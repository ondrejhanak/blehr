//
//  HeartRateApp.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

import SwiftUI

@main
struct HeartRateApp: App {
    @StateObject private var viewModel = HeartRateViewModel()

    var body: some Scene {
        WindowGroup {
            HeartRateView(viewModel: viewModel)
        }
    }
}
