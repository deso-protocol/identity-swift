//
//  SignTransactionWorker.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation

enum SignTransactionResponse {
    case success(_ signedHash: String)
    case failed(_ error: Error)
}

protocol TransactionSignable {
    func signTransaction(_ transaction: UnsignedTransaction,
                         on nodeURL: URL,
                         completion: @escaping (SignTransactionResponse) -> Void) throws
}

struct AppendExtraDataBody: Codable {
    let transactionHex: String
    let extraData: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case transactionHex = "TransactionHex"
        case extraData = "ExtraData"
    }
}

struct AppendExtraDataResponse: Codable {
    let transactionHex: String
    
    enum CodingKeys: String, CodingKey {
        case transactionHex = "TransactionHex"
    }
}

class SignTransactionWorker: TransactionSignable {
    
    private let keyStore: KeyInfoStorable
    
    init(keyStore: KeyInfoStorable = KeyInfoStorageWorker()) {
        self.keyStore = keyStore
    }
    
    func signTransaction(_ transaction: UnsignedTransaction,
                         on nodeURL: URL,
                         completion: @escaping (SignTransactionResponse) -> Void) throws {
        guard let key = try keyStore.getDerivedKeyInfo(for: transaction.publicKey) else {
            throw IdentityError.missingInfoForPublicKey
        }
        
        let decoded = try Base58CheckDecodePrefix(input: key.derivedPublicKey, prefixLen: 3)
        guard let derivedKeyByteString = String(bytes: decoded.result, encoding: .ascii) else {
            throw CryptoError.badPublicKey
        }
        
        let url = URL(string: "/api/v0/append-extra-data", relativeTo: nodeURL)!
        
        let body = AppendExtraDataBody(transactionHex: transaction.transactionHex,
                                       extraData: ["DerivedPublicKey": derivedKeyByteString])
        
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
                } else if let data = data,
                          let responseBody = try? JSONDecoder().decode(AppendExtraDataResponse.self, from: data) {
                    do {
                        let signed = try DeSoIdentity.signTransaction(seedHex: key.derivedSeedHex, transactionHex: responseBody.transactionHex)
                        completion(.success(signed))
                    } catch {
                        completion(.failed(error))
                    }
                }
            })
            .resume()
    }
}
