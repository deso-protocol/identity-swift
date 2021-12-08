//
//  AuthorizeDerivedKeyRequest.swift
//  
//
//  Created by Jacob Davis on 12/7/21.
//

import Foundation

internal struct AuthorizeDerivedKeyResponse: Codable {

    let spendAmountNanos: UInt64
    let totalInputNanos: UInt64
    let changeAmountNanos: UInt64
    let feeNanos: UInt64
    let transactionHex: String
    let txnHashHex: String
}

internal struct AuthorizeDerivedKeyRequest: PostRequest {
    
    static var endpoint: URL {
        return DeSoIdentity.baseURL
            .appendingPathComponent(DeSoIdentity.basePath)
            .appendingPathComponent("authorize-derived-key")
    }
    
    let ownerPublicKeyBase58Check: String
    let derivedPublicKeyBase58Check: String
    let expirationBlock: UInt64
    let accessSignature: String
    let deleteKey: Bool
    let derivedKeySignature: Bool
    let minFeeRateNanosPerKB: UInt64
    
    init(withDerivedKeyInfo derivedKeyInfo: DerivedKeyInfo, deleteKey: Bool = false) {
        self.ownerPublicKeyBase58Check = derivedKeyInfo.publicKey
        self.derivedPublicKeyBase58Check = derivedKeyInfo.derivedPublicKey
        self.expirationBlock = derivedKeyInfo.expirationBlock
        self.accessSignature = derivedKeyInfo.accessSignature
        self.deleteKey = deleteKey
        self.derivedKeySignature = true
        self.minFeeRateNanosPerKB = 1500
    }
}
