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
            if isProduction {
                HeartRateView(viewModel: viewModel)
            }
        }
    }

    private var isProduction: Bool {
        NSClassFromString("XCTestCase") == nil
    }
}
