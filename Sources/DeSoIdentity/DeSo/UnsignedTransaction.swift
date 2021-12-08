//
//  UnsignedTransaction.swift
//  
//
//  Created by Jacob Davis on 12/7/21.
//

import Foundation

public struct UnsignedTransaction: Codable {
    public let publicKey: String
    public let transactionHex: String
    
    public init(publicKey: String, transactionHex: String) {
        self.publicKey = publicKey
        self.transactionHex = transactionHex
    }
}
