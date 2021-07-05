//
//  JWTCreator.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

protocol JWTFetchable {
    // TODO: Confirm interface. Might need something more to specify the public key to use
    func getJWT(for publicKey: String) throws -> String
}

class JWTWorker: JWTFetchable {
    func getJWT(for publicKey: String) throws -> String {
        // TODO: Actually fetch the JWT and return it, or throw an error if there is no jwt for this public key
        return ""
    }
}
