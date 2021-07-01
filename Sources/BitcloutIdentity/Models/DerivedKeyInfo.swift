//
//  File.swift
//  
//
//  Created by Andy Boyd on 30/06/2021.
//

import Foundation

public struct DerivedKeyInfo: Codable {
    let truePublicKey: String
    let newPublicKey: String
    let newPrivateKey: String
    let signedHash: String
}

extension DerivedKeyInfo {
    init?(_ query: [URLQueryItem]) {
        guard let truePubKey = query.first(where: { $0.name == "truePublicKey" })?.value,
              let newPubKey = query.first(where: { $0.name == "newPublicKey" })?.value,
              let newPrivateKey = query.first(where: { $0.name == "newPrivateKey" })?.value,
              let signedHash = query.first(where: { $0.name == "signedHash" })?.value else {
            return nil
        }
        
        self.truePublicKey = truePubKey
        self.newPublicKey = newPubKey
        self.newPrivateKey = newPrivateKey
        self.signedHash = signedHash
    }
}
