//
//  Test.m
//  
//
//  Created by Andy Boyd on 08/07/2021.
//

import XCTest
import Security
import SwiftECC
import BigInt
@testable import BitcloutIdentity

final class ECIESTests: XCTestCase {
    
    private func getRandomKeypair() -> (private: [UInt8], public: [UInt8])? {
        let domain = Domain.instance(curve: .EC256k1)
        let privateK = BInt(bitWidth: 256)
        let publicK = domain.multiply(domain.g, privateK)
        return (private: privateK.asMagnitudeBytes(), public: try! domain.encodePoint(publicK))
    }
    
    func testDerive() {
        let keysA = getRandomKeypair()
        let keysB = getRandomKeypair()
        
        let derived1 = try! derive(privateKeyA: keysA!.private, publicKeyB: keysB!.public)
        let derived2 = try! derive(privateKeyA: keysB!.private, publicKeyB: keysA!.public)
        XCTAssertEqual(derived1, derived2)
    }
    
    func testDeriveNegativeCase() {
        let keysA = getRandomKeypair()
        let keysB = getRandomKeypair()
        let keysC = getRandomKeypair()
        
        let derived1 = try! derive(privateKeyA: keysA!.private, publicKeyB: keysB!.public)
        let derived2 = try! derive(privateKeyA: keysB!.private, publicKeyB: keysC!.public)
        XCTAssertNotEqual(derived1, derived2)
    }
    
    func testVerify() {
        let keys = getRandomKeypair()
        let msg: [UInt8] = try! randomBytes(count: 32)
        
        let sig = try! sign(privateKey: keys!.private, msg: msg)
        let verified = try! verify(publicKey: keys!.public, msg: msg, sig: sig)
        XCTAssertTrue(verified)
    }
    
    func testVerifyNegativeCase() {
        let keys1 = getRandomKeypair()
        let keys2 = getRandomKeypair()
        let msg: [UInt8] = try! randomBytes(count: 32)
        
        let sig = try! sign(privateKey: keys1!.private, msg: msg)
        let verified = try! verify(publicKey: keys2!.public, msg: msg, sig: sig)
        XCTAssertFalse(verified)
    }
    
    func testEncryptDecryptLegacy() {
        let keys = getRandomKeypair()
        let msgText = "Hello, World!"
        let msg = msgText.uInt8Array
        XCTAssertNotEqual(msg.count, 0)
        
        let encrypted = try! encrypt(publicKeyTo: keys!.public, msg: msg, legacy: true)
        XCTAssertNotEqual(msg, encrypted)
        
        let decrypted = try! decrypt(privateKey: keys!.private, encrypted: encrypted, legacy: true)
        let decryptedText = decrypted.stringValue
        XCTAssertEqual(msgText, decryptedText)
    }
    
    func testEncryptDecryptShared() {
        let keysA = getRandomKeypair()!
        let keysB = getRandomKeypair()!
        
        let msgText = "Hello, World!"
        let msg = msgText.uInt8Array
        XCTAssertNotEqual(msg.count, 0)
        
        let encrypted = try! encryptShared(privateKeySender: keysA.private, publicKeyRecipient: keysB.public, msg: msg)
        XCTAssertNotEqual(msg, encrypted)
        
        let decrypted = try! decryptShared(privateKeyRecipient: keysB.private, publicKeySender: keysA.public, encrypted: encrypted)
        let decryptedText = decrypted.stringValue
        XCTAssertEqual(msgText, decryptedText)
    }
}
