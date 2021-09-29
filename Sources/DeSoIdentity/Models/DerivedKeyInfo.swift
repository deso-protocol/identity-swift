//
//  DerivedKeyInfo.swift
//  
//
//  Created by Andy Boyd on 30/06/2021.
//

import Foundation

public enum Network: String, Codable {
    case mainnet
    case testnet
}

public struct DerivedKeyInfo: Codable, Equatable {
    public let publicKey: String
    public let derivedPublicKey: String
    public let derivedSeedHex: String
    public let btcDepositAddress: String
    public let expirationBlock: Int
    public let accessSignature: String
    public let network: Network
    public let jwt: String
    public let derivedJwt: String
}

extension DerivedKeyInfo {
    init?(_ query: [URLQueryItem]) {
        // TODO: Confirm with Identity web app if this matches how the data will be returned from the auth session
        guard let truePubKey = query.first(where: { $0.name == "publicKey" })?.value,
              let newPubKey = query.first(where: { $0.name == "derivedPublicKey" })?.value,
              let newPrivateKey = query.first(where: { $0.name == "derivedSeedHex" })?.value,
              let signedHash = query.first(where: { $0.name == "accessSignature" })?.value,
              let btcDepositAddress = query.first(where: { $0.name == "btcDepositAddress" })?.value,
              let network = Network(rawValue: query.first(where: { $0.name == "network" })?.value ?? ""),
              let expirationBlockValue = query.first(where: { $0.name == "expirationBlock" })?.value,
              let expirationBlock = Int(expirationBlockValue),
              let jwt = query.first(where: { $0.name == "jwt" })?.value,
              let derivedJwt = query.first(where: { $0.name == "derivedJwt" })?.value else {
            return nil
        }
        
        self.publicKey = truePubKey
        self.derivedPublicKey = newPubKey
        self.derivedSeedHex = newPrivateKey
        self.accessSignature = signedHash
        self.btcDepositAddress = btcDepositAddress
        self.network = network
        self.expirationBlock = expirationBlock
        self.jwt = jwt
        self.derivedJwt = derivedJwt
    }
}
