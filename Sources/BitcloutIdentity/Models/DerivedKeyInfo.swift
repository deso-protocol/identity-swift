//
//  DerivedKeyInfo.swift
//  
//
//  Created by Andy Boyd on 30/06/2021.
//

import Foundation

// TODO: Confirm this. Does it need more info, e.g. the access level?
public struct DerivedKeyInfo: Codable {
    public let truePublicKey: String
    public let newPublicKey: String
    public let newPrivateKey: String
    public let signedHash: String
    public let jwt: String
}

extension DerivedKeyInfo {
    init?(_ query: [URLQueryItem]) {
        // TODO: Confirm with Identity web app if this matches how the data will be returned from the auth session
        guard let truePubKey = query.first(where: { $0.name == "truePublicKey" })?.value,
              let newPubKey = query.first(where: { $0.name == "newPublicKey" })?.value,
              let newPrivateKey = query.first(where: { $0.name == "newPrivateKey" })?.value,
              let signedHash = query.first(where: { $0.name == "signedHash" })?.value,
              let jwt = query.first(where: { $0.name == "jwt" })?.value else {
            return nil
        }
        
        self.truePublicKey = truePubKey
        self.newPublicKey = newPubKey
        self.newPrivateKey = newPrivateKey
        self.signedHash = signedHash
        self.jwt = jwt
    }
}
