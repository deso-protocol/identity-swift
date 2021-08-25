//
//  File.swift
//  
//
//  Created by Andy Boyd on 20/08/2021.
//

import Foundation
import Base58
import CryptoSwift

enum Base58Error: Error {
    case invalidFormat
    case checksumError
}

func Base58CheckDecodePrefix(input: String, prefixLen: Int) throws -> (result: [UInt8], prefix: [UInt8]) {
    guard !input.isEmpty else { throw Base58Error.invalidFormat }
    let decoded = try Base58.decode(input.makeBytes())
    if decoded.count < 5 {
        throw Base58Error.invalidFormat
    }

    let toSum = decoded.slice(from: 0, to: decoded.count - 4)
    guard checksum(toSum) == decoded.suffix(4) else {
        throw Base58Error.checksumError
    }
    
    let prefix = decoded.prefix(prefixLen)
    let payload = decoded.slice(from: prefixLen, to: decoded.count - 4)
    return (payload, Array(prefix))
}

private func checksum(_ input: [UInt8]) -> [UInt8] {
    let h = Hash.sha256(input)
    let h2 = Hash.sha256(h)
    return h2.slice(from: 0, to: 4)
}
