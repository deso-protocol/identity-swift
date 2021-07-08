//
//  Test.m
//  
//
//  Created by Andy Boyd on 08/07/2021.
//

import XCTest
@testable import BitcloutIdentity

final class ECIESTests: XCTestCase {
    // TODO: get some test data to actually write these tests
    func testKDF() {
        let input = "foobarbat"
        let kdf = kdf(secret: input.uInt8Array, outputLength: 32)
        XCTAssertEqual("not this", kdf.stringValue)
    }
}
