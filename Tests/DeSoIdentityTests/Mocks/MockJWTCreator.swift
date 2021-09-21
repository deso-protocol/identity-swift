//
//  File.swift
//  
//
//  Created by Andy Boyd on 02/07/2021.
//

import Foundation
@testable import DeSoIdentity

class MockJWTCreator: JWTFetchable {
    var mockJWT = "foobarJWT"
    var calledGetJWT: Bool = false
    var publicKeyToGetJWTFor: String?
    func getJWT(for publicKey: String) throws -> String {
        calledGetJWT = true
        publicKeyToGetJWTFor = publicKey
        return mockJWT
    }
}
