//
//  Test.m
//  
//
//  Created by Andy Boyd on 08/07/2021.
//

import XCTest
import SwiftECC
import BigInt
import CryptoSwift
import ASN1
import Base58

@testable import BitcloutIdentity

final class ECIESTests: XCTestCase {
    
    private func getRandomKeypair() -> (private: [UInt8], public: [UInt8])? {
        let privateK = BInt(bitWidth: 256)
        return (private: privateK.asMagnitudeBytes(), public: getPublicKeyBuffer(from: privateK))
    }
    
    private func getPublicKeyBuffer(from privateKey: BInt) -> [UInt8] {
        let domain = Domain.instance(curve: .EC256k1)
        let publicK = domain.multiply(domain.g, privateKey)
        return try! domain.encodePoint(publicK)
    }
    
    func testDerive() {
        let keysA = getRandomKeypair()
        let keysB = getRandomKeypair()
        
        let derived1 = try! deriveX(privateKeyA: keysA!.private, publicKeyB: keysB!.public)
        let derived2 = try! deriveX(privateKeyA: keysB!.private, publicKeyB: keysA!.public)
        XCTAssertEqual(derived1, derived2)
    }
    
    func testDeriveNegativeCase() {
        let keysA = getRandomKeypair()
        let keysB = getRandomKeypair()
        let keysC = getRandomKeypair()
        
        let derived1 = try! deriveX(privateKeyA: keysA!.private, publicKeyB: keysB!.public)
        let derived2 = try! deriveX(privateKeyA: keysB!.private, publicKeyB: keysC!.public)
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
    
    func testEncryptDecryptWithSharedSecret() {
        let keysA = getRandomKeypair()!
        let keysB = getRandomKeypair()!
        let msgText = "Hello, World!"
        let msg = msgText.uInt8Array
        XCTAssertNotEqual(msg.count, 0)
        
        let sharedPx = try! deriveX(privateKeyA: keysA.private, publicKeyB: keysB.public)
        XCTAssertNotEqual(sharedPx.count, 0)
        
        let encrypted = try! encryptShared(sharedPx: sharedPx, msg: msg)
        XCTAssertNotEqual(msg, encrypted)
        
        let decrypted = try! decryptShared(sharedPx: sharedPx, encrypted: encrypted)
        let decryptedText = decrypted.stringValue
        XCTAssertEqual(msgText, decryptedText)
    }
    
    func testSignTransaction() {
        let keypair = getRandomKeypair()!
        let input = try! randomBytes(count: .random(in: 200..<1500))
        
        let seedHex = keypair.private.toHexString()
        let inputHex = input.toHexString()
        
        let signed = try? signTransaction(seedHex: seedHex, transactionHex: inputHex)
        XCTAssertNotNil(signed)
    }
    
    @available(macOS 11.3, *)
    func testSignKnown() {
        // seed hex of the signing user
        let seedHex = ""
        // unsigned transaction hex, output of any transaction constructing API call
        let inputHex = ""
        // signed transaction hex, input to the corresponding sumbit-transaction call
        let expected = ""
        XCTExpectFailure("This will fail until values are supplied above. Comment out this line to properly run the test")
        do {
            let signedHash = try signTransaction(seedHex: seedHex, transactionHex: inputHex)
            XCTAssertEqual(signedHash, expected)
        } catch {
            print(error.localizedDescription)
            XCTFail()
        }
    }
    
    @available(macOS 11.3, *)
    func testDecryptLegacyKnown() {
        // seed hex for the receiving user
        let seedHex = ""
        // encrypted V1 hex string from get-messages-stateless
        let encrypted = ""
        // the actual message text
        let expected = ""
        XCTExpectFailure("This will fail until values are supplied above. Comment out this line to properly run the test")
        
        do {
            let decrypted = try decrypt(privateKey: [UInt8](hex: seedHex), encrypted: [UInt8](hex: encrypted), legacy: true)
            XCTAssertNotEqual(decrypted.stringValue, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    @available(macOS 11.3, *)
    func testDecryptSharedKnown() {
        // encrypted V2 hex string from get-messages-stateless
        let encrypted =  ""
        // seed hex for receiving user
        let seedHex = ""
        // public key (in Base58 prefixed format) for sending user
        let pKeyOther = ""
        // the actual message text
        let expected = ""
        
        XCTExpectFailure("This will fail until values are supplied above. Comment out this line to properly run the test")
        do {
            let decodedOtherPK = try Base58CheckDecodePrefix(input: pKeyOther, prefixLen: 3).result
            let decrypted = try decryptShared(privateKeyRecipient: [UInt8](hex: seedHex), publicKeySender: [UInt8](decodedOtherPK), encrypted: [UInt8](hex: encrypted))
            XCTAssertEqual(decrypted.stringValue, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
