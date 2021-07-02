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
                                                  signedHash: "bla")
    
    var calledStoreInfo: Bool = false
    var infoRequestedToStore: DerivedKeyInfo?
    func store(_ info: DerivedKeyInfo) throws {
        calledStoreInfo = true
        infoRequestedToStore = info
    }
    
    var calledClearAllDerivedKeys: Bool = false
    func clearAllDerivedKeyInfo() throws {
        calledClearAllDerivedKeys = true
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
}
