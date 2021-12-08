//
//  AppendExtraDataRequest.swift
//  
//
//  Created by Jacob Davis on 12/8/21.
//

import Foundation

internal struct AppendExtraDataRequest: PostRequest {

    static var endpoint: URL {
        return DeSoIdentity.baseURL
            .appendingPathComponent(DeSoIdentity.basePath)
            .appendingPathComponent("append-extra-data")
    }
    
    let transactionHex: String
    let extraData: [String: String]
}

internal struct AppendExtraDataResponse: Decodable {
    let transactionHex: String
}
