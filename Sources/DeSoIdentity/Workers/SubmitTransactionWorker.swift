//
//  File.swift
//  
//
//  Created by Andy Boyd on 29/09/2021.
//

import Foundation

enum SubmitTransactionResponse {
    case success(_ data: Data?)
    case derivedKeyExpired
    case failed(_ error: Error)
}

protocol TransactionSubmittable {
    func submitTransaction(with signedHex: String,
                           on nodeURL: URL,
                           completion: @escaping ((SubmitTransactionResponse) -> Void)) throws
}

struct SubmitTransactionBody: Codable {
    let transactionHex: String

    enum CodingKeys: String, CodingKey {
        case transactionHex = "TransactionHex"
    }
}

class SubmitTransactionWorker: TransactionSubmittable {
    func submitTransaction(with signedHex: String,
                           on nodeURL: URL,
                           completion: @escaping ((SubmitTransactionResponse) -> Void)) throws {
        let url = URL(string: "/api/v0/submit-transaction", relativeTo: nodeURL)!
        
        let body = SubmitTransactionBody(transactionHex: signedHex)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession
            .shared
            .dataTask(with: request, completionHandler: { data, response, error in
                if let error = error {
                    // TODO: Check for expired derived key error here and send back appropriate response
                    completion(.failed(error))
                } else {
                    completion(.success(data))
                }
            })
            .resume()
    }
}
