//
//  UnsignedTransaction.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

public struct UnsignedTransaction: Equatable {
    public let publicKey: String
    public let transactionHex: String
    
    public init(publicKey: String, transactionHex: String) {
        self.publicKey = publicKey
        self.transactionHex = transactionHex
    }
}
