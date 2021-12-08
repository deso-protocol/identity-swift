//
//  SubmitTransactionRequest.swift
//  
//
//  Created by Jacob Davis on 12/8/21.
//

import Foundation

internal struct SubmitTransactionRequest: PostRequest {
    
    static var endpoint: URL {
        return DeSoIdentity.baseURL
            .appendingPathComponent(DeSoIdentity.basePath)
            .appendingPathComponent("submit-transaction")
    }
    
    let transactionHex: String
}

public struct SubmitTransactionResponse: Decodable {
    public let txnHashHex: String
}
