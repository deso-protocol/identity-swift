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
    var specifiedNodeURL: URL?
    var transactionRequestedForSign: UnsignedTransaction?
    func signTransaction(_ transaction: UnsignedTransaction,
                         on nodeURL: URL,
                         completion: @escaping (SignTransactionResponse) -> Void) throws {
        calledSignTransaction = true
        specifiedNodeURL = nodeURL
        transactionRequestedForSign = transaction
        completion(.success(mockSignedHex))
    }
    
}
