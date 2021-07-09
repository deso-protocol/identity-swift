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
        let keys = domain.makeKeyPair()
        let privateK = keys.1
        let publicK = keys.0
        
        return (private: privateK.asn1.encode(), public: publicK.asn1.encode())
    }
    
    // TODO: get some test data to actually write these tests
    func testKDF() {
        let input = "foobarbat"
        let kdf = kdf(secret: input.uInt8Array, outputLength: 32)
        XCTAssertEqual("not this", kdf.stringValue)
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
}
