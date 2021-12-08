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
    /// - Returns: ``SubmitTransactionResponse``
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
