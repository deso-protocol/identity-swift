//
//  AuthWorker.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation
import AuthenticationServices

protocol Authable {
    func presentAuthSession(accessLevel: AccessLevel, context: PresentationContextProvider)
}

class AuthWorker: Authable {
    private let keyStore: KeyInfoStorable = KeyInfoStorageWorker()
    
    func presentAuthSession(accessLevel: AccessLevel, context: PresentationContextProvider) {
        // TODO: Confirm the correct URL and callback URL scheme. Obviously localhost will not work 😂
        let session = ASWebAuthenticationSession(url: URL(string: "http://localhost:3000")!,
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
            } catch {
                print(error.localizedDescription)
            }
        }
        session.presentationContextProvider = context
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
}
