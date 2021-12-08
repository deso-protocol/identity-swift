import Foundation
import KeychainAccess
import AuthenticationServices

public struct DeSoIdentity {
    
    /// Simply set this static field to any DeSo backend node you prefer
    public static var baseURL = URL(string: "https://node.deso.org")!
    /// Simply set this static field to any DeSo identity node you prefer
    public static var baseIdentityURL = URL(string: "https://identity.deso.org")!
    /// Setting debug true will print some extra info in certain cases
    public static var debug = false
    
    /// Login user by authenticating them via DeSo Identity
    ///
    /// This function will authorize and store the derived key in keychain
    /// which is required for signing transacitons via the derived key.
    /// When logging in you should store your own reference to
    /// ``DeSoLoginResponse/selectedPublicKey`` which is
    /// a property on ``DeSoLoginResponse`` as this is
    /// what you can consider the selected logged in user
    ///
    /// Its also worth noting that if you call this again and the user
    /// initiates another login for the same owner key, the current
    /// stored derived key will be deauthorized and the new on will be
    /// authorized and stored.
    ///
    /// - Parameters:
    ///   - publicKey?: By passing in public key, identity will attempt to find already authorized key for ower
    ///   public key. You can check ``DeSoLoginResponse/LoginState-swift.enum`` to determine what
    ///   to do in response. If you pass in no `publicKey` then the user will be presented with the authentication window.
    ///
    /// - Returns: ``DeSoLoginResponse``
    ///
    /// - Throws: ``DeSoIdentityError``
    public static func login(_ publicKey: String? = nil) async throws -> DeSoLoginResponse {
        
        if let publicKey = publicKey, let derivedKeyInfo = try? keychain.getDerivedKeyInfo(for: publicKey) {
            
            let allKeys = try keychain.getAllStoredKeys()
            let (appState, userState, derivedKeyState) = try await fetchAuthorizationState(publicKey)

            guard let user = userState.user else {
                throw DeSoIdentityError.noUserFoundForPublicKey // error no user found for key
            }
            
            if user.balanceNanos < 1500 { // TODO: Check if there is a better way for this?
                return DeSoLoginResponse(selectedPublicKey: publicKey, allLoadedPublicKeys: allKeys, loginState: .insufficentBalanceForAuthorization) // not enough balance to authorize
            }
            
            guard let derivedKey = derivedKeyState.derivedKey(forDerivedPublicKey: derivedKeyInfo.derivedPublicKey) else {
                return DeSoLoginResponse(selectedPublicKey: publicKey, allLoadedPublicKeys: allKeys, loginState: .notAuthorized) // not authorized
            }

            if (appState.blockHeight - derivedKey.experationThreshold) > derivedKey.expirationBlock || !derivedKey.isValid {
                return DeSoLoginResponse(selectedPublicKey: publicKey, allLoadedPublicKeys: allKeys, loginState: .expiredAuthorization) // auth expired
            } else {
                return DeSoLoginResponse(selectedPublicKey: publicKey, allLoadedPublicKeys: allKeys, loginState: .authorized) // authorized good to go
            }

        } else {
            
            let callbackScheme = (Bundle.main.bundleIdentifier ?? UUID().uuidString) + ".identity"
            var components = URLComponents(string: baseIdentityURL.appendingPathComponent("derive").absoluteString)
            components?.queryItems = [
                URLQueryItem(name: "callback", value: "\(callbackScheme)://"),
                URLQueryItem(name: "webview", value: "true")
            ]

            guard let url = components?.url else {
                throw DeSoIdentityError.unableToFormIdentityUrl
            }

            // Authorize Derived Keys
            let derivedKeyInfo = try await ASWebAuthenticationSession.startSession(url: url, callbackURLScheme: callbackScheme)
            
            // Check user balance
            let userState: UsersStatelessResponse = try await post(UsersStatelessRequest(publicKey: derivedKeyInfo.publicKey))
            guard let user = userState.user else {
                throw DeSoIdentityError.noUserFoundForPublicKey // error no user found for key
            }
            
            if user.balanceNanos < 1500 { // TODO: Check if there is a better way for this?
                try keychain.store(derivedKeyInfo)
                let allKeys = try keychain.getAllStoredKeys()
                return DeSoLoginResponse(selectedPublicKey: derivedKeyInfo.publicKey, allLoadedPublicKeys: allKeys, loginState: .insufficentBalanceForAuthorization) // not enough balance to authorize
            } else {
                let authorizeDerivedKeyResposne = try await authorizeDerivedKey(with: derivedKeyInfo)
                let signed = try signTransaction(seedHex: derivedKeyInfo.derivedSeedHex, transactionHex: authorizeDerivedKeyResposne.transactionHex)
                let _ = try await submitTransaction(signedHex: signed)
                
                try keychain.store(derivedKeyInfo)
                let allKeys = try keychain.getAllStoredKeys()
                
                return DeSoLoginResponse(selectedPublicKey: derivedKeyInfo.publicKey, allLoadedPublicKeys: allKeys, loginState: .authorized)
            }

        }

    }
    
