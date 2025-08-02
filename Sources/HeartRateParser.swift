//
//  HeartRateParser.swift
//  blehr
//
//  Created by Ondrej Hanak on 02.08.2025.
//

import Foundation

struct HeartRateParser {
    /// Parses data of a 2A37 notification.
    /// - Parameter data: The raw Data from the characteristic.
    /// - Returns: The decoded BPM.
    static func parse(_ data: Data) -> Int {
        let byteArray = [UInt8](data)
        let flag = byteArray[0]
        if flag & 0x01 == 0 {
            return Int(byteArray[1]) // UInt8
        } else {
            return Int(UInt16(byteArray[1]) | UInt16(byteArray[2]) << 8) // UInt16 little endian
        }
    }
}
