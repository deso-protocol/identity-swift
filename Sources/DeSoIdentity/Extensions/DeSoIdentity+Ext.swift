//
//  DeSoIdentity+Ext.swift
//  
//
//  Created by Jacob Davis on 12/8/21.
//

import Foundation
import KeychainAccess

internal protocol PostRequest: Codable {
    static var endpoint: URL { get }
}

internal protocol GetRequest {
    static var endpoint: URL { get }
}

internal extension DeSoIdentity {

    static let session = URLSession.shared
    static var basePath = "api/v0"
    
    #if targetEnvironment(simulator)
    static var keychain = [String: String]()
    #else
    static var keychain = Keychain(service: "identity-swift")
    #endif
    
    static func fetchAuthorizationState(_ publicKey: String) async throws -> (appState: AppStateResponse, userState: UsersStatelessResponse, derivedKeyState: UserDerivedKeyResponse) {
        
        async let appState: AppStateResponse = post(AppStateRequest())
        async let userState: UsersStatelessResponse = post(UsersStatelessRequest(publicKey: publicKey))
        async let derivedKeyState: UserDerivedKeyResponse = post(UserDerivedKeyRequest(publicKey: publicKey))
        
        return try await (appState, userState, derivedKeyState)
    }
    
    static func authorizeDerivedKey(with derivedKeyInfo: DerivedKeyInfo,
                                                   deauth: Bool = false) async throws -> AuthorizeDerivedKeyResponse {
        let request = AuthorizeDerivedKeyRequest(withDerivedKeyInfo: derivedKeyInfo, deleteKey: deauth)
        return try await post(request)
    }
    
    static func submitTransaction(signedHex: String) async throws -> SubmitTransactionResponse {
        return try await post(SubmitTransactionRequest(transactionHex: signedHex))
    }
    
    static func signWithAppendedDerivedKey(unsignedTransaction: UnsignedTransaction) async throws -> String {
        
        guard let derivedKeyInfo = try? keychain.getDerivedKeyInfo(for: unsignedTransaction.publicKey) else {
            throw DeSoIdentityError.noDerivedKeyInfoFound
        }
        
        guard let decodedKey = try? Base58CheckDecodePrefix(input: derivedKeyInfo.derivedPublicKey, prefixLen: 3) else {
            throw DeSoIdentityError.noDerivedKeyInfoFound
        }
        
        let request = AppendExtraDataRequest(transactionHex: unsignedTransaction.transactionHex, extraData: ["DerivedPublicKey": decodedKey.result.toHexString()])
        let response: AppendExtraDataResponse = try await post(request)
        
        return try signTransaction(seedHex: derivedKeyInfo.derivedSeedHex, transactionHex: response.transactionHex)
        
    }
    
    static func post<T: PostRequest, R: Decodable>(_ request: T) async throws -> R {
        do {
            
            let req = try buildPostRequest(request: request)
            let (data, res): (Data, URLResponse)
            if #available(iOS 15.0, *) {
                (data, res) = try await session.data(for: req)
            } else {
                (data, res) = try await session.data(with: req)
            }
            
            guard let response = res as? HTTPURLResponse else {
                throw DeSoIdentityError.httpResponseFailure
            }
            
            if response.statusCode == 200 {
                if debug {
                    print(String(data: try JSONSerialization.data(withJSONObject: try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed), options: .prettyPrinted), encoding: .utf8 ) ?? "")
                }
                return try decoder.decode(R.self, from: data)
            } else if let errorResponse = try? decoder.decode(DeSoBackendErrorResponse.self, from: data) {
                print("😭 DESO BACKEND ERROR: \(errorResponse.error)")
                throw DeSoIdentityError.error(message: errorResponse.error)
            } else {
                print("😭 DESO BACKEND ERROR: Uknown")
                throw DeSoIdentityError.unknown
            }
            
        } catch {
            print("😭 DESO BACKEND ERROR: \(error.localizedDescription)")
            throw DeSoIdentityError.error(message: error.localizedDescription)
        }
    }
    
    static func get<R: Decodable>(url: URL) async throws -> R {
        do {
            let (data, res): (Data, URLResponse)
            if #available(iOS 15.0, *) {
                (data, res) = try await session.data(for: URLRequest(url: url))
            } else {
                (data, res) = try await session.data(with: URLRequest(url: url))
            }
            
            guard let response = res as? HTTPURLResponse else {
                throw DeSoIdentityError.httpResponseFailure
            }
            
            if response.statusCode == 200 {
                if debug {
                    print(String(data: try JSONSerialization.data(withJSONObject: try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed), options: .prettyPrinted), encoding: .utf8 ) ?? "")
                }
                if R.self is String.Type {
                    guard let responseObject = String(decoding: data, as: UTF8.self) as? R else {
                        throw DeSoIdentityError.error(message: "Unable to decode Response")
                    }
                    return responseObject
                } else {
                    return try decoder.decode(R.self, from: data)
                }
            } else if let errorResponse = try? decoder.decode(DeSoBackendErrorResponse.self, from: data) {
                print("😭 DESO BACKEND ERROR: \(errorResponse.error)")
                throw DeSoIdentityError.error(message: errorResponse.error)
            } else {
                print("😭 DESO BACKEND ERROR: Uknown")
                throw DeSoIdentityError.unknown
            }
            
        } catch {
            print("😭 DESO BACKEND ERROR: \(error.localizedDescription)")
            throw DeSoIdentityError.error(message: error.localizedDescription)
        }
    }
    
    static func buildPostRequest<T: PostRequest>(request: T) throws -> URLRequest {
        var req = URLRequest(url: T.endpoint)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.httpMethod = "POST"
        do {
            req.httpBody = try encoder.encode(request)
            return req
        } catch {
            throw DeSoIdentityError.error(message: "Unable to encode Request")
        }
    }
    
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromPascalCase
        return decoder
    }
    
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToPascalCase
        return encoder
    }
    
}
