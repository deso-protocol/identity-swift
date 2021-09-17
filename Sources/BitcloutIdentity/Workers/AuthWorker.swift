//
//  AuthWorker.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation
import AuthenticationServices

protocol Authable {
    func presentAuthSession(context: PresentationContextProvidable, on network: Network, overrideUrl: String?, with completion: Identity.LoginCompletion?)
}

class AuthWorker: Authable {
    private let keyStore: KeyInfoStorable = KeyInfoStorageWorker()
    
    func presentAuthSession(context: PresentationContextProvidable, on network: Network, overrideUrl: String?, with completion: Identity.LoginCompletion?) {
        var url: String
        if let overrideUrl = overrideUrl {
            url = overrideUrl
        } else {
            let baseUrl = "https://identity.bitclout.com"
            url = baseUrl + "/derive" + "?callback=identity://".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        }
        
        if network == .testnet {
            url = url + "&testnet=true"
        }
        
        let session = ASWebAuthenticationSession(url: URL(string: url)!,
                                                 callbackURLScheme: "identity") { url, error in
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
                completion?(allKeys, nil)
            } catch {
                print(error.localizedDescription)
                completion?(nil, error)
            }
        }
        session.presentationContextProvider = context
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
}
