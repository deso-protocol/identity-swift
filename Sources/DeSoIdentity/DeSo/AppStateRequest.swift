//
//  AppStateRequest.swift
//  
//
//  Created by Jacob Davis on 12/8/21.
//

import Foundation

internal struct AppStateRequest: PostRequest {
    
    static var endpoint: URL {
        return DeSoIdentity.baseURL
            .appendingPathComponent(DeSoIdentity.basePath)
            .appendingPathComponent("get-app-state")
    }
    
    let publicKeyBase58Check: String
    
    init(publicKey: String = "") {
        self.publicKeyBase58Check = publicKey
    }
}

internal struct AppStateResponse: Decodable {
    
    let blockHeight: UInt64
    //let defaultFeeRateNanosPerKB: UInt64
}
