//
//  UsersStatelessRequest.swift
//  
//
//  Created by Jacob Davis on 12/8/21.
//

import Foundation

internal struct UsersStatelessRequest: PostRequest {
    
    static var endpoint: URL {
        return DeSoIdentity.baseURL
            .appendingPathComponent(DeSoIdentity.basePath)
            .appendingPathComponent("get-users-stateless")
    }
    
    let publicKeysBase58Check: [String]
    let skipForLeaderboard: Bool

    init(publicKey: String) {
        self.publicKeysBase58Check = [publicKey]
        self.skipForLeaderboard = false
    }
}

internal struct UsersStatelessResponse: Decodable {
    let userList: [User]
    let defaultFeeRateNanosPerKB: UInt64
    var user: User? {
        return userList.first
    }
}

internal struct User: Decodable {
    let publicKeyBase58Check: String
    let balanceNanos: UInt64
}
