//
//  File.swift
//  
//
//  Created by Andy Boyd on 02/07/2021.
//

import Foundation
@testable import DeSoIdentity

class MockKeyStore: KeyInfoStorable {
    var mockInfo: DerivedKeyInfo? = DerivedKeyInfo(publicKey: "foo",
                                                   derivedPublicKey: "bar",
                                                   derivedSeedHex: "bat",
                                                   btcDepositAddress: "12345",
                                                   expirationBlock: 23,
                                                   accessSignature: "djadlvjbdsljvb",
                                                   network: .testnet,
                                                   jwt: "jooooot",
                                                   derivedJwt: "tooooooj")
    
    var mockSharedSecret: SharedSecret? = SharedSecret(secret: "foo",
                                                       privateKey: "bar",
                                                       publicKey: "bat",
                                                       myTruePublicKey: "foobarbat")
    
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
    
    var calledGetSharedSecret: Bool = false
    var myPublicKeyToGetSharedSecret: String?
    var otherPublicKeyToGetSharedSecret: String?
    func getSharedSecret(for myPublicKey: String, and otherPublicKey: String) throws -> SharedSecret? {
        calledGetSharedSecret = true
        myPublicKeyToGetSharedSecret = myPublicKey
        otherPublicKeyToGetSharedSecret = otherPublicKey
        return mockSharedSecret
    }
    
    var calledGetAllSharedSecrets: Bool = false
    func getAllSharedSecrets() throws -> [SharedSecret] {
        calledGetAllSharedSecrets = true
        return [mockSharedSecret!]
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
