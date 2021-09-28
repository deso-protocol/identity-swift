//
//  File.swift
//  
//
//  Created by Andy Boyd on 28/09/2021.
//

import XCTest

@testable import DeSoIdentity

final class KeystoreTests: XCTestCase {
    
    var sut: EphemeralKeyStore!
    var readableKeychain: [String: String] {
        return sut.keychain as! [String: String]
    }
    
    var testInfo = DerivedKeyInfo(publicKey: "abcdef12345",
                                  derivedPublicKey: "oewbvowiuvweoi",
                                  derivedSeedHex: "eo838hfoiwe9g",
                                  btcDepositAddress: "38r87c43gbsiu",
                                  expirationBlock: 123,
                                  accessSignature: "f498hf2398hfvu47",
                                  network: .testnet,
                                  jwt: "fiweesboigf848",
                                  derivedJwt: "@e983yf0842h98h")
    
    override func setUp() {
        super.setUp()
        sut = EphemeralKeyStore()
    }
    
    func testStore() {
        try! sut.store(testInfo)
        let allStoredInfo = readableKeychain[StorableKeys.derivedKeyInfo.rawValue]!
        let allStoredData = Data(base64Encoded: allStoredInfo)!
        let storedKeys = try! JSONDecoder().decode([String: Data].self, from: allStoredData)
        let storedData = storedKeys[testInfo.publicKey]!
        let storedInfo = try! JSONDecoder().decode(DerivedKeyInfo.self, from: storedData)
        XCTAssertEqual(storedInfo, testInfo)
    }
    
    func testGet() {
        try! sut.store(testInfo)
        let storedInfo = try! sut.getDerivedKeyInfo(for: testInfo.publicKey)
        XCTAssertEqual(storedInfo, testInfo)
    }
    
    func testRemove() {
        try! sut.store(testInfo)
        XCTAssertNotNil(readableKeychain[StorableKeys.derivedKeyInfo.rawValue])
        
        try! sut.keychain.remove(StorableKeys.derivedKeyInfo.rawValue)
        XCTAssertNil(readableKeychain[StorableKeys.derivedKeyInfo.rawValue])
    }
}
