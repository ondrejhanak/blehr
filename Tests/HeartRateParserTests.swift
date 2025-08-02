//
//  HeartRateParserTests.swift
//  tests
//
//  Created by Ondrej Hanak on 02.08.2025.
//

import Testing
import Foundation
@testable import BLE_HR

struct HeartRateParserTests {
    @Test(arguments:
            [
                (0,   [0x00, 0x00]),
                (5,   [0x00, 0x05]),
                (255, [0x00, 0xFF]),
                (256,  [0x01, 0x00, 0x01]),
                (1023, [0x01, 0xFF, 0x03]),
            ]
    )
    func parseParsing(params: (Int, [UInt8])) {
        let bpm = HeartRateParser.parse(Data(params.1))
        #expect(bpm == params.0)
    }
}
