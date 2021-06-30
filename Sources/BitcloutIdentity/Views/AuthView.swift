//
//  File.swift
//  
//
//  Created by Andy Boyd on 29/06/2021.
//

import Foundation
import AuthenticationServices

func presentAuthSession(accessLevel: AccessLevel, context: PresentationContextProvider) {
    let session = ASWebAuthenticationSession(url: URL(string: "http://localhost:3000")!,
                                             callbackURLScheme: "identity") { url, error in
        // TODO: get the auth information here and store it in the keychain (or wherever is appropriate)
        print(url?.absoluteString ?? "NO URL returned")
        if let error = error {
            print(error.localizedDescription)
        }
    }
    session.presentationContextProvider = context
    session.prefersEphemeralWebBrowserSession = false
    session.start()
}
