//
//  UserDerivedKeyRequest.swift
//  
//
//  Created by Jacob Davis on 12/8/21.
//

import Foundation

internal struct UserDerivedKeyRequest: PostRequest {
    
    static var endpoint: URL {
        return DeSoIdentity.baseURL
            .appendingPathComponent(DeSoIdentity.basePath)
            .appendingPathComponent("get-user-derived-keys")
    }
    
    let publicKeyBase58Check: String

    init(publicKey: String) {
        self.publicKeyBase58Check = publicKey
    }
}

internal struct UserDerivedKeyResponse: Decodable {
    let derivedKeys: [String: UserDerivedKey]
    func derivedKey(forDerivedPublicKey publicKey: String) -> UserDerivedKey? {
        return derivedKeys[publicKey]
    }
}

internal struct UserDerivedKey: Decodable {
    let ownerPublicKeyBase58Check: String
    let derivedPublicKeyBase58Check: String
    let expirationBlock: UInt64
    let isValid: Bool
    var experationThreshold: UInt64 {
        return 100
    }
}