    /// Logout user and deauthorize the current derived key
    ///
    /// This function will deathorize the current derived key
    /// for the owner public key passed in and remove from
    /// keychain.
    ///
    /// - Parameters:
    ///   - publicKey: The owner public key which is associated with the logged in user
    ///
    /// - Returns: `[String]`
    ///
    /// - Throws: ``DeSoIdentityError``
    public static func logout(_ publicKey: String) async throws -> [String] {
        
        if let derivedKeyInfo = try? keychain.getDerivedKeyInfo(for: publicKey) {
            try keychain.clearDerivedKeyInfo(for: publicKey)
            let deAuthorizeDerivedKeyResposne = try await authorizeDerivedKey(with: derivedKeyInfo, deauth: true)
            let signed = try signTransaction(seedHex: derivedKeyInfo.derivedSeedHex, transactionHex: deAuthorizeDerivedKeyResposne.transactionHex)
            let _ = try await submitTransaction(signedHex: signed)
        }
        
        if let remainingStoredKeys = try? keychain.getAllStoredKeys() {
            return remainingStoredKeys
        }
        
        return []
    }

    public static func getLoggedInKeys() throws -> [String] {
        return try keychain.getAllStoredKeys()
    }
    
    public static func removeAllKeys() throws {
        try keychain.clearAllStoredInfo()
    }
    
    /// Signs an ``UnsignedTransaction``
    ///
    /// This function will sign an ``UnsignedTransaction`` but it also
    /// takes care of appending the `ExtraData` needed to actually submit
    /// the transaction when signing with a Derived key.
    ///
    /// Its Important that you add an extra 500 nanos to your `minFeeRateNanosPerKB`
    /// since the extra data per transaction costs just a bit more.
    ///
    /// You can get the `defaultFeeRateNanosPerKB` from a `get-app-state` api
    /// backend call. But in general a good place to start is `1000 + 500` for `minFeeRateNanosPerKB`
    ///
    /// Attention, this funciton only signs the ``UnsignedTransaction``. You will still need to
    /// sumbit the transction. See ``signAndSumbit(_:)``
    ///
    /// - Parameters:
    ///   - unsignedTransaction: ``UnsignedTransaction``
    ///
    /// - Returns: `String`
    ///
    /// - Throws: ``DeSoIdentityError``
    public static func sign(_ unsignedTransaction: UnsignedTransaction) async throws -> String {
        return try await signWithAppendedDerivedKey(unsignedTransaction: unsignedTransaction)
    }
    
    /// Signs an ``UnsignedTransaction``
    ///
    /// This function will sign an ``UnsignedTransaction`` but it also
    /// takes care of appending the `ExtraData` needed to actually submit
    /// the transaction when signing with a Derived key as well as take care of actually
    /// sumbittling the transaction to the blockchain.
    ///
    /// Its Important that you add an extra 500 nanos to your `minFeeRateNanosPerKB`
    /// since the extra data per transaction costs just a bit more.
    ///
    /// You can get the `defaultFeeRateNanosPerKB` from a `get-app-state` api
    /// backend call. But in general a good place to start is `1000 + 500` for `minFeeRateNanosPerKB`
    ///
    /// - Parameters:
    ///   - unsignedTransaction: ``UnsignedTransaction``
    ///
    /// - Returns: `Data`
    ///
    /// - Throws: ``DeSoIdentityError``
    public static func signAndSumbit(_ unsignedTransaction: UnsignedTransaction) async throws -> SubmitTransactionResponse {
        let signed = try await signWithAppendedDerivedKey(unsignedTransaction: unsignedTransaction)
        return try await submitTransaction(signedHex: signed)
    }
    
}

public struct DeSoLoginResponse {
    
    public enum LoginState {
        case authorized
        case notAuthorized
        case expiredAuthorization
        case insufficentBalanceForAuthorization
    }
    
    public let selectedPublicKey: String
    public let allLoadedPublicKeys: [String]
    public let loginState: LoginState
}


// MARK: - Private functions that should not be used via the public api of this library

internal protocol PostRequest: Codable {
    static var endpoint: URL { get }
}

internal protocol GetRequest {
    static var endpoint: URL { get }
}

extension DeSoIdentity {

    internal static let session = URLSession.shared
    internal static var basePath = "api/v0"
    
    #if targetEnvironment(simulator)
    internal static var keychain = [String: String]()
    #else
    internal static var keychain = Keychain(service: "identity-swift")
    #endif
    
    internal static func fetchAuthorizationState(_ publicKey: String) async throws -> (appState: AppStateResponse, userState: UsersStatelessResponse, derivedKeyState: UserDerivedKeyResponse) {
        
        async let appState: AppStateResponse = post(AppStateRequest())
        async let userState: UsersStatelessResponse = post(UsersStatelessRequest(publicKey: publicKey))
        async let derivedKeyState: UserDerivedKeyResponse = post(UserDerivedKeyRequest(publicKey: publicKey))
        
        return try await (appState, userState, derivedKeyState)
    }
    
    internal static func authorizeDerivedKey(with derivedKeyInfo: DerivedKeyInfo,
                                                   deauth: Bool = false) async throws -> AuthorizeDerivedKeyResponse {
        let request = AuthorizeDerivedKeyRequest(withDerivedKeyInfo: derivedKeyInfo, deleteKey: deauth)
        return try await post(request)
    }
    
    internal static func submitTransaction(signedHex: String) async throws -> SubmitTransactionResponse {
        return try await post(SubmitTransactionRequest(transactionHex: signedHex))
    }
    
    internal static func signWithAppendedDerivedKey(unsignedTransaction: UnsignedTransaction) async throws -> String {
        
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
    
    internal static func post<T: PostRequest, R: Decodable>(_ request: T) async throws -> R {
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
    
    internal static func get<R: Decodable>(url: URL) async throws -> R {
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
    
    internal static func buildPostRequest<T: PostRequest>(request: T) throws -> URLRequest {
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
    
    internal static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromPascalCase
        return decoder
    }
    
    internal static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToPascalCase
        return encoder
    }
    
}
