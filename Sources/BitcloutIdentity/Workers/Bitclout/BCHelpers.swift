//
//  File.swift
//  
//
//  Created by Andy Boyd on 20/08/2021.
//

import Foundation
import Base58

enum Base58Error: Error {
    case invalidFormat
}

func Base58CheckDecodePrefix(input: String, prefixLen: Int) throws -> (result: [UInt8], prefix: [UInt8]) {
    guard !input.isEmpty else { throw Base58Error.invalidFormat }
    let decoded = try Base58.decode(input.makeBytes())
    if decoded.count < 5 {
        throw Base58Error.invalidFormat
    }
// TODO: figure out checksums
//        var cksum : [UInt8] = decoded.suffix(4) //[4]byte
////        copy(cksum[:], decoded[len(decoded)-4:])
//        if checksum(decoded[:len(decoded)-4]) != cksum {
//            return nil, nil, errors.Wrap(fmt.Errorf("CheckDecode: Checksum does not match"), "")
//        }
    let prefix = decoded.prefix(prefixLen)
    let payload = decoded.slice(from: prefixLen, to: decoded.count - 4)
    return (payload, Array(prefix))
}
