//
//  File.swift
//  
//
//  Created by Andy Boyd on 02/07/2021.
//

import Foundation
@testable import DeSoIdentity

class MockTransactionSigner: TransactionSignable {
    var mockSignedHex: String = "foobarbat"
    
    var calledSignTransaction: Bool = false
    var transactionRequestedForSign: UnsignedTransaction?
    func signTransaction(_ transaction: UnsignedTransaction) throws -> String {
        calledSignTransaction = true
        transactionRequestedForSign = transaction
        return mockSignedHex
    }
    
    
}
