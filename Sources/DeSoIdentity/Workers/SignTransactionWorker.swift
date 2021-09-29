//
//  SignTransactionWorker.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

protocol TransactionSignable {
    func signTransaction(_ transaction: UnsignedTransaction) throws -> String
}

class SignTransactionWorker: TransactionSignable {
    
    private let keyStore: KeyInfoStorable
    
    init(keyStore: KeyInfoStorable = KeyInfoStorageWorker()) {
        self.keyStore = keyStore
    }
    
    func signTransaction(_ transaction: UnsignedTransaction) throws -> String {
        guard let key = try keyStore.getDerivedKeyInfo(for: transaction.publicKey) else {
            throw IdentityError.missingInfoForPublicKey
        }
        
        return try DeSoIdentity.signTransaction(seedHex: key.derivedSeedHex, transactionHex: transaction.transactionHex)
    }
}
