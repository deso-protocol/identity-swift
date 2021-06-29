//
//  File.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

protocol TransactionSignable {
    func signTransaction(_ transaction: UnsignedTransaction) -> String
}

class SignTransactionWorker: TransactionSignable {
    func signTransaction(_ transaction: UnsignedTransaction) -> String {
        // TODO: Actually sign the transaction and return the signed hex
        return ""
    }
}
