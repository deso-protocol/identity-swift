//
//  AuthWorker.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation
import AuthenticationServices

protocol Authable {
    func presentAuthSession(context: PresentationContextProvidable,
                            on network: Network, overrideUrl: String?,
                            with completion: @escaping Identity.LoginCompletion)
}

class AuthWorker: Authable {
    private var keyStore: KeyInfoStorable = KeyInfoStorageWorker()
    
    func presentAuthSession(context: PresentationContextProvidable,
                            on network: Network, overrideUrl: String?,
                            with completion: @escaping Identity.LoginCompletion) {
        var url: String
        if let overrideUrl = overrideUrl {
            url = overrideUrl
        } else {
            let baseUrl = "https://identity.bitclout.com"
            url = baseUrl + "/derive"
        }
        let callbackScheme = (Bundle.main.bundleIdentifier ?? UUID().uuidString) + ".identity"
        url = url
        + "?callback="
        + callbackScheme.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        + "://".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        + "&webview=true"
        if network == .testnet {
            url = url + "&testnet=true"
        }
        
        let session = ASWebAuthenticationSession(url: URL(string: url)!,
                                                 callbackURLScheme: callbackScheme) { url, error in
            guard let url = url else {
                print(error?.localizedDescription ?? "No URL Returned")
                return
            }
            
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            guard let query = components?.queryItems,
                  let keyData = DerivedKeyInfo(query) else {
                print("Unexpected data returned")
                return
            }
            do {
                try self.keyStore.store(keyData)
                let allKeys = try self.keyStore.getAllStoredKeys()
                completion(.success(selectedPublicKey: keyData.publicKey, allLoadedPublicKeys: allKeys))
            } catch {
                print(error.localizedDescription)
                completion(.failed(error: error))
            }
        }
        session.presentationContextProvider = context
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
}
