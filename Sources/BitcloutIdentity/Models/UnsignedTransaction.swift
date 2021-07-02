//
//  UnsignedTransaction.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

public struct UnsignedTransaction: Equatable {
    let accessLevel: AccessLevel
    let accessLevelHmac: String
    let encryptedSeedHex: String
    let transactionHex: String
}
