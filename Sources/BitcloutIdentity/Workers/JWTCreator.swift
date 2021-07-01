//
//  JWTCreator.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

protocol JWTCreatable {
    // TODO: Confirm interface. Might need something more to specify the public key to use
    func createJwt(_ request: JWTRequest) throws -> String
}

class JWTCreator: JWTCreatable {
    func createJwt(_ request: JWTRequest) throws -> String {
        // TODO: Actually create the JWT and return it
        return ""
    }
}
