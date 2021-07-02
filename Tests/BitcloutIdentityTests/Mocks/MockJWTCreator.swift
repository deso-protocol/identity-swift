//
//  File.swift
//  
//
//  Created by Andy Boyd on 02/07/2021.
//

import Foundation
@testable import BitcloutIdentity

class MockJWTCreator: JWTCreatable {
    var mockJWT = "foobarJWT"
    var calledCreateJWT: Bool = false
    var jwtRequest: JWTRequest?
    func createJwt(_ request: JWTRequest) throws -> String {
        calledCreateJWT = true
        jwtRequest = request
        return mockJWT
    }
}
