//
//  File.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

protocol JWTCreatable {
    func createJwt(_ request: JWTRequest) -> String
}

class JWTCreator: JWTCreatable {
    func createJwt(_ request: JWTRequest) -> String {
        // TODO: Actually create the JWT and return it
        return ""
    }
}
