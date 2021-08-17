//
//  File.swift
//  
//
//  Created by Andy Boyd on 11/08/2021.
//

import Foundation

protocol UIntToBytesConvertable {
    var toBytes: [UInt8] { get }
}

extension UIntToBytesConvertable {
    func toByteArr<T: BinaryInteger>(endian: T, count: Int) -> [UInt8] {
        var _endian = endian
        let bytePtr = withUnsafePointer(to: &_endian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return [UInt8](bytePtr)
    }
}

extension UInt16: UIntToBytesConvertable {
    var toBytes: [UInt8] {
        if CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) {
            return toByteArr(endian: self.littleEndian,
                         count: MemoryLayout<UInt16>.size)
        } else {
            return toByteArr(endian: self.bigEndian,
                             count: MemoryLayout<UInt16>.size)
        }
    }
}

extension UInt32: UIntToBytesConvertable {
    var toBytes: [UInt8] {
        if CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) {
        return toByteArr(endian: self.littleEndian,
                         count: MemoryLayout<UInt32>.size)
        } else {
            return toByteArr(endian: self.bigEndian,
                             count: MemoryLayout<UInt32>.size)
        }
    }
}

extension UInt64: UIntToBytesConvertable {
    var toBytes: [UInt8] {
        if CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) {
        return toByteArr(endian: self.littleEndian,
                         count: MemoryLayout<UInt64>.size)
        } else {
            return toByteArr(endian: self.bigEndian,
                             count: MemoryLayout<UInt64>.size)
        }
    }
}
