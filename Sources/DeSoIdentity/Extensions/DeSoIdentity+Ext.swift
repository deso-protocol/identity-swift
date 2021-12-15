//
//  DeSoIdentity+Ext.swift
//  
//
//  Created by Jacob Davis on 12/8/21.
//

import Foundation
import KeychainAccess
import AuthenticationServices

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
    
    static func getSharedSecrets(_ publicKey: String, messagePublicKeys publicKeys: [String]) async throws -> [SharedSecret] {
        
        var messagePublicKeys = Array(Set(publicKeys))
        messagePublicKeys.sort(by: { $0 < $1 })
        
        if let storedSharedSecrets = try? keychain.getSharedSecrets(for: publicKey, and: publicKeys) {
            return storedSharedSecrets
        } else if let derivedKeyInfo = try? keychain.getDerivedKeyInfo(for: publicKey), messagePublicKeys.count > 0 {

            let ownerPublicKey = publicKey
            let derivedPublicKey = derivedKeyInfo.derivedPublicKey
            let derivedJWT = derivedKeyInfo.derivedJwt

            let callbackScheme = (Bundle.main.bundleIdentifier ?? UUID().uuidString) + ".identity"
            var components = URLComponents(string: baseIdentityURL.appendingPathComponent("get-shared-secrets").absoluteString)
            components?.queryItems = [
                URLQueryItem(name: "callback", value: "\(callbackScheme)://"),
                URLQueryItem(name: "webview", value: "true"),
                URLQueryItem(name: "ownerPublicKey", value: ownerPublicKey),
                URLQueryItem(name: "derivedPublicKey", value: derivedPublicKey),
                URLQueryItem(name: "JWT", value: derivedJWT),
                URLQueryItem(name: "messagePublicKeys", value: messagePublicKeys.joined(separator: ","))
            ]

            guard let url = components?.url else {
                throw DeSoIdentityError.unableToFormIdentityUrl
            }

            // Get Shared Secrets
            let secrets = try await ASWebAuthenticationSession.startGetSharedSecretsSession(url: url, callbackURLScheme: callbackScheme)
            if messagePublicKeys.count == secrets.count {
                
                var sharedSecrets = [SharedSecret]()
                for (i, secret) in secrets.enumerated() {
                    let sharedSecret = SharedSecret(secret: secret, publicKey: publicKey, otherPublicKey: messagePublicKeys[i])
                    try keychain.store(sharedSecret)
                    sharedSecrets.append(sharedSecret)
                }
                
                return sharedSecrets
                
            } else {
                throw DeSoIdentityError.error(message: "Publickey count doesnt match number of shared secrets returned")
            }

        } else {
            
            throw DeSoIdentityError.noDerivedKeyInfoFound

        }

    }
    
    static func decryptThread(_ thread: EncryptedMessagesThread, shouldThrow: Bool) throws -> [String] {
        guard let sharedSecret = try? DeSoIdentity.keychain.getSharedSecret(for: thread.publicKey, and: thread.otherPublicKey) else {
            throw DeSoIdentityError.missingSharedSecret
        }
        var decrypted: [String] = []
        do {
            decrypted = try DeSoIdentity.decrypt(messages: thread.encryptedMessages, with: sharedSecret)
        } catch {
            if shouldThrow {
                throw error
            }
            print(error)
        }
        return decrypted
    }
    
    static func decrypt(messages: [EncryptedMessagesThread.EncryptedText], with secret: SharedSecret) throws -> [String] {
        return try messages.compactMap {
            return try decryptWith(sharedSecret: secret.secret, encryptedText: $0.message, v2: $0.v2).stringValue
        }
    }
    
    static func post<T: PostRequest, R: Decodable>(_ request: T) async throws -> R {
        do {
            
            let req = try buildPostRequest(request: request)
            let (data, res): (Data, URLResponse)
            if #available(iOS 15.0, macOS 12.0, *) {
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
            if #available(iOS 15.0, macOS 12.0, *) {
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
