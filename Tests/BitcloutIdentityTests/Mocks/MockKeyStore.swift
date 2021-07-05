//
//  File.swift
//  
//
//  Created by Andy Boyd on 02/07/2021.
//

import Foundation
@testable import BitcloutIdentity

class MockKeyStore: KeyInfoStorable {
    var mockInfo: DerivedKeyInfo? = DerivedKeyInfo(truePublicKey: "foo",
                                                  newPublicKey: "bar",
                                                  newPrivateKey: "bat",
                                                  signedHash: "bla",
                                                  jwt: "joooot")
    
    var calledStoreInfo: Bool = false
    var infoRequestedToStore: DerivedKeyInfo?
    func store(_ info: DerivedKeyInfo) throws {
        calledStoreInfo = true
        infoRequestedToStore = info
    }
    
    var calledClearDerivedKeyInfo: Bool = false
    var publicKeyRequestedForClearInfo: String?
    func clearDerivedKeyInfo(for publicKey: String) throws {
        calledClearDerivedKeyInfo = true
        publicKeyRequestedForClearInfo = publicKey
    }
    
    var calledGetDerivedKeyInfo: Bool = false
    var publicKeyRequestedForGetInfo: String?
    func getDerivedKeyInfo(for publicKey: String) throws -> DerivedKeyInfo? {
        calledGetDerivedKeyInfo = true
        publicKeyRequestedForGetInfo = publicKey
        return mockInfo
    }
    
    var calledGetAllStoredKeys: Bool = false
    func getAllStoredKeys() throws -> [String] {
        calledGetAllStoredKeys = true
        return ["foo"]
    }
    
    var calledStoreSharedSecret: Bool = false
    var sharedSecretToStore: SharedSecret?
    func store(sharedSecret: SharedSecret) throws {
        calledStoreInfo = true
        sharedSecretToStore = sharedSecret
    }
    
    var calledClearAllStoredInfo: Bool = false
    func clearAllStoredInfo() throws {
        calledClearAllStoredInfo = true
    }
    
    var calledClearAllSharedSecretsForKey: Bool = false
    var privateKeyToDeleteSharedSecretsFor: String?
    func clearAllSharedSecrets(for privateKey: String) throws {
        calledClearAllSharedSecretsForKey = true
        privateKeyToDeleteSharedSecretsFor = privateKey
    }
    
    var calledClearSharedSecret: Bool = false
    var privateKeyToClearSingleSharedSecret: String?
    var publicKeyToClearSingleSharedSecret: String?
    func clearSharedSecret(for privateKey: String, and publicKey: String) throws {
        calledClearSharedSecret = true
        privateKeyToDeleteSharedSecretsFor = privateKey
        publicKeyToClearSingleSharedSecret = publicKey
    }
}
