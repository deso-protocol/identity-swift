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
        
        // TODO: Can we check here if the derived key is still valid, or should we sign it, try to commit, and see if it fails?
        
        let signed = try sign(privateKey: key.newPrivateKey.uInt8Array, msg: transaction.transactionHex.uInt8Array)
        guard let signedString = signed.stringValue else {
            throw IdentityError.signatureNotAString
        }
        
        return signedString
    }
}
