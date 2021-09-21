//
//  JWTCreator.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

protocol JWTFetchable {
    // TODO: Confirm interface. Might need something more to specify the public key to use
    func getJWT(for publicKey: String) throws -> String
}

class JWTWorker: JWTFetchable {
    
    private let keyStore: KeyInfoStorable
    
    init(keyStore: KeyInfoStorable = KeyInfoStorageWorker()) {
        self.keyStore = keyStore
    }
    
    func getJWT(for publicKey: String) throws -> String {
        guard let keyInfo = try keyStore.getDerivedKeyInfo(for: publicKey) else {
            throw IdentityError.missingInfoForPublicKey
        }
        
        // TODO: Check if derived key is expired and get a new one if necessary?
        
        return ""
    }
}
